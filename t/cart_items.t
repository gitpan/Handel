#!perl -wT
# $Id: cart_items.t 1072 2006-01-17 03:30:38Z claco $
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
        plan tests => 378;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', qw(:cart :returnas));
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
&run('Handel::Cart', 'Handel::Cart::Item', 1);
&run('Handel::Subclassing::CartOnly', 'Handel::Cart::Item', 2);
&run('Handel::Subclassing::Cart', 'Handel::Subclassing::CartItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;


    ## Setup SQLite DB for tests
    {
        my $dbfile  = "t/cart_items_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/cart_create_table.sql';
        my $data    = 't/sql/cart_fake_data.sql';

        unlink $dbfile;
        executesql($db, $create);
        executesql($db, $data);

        local $^W = 0;
        Handel::DBI->connection($db);
    };


    ## load multiple item Handel::Cart object and get items array on RETURNAS_AUTO
    {
        my $cart = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->id, '11111111-1111-1111-1111-111111111111');
        is($cart->shopper, '11111111-1111-1111-1111-111111111111');
        is($cart->type, CART_TYPE_TEMP);
        is($cart->name, 'Cart 1');
        is($cart->description, 'Test Temp Cart 1');
        is($cart->count, 2);
        is($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my @items = $cart->items;
        is(scalar @items, $cart->count);

        my $item1 = $items[0];
        isa_ok($item1, 'Handel::Cart::Item');
        isa_ok($item1, $itemclass);
        is($item1->id, '11111111-1111-1111-1111-111111111111');
        is($item1->cart, $cart->id);
        is($item1->sku, 'SKU1111');
        is($item1->quantity, 1);
        is($item1->price, 1.11);
        is($item1->description, 'Line Item SKU 1');
        is($item1->total, 1.11);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item1->custom, 'custom');
        };

        my $item2 = $items[1];
        isa_ok($item2, 'Handel::Cart::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222');
        is($item2->cart, $cart->id);
        is($item2->sku, 'SKU2222');
        is($item2->quantity, 2);
        is($item2->price, 2.22);
        is($item2->description, 'Line Item SKU 2');
        is($item2->total, 4.44);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom');
        };

        ## While we are here, lets poop out a max quantity exception
        ## THere should be a better place for this, but I haven't found it yet. :-)
        {
            local $ENV{'HandelMaxQuantity'} = 5;
            local $ENV{'HandelMaxQuantityAction'} = 'Exception';

            try {
                $item2->quantity(6);
            } catch Handel::Exception::Constraint with {
                pass;
            } otherwise {
                fail;
            };
        };


        ## While we are here, lets poop out a max quantity adjustment
        ## There should be a better place for this, but I haven't found it yet. :-)
        {
            local $ENV{'HandelMaxQuantity'} = 2;

            $item2->quantity(6);
            is($item2->quantity, 2);
        };
    };


    ## load multiple item Handel::Cart object and get items array on RETURNAS_LIST
    {
        my $cart = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->id, '11111111-1111-1111-1111-111111111111');
        is($cart->shopper, '11111111-1111-1111-1111-111111111111');
        is($cart->type, CART_TYPE_TEMP);
        is($cart->name, 'Cart 1');
        is($cart->description, 'Test Temp Cart 1');
        is($cart->count, 2);
        is($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my @items = $cart->items(undef, RETURNAS_LIST);
        is(scalar @items, $cart->count);

        my $item1 = $items[0];
        isa_ok($item1, 'Handel::Cart::Item');
        isa_ok($item1, $itemclass);
        is($item1->id, '11111111-1111-1111-1111-111111111111');
        is($item1->cart, $cart->id);
        is($item1->sku, 'SKU1111');
        is($item1->quantity, 1);
        is($item1->price, 1.11);
        is($item1->description, 'Line Item SKU 1');
        is($item1->total, 1.11);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item1->custom, 'custom');
        };

        my $item2 = $items[1];
        isa_ok($item2, 'Handel::Cart::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222');
        is($item2->cart, $cart->id);
        is($item2->sku, 'SKU2222');
        is($item2->quantity, 2);
        is($item2->price, 2.22);
        is($item2->description, 'Line Item SKU 2');
        is($item2->total, 4.44);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom');
        };
    };


    ## load multiple item Handel::Cart object and get items Iterator
    {
        my $cart = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->id, '11111111-1111-1111-1111-111111111111');
        is($cart->shopper, '11111111-1111-1111-1111-111111111111');
        is($cart->type, CART_TYPE_TEMP);
        is($cart->name, 'Cart 1');
        is($cart->description, 'Test Temp Cart 1');
        is($cart->count, 2);
        is($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my $items = $cart->items;
        isa_ok($items, 'Handel::Iterator');
        is($items->count, 2);
    };


    ## load multiple item Handel::Cart object and get filter single item
    {
        my $cart = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->id, '11111111-1111-1111-1111-111111111111');
        is($cart->shopper, '11111111-1111-1111-1111-111111111111');
        is($cart->type, CART_TYPE_TEMP);
        is($cart->name, 'Cart 1');
        is($cart->description, 'Test Temp Cart 1');
        is($cart->count, 2);
        is($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my $item2 = $cart->items({sku => 'SKU2222'});
        isa_ok($item2, 'Handel::Cart::Item');
        isa_ok($item2, $itemclass);
        is($item2->id, '22222222-2222-2222-2222-222222222222');
        is($item2->cart, $cart->id);
        is($item2->sku, 'SKU2222');
        is($item2->quantity, 2);
        is($item2->price, 2.22);
        is($item2->description, 'Line Item SKU 2');
        is($item2->total, 4.44);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item2->custom, 'custom');
        };
    };


    ## load multiple item Handel::Cart object and get filter single item to Iterator
    {
        my $cart = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->id, '11111111-1111-1111-1111-111111111111');
        is($cart->shopper, '11111111-1111-1111-1111-111111111111');
        is($cart->type, CART_TYPE_TEMP);
        is($cart->name, 'Cart 1');
        is($cart->description, 'Test Temp Cart 1');
        is($cart->count, 2);
        is($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my $iterator = $cart->items({sku => 'SKU2222'}, 1);
        isa_ok($iterator, 'Handel::Iterator');
    };


    ## load multiple item Handel::Cart object and get wildcard filter to Iterator
    {
        my $cart = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->id, '11111111-1111-1111-1111-111111111111');
        is($cart->shopper, '11111111-1111-1111-1111-111111111111');
        is($cart->type, CART_TYPE_TEMP);
        is($cart->name, 'Cart 1');
        is($cart->description, 'Test Temp Cart 1');
        is($cart->count, 2);
        is($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my $iterator = $cart->items({sku => 'SKU%'}, 1);
        isa_ok($iterator, 'Handel::Iterator');
        is($iterator, 2);
    };


    ## load multiple item Handel::Cart object and get filter bogus item to Iterator
    {
        my $cart = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        is($cart->id, '11111111-1111-1111-1111-111111111111');
        is($cart->shopper, '11111111-1111-1111-1111-111111111111');
        is($cart->type, CART_TYPE_TEMP);
        is($cart->name, 'Cart 1');
        is($cart->description, 'Test Temp Cart 1');
        is($cart->count, 2);
        is($cart->subtotal, 5.55);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, 'custom');
        };

        my $iterator = $cart->items({sku => 'notfound'}, 1);
        isa_ok($iterator, 'Handel::Iterator');
    };

};
