#!perl -wT
# $Id: order_load.t 1336 2006-07-15 03:54:43Z claco $
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
        plan tests => 318;
    };

    use_ok('Handel::Order');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
    use_ok('Handel::Constants', qw(:order));
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
        my $dbfile  = "t/order_load_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/order_create_table.sql';
        my $data    = 't/sql/order_fake_data.sql';

        unlink $dbfile;
        executesql($db, $create);
        executesql($db, $data);

        $ENV{'HandelDBIDSN'} = $db;
    };


    ## test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            my $order = $subclass->load(id => '1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## load a single cart returning a Handel::Cart object
    {
        my $it = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };
    };


    ## load a single order returning a Handel::Iterator object
    {
        my $iterator = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        }, 1);
        isa_ok($iterator, 'Handel::Iterator');
    };


    ## load all orders for the shopper returning a Handel::Iterator object
    {
        my $iterator = $subclass->load({
            shopper => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($iterator, 'Handel::Iterator');
    };


    ## load all carts into an array without a filter
    {
        my @orders = $subclass->load();
        is(scalar @orders, 3);

        my $order1 = $orders[0];
        isa_ok($order1, 'Handel::Order');
        isa_ok($order1, $subclass);
        is($order1->id, '11111111-1111-1111-1111-111111111111');
        is($order1->shopper, '11111111-1111-1111-1111-111111111111');
        is($order1->type,ORDER_TYPE_TEMP);
        is($order1->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order1->custom, 'custom');
        };

        my $order2 = $orders[1];
        isa_ok($order2, 'Handel::Order');
        isa_ok($order2, $subclass);
        is($order2->id, '22222222-2222-2222-2222-222222222222');
        is($order2->shopper, '11111111-1111-1111-1111-111111111111');
        is($order2->type, ORDER_TYPE_SAVED);
        is($order2->count, 1);
        if ($subclass ne 'Handel::Order') {
            is($order2->custom, 'custom');
        };

        my $order3 = $orders[2];
        isa_ok($order3, 'Handel::Order');
        isa_ok($order3, $subclass);
        is($order3->id, '33333333-3333-3333-3333-333333333333');
        is($order3->shopper, '33333333-3333-3333-3333-333333333333');
        is($order3->type, ORDER_TYPE_SAVED);
        is($order3->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order3->custom, 'custom');
        };
    };


    ## load all orders into an array without a filter
    {
        my @orders = $subclass->load();
        is(scalar @orders, 3);

        my $order1 = $orders[0];
        isa_ok($order1, 'Handel::Order');
        isa_ok($order1, $subclass);
        is($order1->id, '11111111-1111-1111-1111-111111111111');
        is($order1->shopper, '11111111-1111-1111-1111-111111111111');
        is($order1->type, ORDER_TYPE_TEMP);
        is($order1->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order1->custom, 'custom');
        };

        my $order2 = $orders[1];
        isa_ok($order2, 'Handel::Order');
        isa_ok($order2, $subclass);
        is($order2->id, '22222222-2222-2222-2222-222222222222');
        is($order2->shopper, '11111111-1111-1111-1111-111111111111');
        is($order2->type, ORDER_TYPE_SAVED);
        is($order2->count, 1);
        if ($subclass ne 'Handel::Order') {
            is($order2->custom, 'custom');
        };

        my $order3 = $orders[2];
        isa_ok($order3, 'Handel::Order');
        isa_ok($order3, $subclass);
        is($order3->id, '33333333-3333-3333-3333-333333333333');
        is($order3->shopper, '33333333-3333-3333-3333-333333333333');
        is($order3->type, ORDER_TYPE_SAVED);
        is($order3->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order3->custom, 'custom');
        };
    };


    ## load all orders into an array with a filter
    {
        my @orders = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        is(scalar @orders, 1);

        my $order = $orders[0];
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);
        is($order->id, '22222222-2222-2222-2222-222222222222');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_SAVED);
        is($order->count, 1);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };
    };


    ## load all orders into an array with a wildcard filter
    {
        my @orders = $subclass->load({
            id => '%-%'
        });
        is(scalar @orders, 3);

        my $order1 = $orders[0];
        isa_ok($order1, 'Handel::Order');
        isa_ok($order1, $subclass);
        is($order1->id, '11111111-1111-1111-1111-111111111111');
        is($order1->shopper, '11111111-1111-1111-1111-111111111111');
        is($order1->type, ORDER_TYPE_TEMP);
        is($order1->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order1->custom, 'custom');
        };

        my $order2 = $orders[1];
        isa_ok($order2, 'Handel::Order');
        isa_ok($order2, $subclass);
        is($order2->id, '22222222-2222-2222-2222-222222222222');
        is($order2->shopper, '11111111-1111-1111-1111-111111111111');
        is($order2->type, ORDER_TYPE_SAVED);
        is($order2->count, 1);
        if ($subclass ne 'Handel::Order') {
            is($order2->custom, 'custom');
        };

        my $order3 = $orders[2];
        isa_ok($order3, 'Handel::Order');
        isa_ok($order3, $subclass);
        is($order3->id, '33333333-3333-3333-3333-333333333333');
        is($order3->shopper, '33333333-3333-3333-3333-333333333333');
        is($order3->type, ORDER_TYPE_SAVED);
        is($order3->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order3->custom, 'custom');
        };
    };


    ## load all orders into an array with SQL::Abstract wildcard filter
    {
        my @orders = $subclass->load({
            id => {like => '%-%'}
        });
        is(scalar @orders, 3);

        my $order1 = $orders[0];
        isa_ok($order1, 'Handel::Order');
        isa_ok($order1, $subclass);
        is($order1->id, '11111111-1111-1111-1111-111111111111');
        is($order1->shopper, '11111111-1111-1111-1111-111111111111');
        is($order1->type, ORDER_TYPE_TEMP);
        is($order1->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order1->custom, 'custom');
        };

        my $order2 = $orders[1];
        isa_ok($order2, 'Handel::Order');
        isa_ok($order2, $subclass);
        is($order2->id, '22222222-2222-2222-2222-222222222222');
        is($order2->shopper, '11111111-1111-1111-1111-111111111111');
        is($order2->type, ORDER_TYPE_SAVED);
        is($order2->count, 1);
        if ($subclass ne 'Handel::Order') {
            is($order2->custom, 'custom');
        };

        my $order3 = $orders[2];
        isa_ok($order3, 'Handel::Order');
        isa_ok($order3, $subclass);
        is($order3->id, '33333333-3333-3333-3333-333333333333');
        is($order3->shopper, '33333333-3333-3333-3333-333333333333');
        is($order3->type, ORDER_TYPE_SAVED);
        is($order3->count, 2);
        if ($subclass ne 'Handel::Order') {
            is($order3->custom, 'custom');
        };
    };


    ## load returns 0
    {
        my $order = $subclass->load({
            id => 'notfound'
        });
        is($order, 0);
    };

};
