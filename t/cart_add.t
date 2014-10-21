#!perl -wT
# $Id: cart_add.t 1072 2006-01-17 03:30:38Z claco $
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
        plan tests => 156;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', ':cart');
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
        my $dbfile  = "t/cart_add_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/cart_create_table.sql';
        my $data    = 't/sql/cart_fake_data.sql';

        unlink $dbfile;
        executesql($db, $create);
        executesql($db, $data);

        local $^W = 0;
        Handel::DBI->connection($db);
    };


    ## test for Handel::Exception::Argument where first param is not a hashref
    ## or Handle::Cart::Item subclass
    {
        try {
            my $newitem = $subclass->add(id => '1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where first param is not a hashref
    ## or Handle::Cart::Item subclass
    {
        try {
            my $fakeitem = bless {}, 'FakeItem';
            my $newitem = $subclass->add($fakeitem);

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## add a new item by passing a hashref
    {
        my $cart = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);

        my $data = {
            sku         => 'SKU9999',
            quantity    => 2,
            price       => 1.11,
            description => 'Line Item SKU 9'
        };
        if ($itemclass ne 'Handel::Cart::Item') {
            $data->{'custom'} = 'custom';
        };

        my $item = $cart->add($data);
        isa_ok($item, 'Handel::Cart::Item');
        isa_ok($item, $itemclass);
        is($item->cart, $cart->id);
        is($item->sku, 'SKU9999');
        is($item->quantity, 2);
        is($item->price, 1.11);
        is($item->description, 'Line Item SKU 9');
        is($item->total, 2.22);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item->custom, 'custom');
        };


        is($cart->count, 3);
        is($cart->subtotal, 7.77);

        my $recart = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($recart, $subclass);
        is($recart->count, 3);

        my $reitem = $cart->items({sku => 'SKU9999'});
        isa_ok($item, 'Handel::Cart::Item');
        isa_ok($item, $itemclass);
        is($reitem->cart, $cart->id);
        is($reitem->sku, 'SKU9999');
        is($reitem->quantity, 2);
        is($reitem->price, 1.11);
        is($reitem->description, 'Line Item SKU 9');
        is($reitem->total, 2.22);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item->custom, 'custom');
        };
    };


    ## add a new item by passing a Handel::Cart::Item
    {
        my $data = {
            sku         => 'SKU8888',
            quantity    => 1,
            price       => 1.11,
            description => 'Line Item SKU 8'
        };
        if ($itemclass ne 'Handel::Cart::Item') {
            $data->{'custom'} = 'custom';
        };

        my $newitem = $itemclass->new($data);
        isa_ok($newitem, 'Handel::Cart::Item');
        isa_ok($newitem, $itemclass);

        my $cart = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);

        my $item = $cart->add($newitem);
        isa_ok($item, 'Handel::Cart::Item');
        isa_ok($item, $itemclass);
        is($item->cart, $cart->id, "koo");
        is($item->sku, 'SKU8888');
        is($item->quantity, 1);
        is($item->price, 1.11);
        is($item->description, 'Line Item SKU 8');
        is($item->total, 1.11);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item->custom, 'custom');
        };

        is($cart->count, 2);
        is($cart->subtotal, 11.10);

        my $recart = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($recart, $subclass);
        isa_ok($recart, 'Handel::Cart');
        is($recart->count, 2);

        my $reitem = $cart->items({sku => 'SKU8888'});
        isa_ok($reitem, 'Handel::Cart::Item');
        isa_ok($reitem, $itemclass);
        is($reitem->cart, $cart->id);
        is($reitem->sku, 'SKU8888');
        is($reitem->quantity, 1);
        is($reitem->price, 1.11);
        is($reitem->description, 'Line Item SKU 8');
        is($reitem->total, 1.11);
        if ($itemclass ne 'Handel::Cart::Item') {
            is($item->custom, 'custom');
        };
    };

};
