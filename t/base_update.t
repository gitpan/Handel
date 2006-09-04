#!perl -wT
# $Id: base_update.t 1394 2006-09-04 17:54:57Z claco $
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::More;
use Handel::Test;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 10;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


{
    my $storage = Handel::Storage::DBIC->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts',
        connection_info    => [Handel::Test->init_schema(no_populate => 1)->dsn]
    });

    my $schema = $storage->schema_instance;

    $schema->resultset('Carts')->create({
        id => 1,
        shopper => 1,
        name => 'Cart1',
        description => 'My Cart 1'
    });

    my $it = $schema->resultset('Carts')->search({id => 1});

    my $iterator = $storage->iterator_class->new({
        data => $it,
        storage => $storage,
        result_class => 'Handel::Storage::DBIC::Result'
    });

    my $cart = Handel::Base->create_instance($iterator->next, $storage);

    is($cart->result->id, 1);
    is($cart->result->shopper, 1);
    is($cart->result->name, 'Cart1');
    is($cart->result->description, 'My Cart 1');

    $cart->result->set_column('name', 'UpdatedName');
    is($cart->result->name, 'UpdatedName');

    my $reit = $schema->resultset('Carts')->search({id => 1});
    my $reiter = $storage->iterator_class->new({
        data => $reit,
        storage => $storage,
        result_class => 'Handel::Storage::DBIC::Result'
    });

    my $recart = Handel::Base->create_instance($reiter->first, $storage);
    is($recart->result->name, 'Cart1');

    $cart->update;

    my $it2 = $schema->resultset('Carts')->search({id => 1});
    my $reit2 = $storage->iterator_class->new({
        data => $it2,
        storage => $storage,
        result_class => 'Handel::Storage::DBIC::Result'
    });


    my $recart2 = Handel::Base->create_instance($reit2->first, $storage);
    is($recart2->result->name, 'UpdatedName');
};
