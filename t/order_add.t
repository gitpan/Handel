#!perl -wT
# $Id: order_add.t 1355 2006-08-07 01:51:41Z claco $
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
        plan tests => 290;
    };

    use_ok('Handel::Order');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
    use_ok('Handel::Subclassing::CartItem');
    use_ok('Handel::Order::Item');
    use_ok('Handel::Cart::Item');
    use_ok('Handel::Constants', ':order');
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
&run('Handel::Order', 'Handel::Order::Item', 1);
&run('Handel::Subclassing::OrderOnly', 'Handel::Order::Item', 2);
&run('Handel::Subclassing::Order', 'Handel::Subclassing::OrderItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;


    ## Setup SQLite DB for tests
    {
        my $dbfile  = "t/order_add_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $cartcreate   = 't/sql/order_create_table.sql';
        my $cartdata     = 't/sql/order_fake_data.sql';
        my $ordercreate  = 't/sql/cart_create_table.sql';
        my $orderdata    = 't/sql/cart_fake_data.sql';

        unlink $dbfile;
        executesql($db, $cartcreate);
        executesql($db, $cartdata);
        executesql($db, $ordercreate);
        executesql($db, $orderdata);

        $ENV{'HandelDBIDSN'} = $db;
    };


    ## test for Handel::Exception::Argument where first param is not a hashref
    ## or Handle::Order::Item subclass
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
    ## or Handle::Order::Item subclass
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
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);

        my $data = {
            sku         => 'SKU9999',
            quantity    => 2,
            price       => 1.11,
            total       => 2.22,
            description => 'Line Item SKU 9'
        };
        if ($itemclass ne 'Handel::Order::Item') {
            $data->{'custom'} = 'custom';
        };

        my $item = $order->add($data);
        isa_ok($item, 'Handel::Order::Item');
        isa_ok($item, $itemclass);
        is($item->orderid, $order->id);
        is($item->sku, 'SKU9999');
        is($item->quantity, 2);
        is($item->price, 1.11);
        is($item->description, 'Line Item SKU 9');
        is($item->total, 2.22);
        if ($itemclass ne 'Handel::Order::Item') {
            is($item->custom, 'custom');
        };

        is($order->count, 3);
        is($order->subtotal, 5.55);

        my $reit = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 1);

        my $reorder = $reit->first;
        isa_ok($reorder, 'Handel::Order');
        isa_ok($reorder, $subclass);
        is($reorder->count, 3);

        my $reitemit = $reorder->items({sku => 'SKU9999'});
        isa_ok($reitemit, 'Handel::Iterator');
        is($reitemit, 1);

        my $reitem = $reitemit->first;
        isa_ok($reitem, 'Handel::Order::Item');
        isa_ok($reitem, $itemclass);
        is($reitem->orderid, $reorder->id);
        is($reitem->sku, 'SKU9999');
        is($reitem->quantity, 2);
        is($reitem->price, 1.11);
        is($reitem->description, 'Line Item SKU 9');
        is($reitem->total, 2.22);
        if ($itemclass ne 'Handel::Order::Item') {
            is($reitem->custom, 'custom');
        };
    };


    ## add a new item by passing a Handel::Order::Item
    {
        my $data = {
            sku         => 'SKU8888',
            quantity    => 1,
            price       => 1.11,
            description => 'Line Item SKU 8',
            total       => 2.22,
            orderid     => '00000000-0000-0000-0000-000000000000'
        };
        if ($itemclass ne 'Handel::Order::Item') {
            $data->{'custom'} = 'custom';
        };
        my $newitem = $itemclass->create($data);

        isa_ok($newitem, 'Handel::Order::Item');
        isa_ok($newitem, $itemclass);

        my $it = $subclass->search({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);

        my $item = $order->add($newitem);
        isa_ok($item, 'Handel::Order::Item');
        isa_ok($item, $itemclass);
        is($item->orderid, $order->id);
        is($item->sku, 'SKU8888');
        is($item->quantity, 1);
        is($item->price, 1.11);
        is($item->description, 'Line Item SKU 8');
        is($item->total, 2.22);
        if ($itemclass ne 'Handel::Order::Item') {
            is($item->custom, 'custom');
        };

        is($order->count, 2);
        is($order->subtotal, 5.55);

        my $reit = $subclass->search({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 1);

        my $reorder = $reit->first;
        isa_ok($reorder, 'Handel::Order');
        isa_ok($reorder, $subclass);
        is($reorder->count, 2);

        my $reitemit = $order->items({sku => 'SKU8888'});
        isa_ok($reitemit, 'Handel::Iterator');
        is($reitemit, 1);

        my $reitem = $reitemit->first;
        isa_ok($reitem, 'Handel::Order::Item');
        isa_ok($reitem, $itemclass);
        is($reitem->orderid, $reorder->id);
        is($reitem->sku, 'SKU8888');
        is($reitem->quantity, 1);
        is($reitem->price, 1.11);
        is($reitem->description, 'Line Item SKU 8');
        is($reitem->total, 2.22);
        if ($itemclass ne 'Handel::Order::Item') {
            is($reitem->custom, 'custom');
        };
    };


    ## add a new item by passing a Handel::Cart::Item
    {
        my $newitem = Handel::Cart::Item->create({
            sku         => 'SKU9999',
            quantity    => 2,
            price       => 1.11,
            description => 'Line Item SKU 9',
            cart        => '00000000-0000-0000-0000-000000000000'
        });
        isa_ok($newitem, 'Handel::Cart::Item');

        my $it = $subclass->search({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);

        my $item = $order->add($newitem);
        isa_ok($item, 'Handel::Order::Item');
        isa_ok($item, $itemclass);
        is($item->orderid, $order->id);
        is($item->sku, 'SKU9999');
        is($item->quantity, 2);
        is($item->price, 1.11);
        is($item->description, 'Line Item SKU 9');
        is($item->total, 2.22);
        if ($itemclass ne 'Handel::Order::Item') {
            is($item->custom, undef);
        };

        is($order->count, 3);
        is($order->subtotal, 5.55);

        my $reit = $subclass->search({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 1);

        my $reorder = $reit->first;
        isa_ok($reorder, 'Handel::Order');
        isa_ok($reorder, $subclass);
        is($reorder->count, 3);

        my $reitemit = $order->items({sku => 'SKU9999'});
        isa_ok($reitemit, 'Handel::Iterator');
        is($reitemit, 1);

        my $reitem = $reitemit->first;
        isa_ok($reitem, 'Handel::Order::Item');
        isa_ok($reitem, $itemclass);
        is($reitem->orderid, $reorder->id);
        is($reitem->sku, 'SKU9999');
        is($reitem->quantity, 2);
        is($reitem->price, 1.11);
        is($reitem->description, 'Line Item SKU 9');
        is($reitem->total, 2.22);
        if ($itemclass ne 'Handel::Order::Item') {
            is($reitem->custom, undef);
        };
    };

};
