#!perl -wT
# $Id: base_create_instance.t 1354 2006-08-06 00:11:31Z claco $
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);
use Scalar::Util qw/refaddr/;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 18;
    };

    use_ok('Handel::Storage');
    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


{
    ## Setup SQLite DB for tests
    my $dbfile  = "t/base_create_instance.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';

    unlink $dbfile;
    executesql($db, $create);

    my $storage = Handel::Storage->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts',
        item_class         => 'Handel::Cart::Item',
        connection_info    => [$db]
    });

    my $schema = $storage->schema_instance;

    $schema->resultset('Carts')->create({
        id => '11111111-1111-1111-1111-111111111111',
        shopper => 1,
        name => 'Cart1',
        description => 'My Cart 1'
    });

    my $iterator = $schema->resultset('Carts')->search({id => '11111111-1111-1111-1111-111111111111'});
    $iterator->result_class('Handel::Storage::Result');
    isa_ok($iterator, 'Handel::Iterator');

    my $cart = Handel::Base->create_instance($iterator->next);

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
