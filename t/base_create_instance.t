#!perl -wT
# $Id: base_create_instance.t 1386 2006-08-26 01:46:16Z claco $
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Handel::Test;
use Test::More;
use Scalar::Util qw/refaddr/;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 19;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


{
    my $storage = Handel::Storage::DBIC->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts',
        item_class         => 'Handel::Cart::Item',
        connection_info    => [Handel::Test->init_schema(no_populate => 1)->dsn]
    });

    my $schema = $storage->schema_instance;

    $schema->resultset('Carts')->create({
        id => '11111111-1111-1111-1111-111111111111',
        shopper => 1,
        name => 'Cart1',
        description => 'My Cart 1'
    });

    my $it = $schema->resultset('Carts')->search({id => '11111111-1111-1111-1111-111111111111'});
    isa_ok($it, 'DBIx::Class::ResultSet');

    my $iterator = Handel::Iterator::DBIC->new({
        data => $it,
        storage => $storage,
        result_class => 'Handel::Storage::Result'
    });
    isa_ok($iterator, 'Handel::Iterator::DBIC');

    my $cart = Handel::Base->create_instance($iterator->next, $storage);

    isa_ok($cart, 'Handel::Base');
    isa_ok($cart->result, 'Handel::Storage::Result');

    is($cart->result->id, '11111111-1111-1111-1111-111111111111');
    is($cart->result->shopper, 1);
    is($cart->result->name, 'Cart1');
    is($cart->result->description, 'My Cart 1');

    is(refaddr $cart->result->{'storage'}, refaddr $storage);
    is(refaddr $cart->result->storage, refaddr $storage);
    is(refaddr $cart->result->{'storage'}->_schema_instance, refaddr $schema);

    my $item = $cart->result->add_item({
        cart => '11111111-1111-1111-1111-111111111111',
        sku => 'ABC123'
    });

    $item = $storage->item_class->create_instance($item);
    isa_ok($item, 'Handel::Cart::Item');

    isnt(refaddr $item->result->{'storage'}, refaddr $storage);
    isnt(refaddr $item->result->{'storage'}, refaddr Handel::Cart::Item->storage);
    isnt(refaddr $item->result->storage, refaddr $storage);
    is(refaddr $item->result->{'storage'}->_schema_instance, refaddr $schema);
};
