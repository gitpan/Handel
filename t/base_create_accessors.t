#!perl -wT
# $Id: base_create_accessors.t 1354 2006-08-06 00:11:31Z claco $
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 25;
    };

    use_ok('Handel::Base');
};


## Setup SQLite DB for tests
my $dbfile  = "t/base_create_accessors.db";
my $db      = "dbi:SQLite:dbname=$dbfile";
my $create  = 't/sql/cart_create_table.sql';

unlink $dbfile;
executesql($db, $create);


{
    my $base = 'Handel::Base';
    $base->storage({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts',
        connection_info    => [$db],
        add_columns        => [custom => {accessor => 'foo'}]
    });

    $base->create_accessors;
    
    can_ok($base, 'id');
    can_ok($base, 'shopper');
    can_ok($base, 'type');
    can_ok($base, 'name');
    can_ok($base, 'description');
    can_ok($base, 'foo');

    my $schema = $base->storage->schema_instance;
    
    my $new = $base->storage->schema_instance->resultset('Carts')->create({
        id => 1,
        shopper => 1,
        type => 1,
        name => 'Cart1',
        description => 'My Cart 1',
        custom => 'foo'
    });

    my $it = $base->storage->schema_instance->resultset('Carts')->search({id => 1});
    $it->result_class('Handel::Storage::Result');

    my $iterator = Handel::Iterator->create_iterator($it, 'Handel::Base');
    
    my $cart = $iterator->next;
    can_ok($cart, 'id');
    can_ok($cart, 'shopper');
    can_ok($cart, 'type');
    can_ok($cart, 'name');
    can_ok($cart, 'description');
    can_ok($cart, 'foo');
    
    is($cart->id, 1);
    is($cart->shopper, 1);
    is($cart->type, 1);
    is($cart->name, 'Cart1');
    is($cart->description, 'My Cart 1');
    is($cart->foo, 'foo');
    
    is($cart->id, $cart->result->id);
    is($cart->shopper, $cart->result->shopper);
    is($cart->type, $cart->result->type);
    is($cart->name, $cart->result->name);
    is($cart->description, $cart->result->description);
    is($cart->foo, $cart->result->foo);
};
