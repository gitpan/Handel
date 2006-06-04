#!perl -wT
# $Id$
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
        plan tests => 70;
    };

    use_ok('Handel::Order');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
    use_ok('Handel::Constants', qw(:order :returnas));
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
        my $dbfile  = "t/order_destroy_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/order_create_table.sql';
        my $data    = 't/sql/order_fake_data.sql';

        unlink $dbfile;
        executesql($db, $create);
        executesql($db, $data);

        $ENV{'HandelDBIDSN'} = $db;
    };


    ## Test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            $subclass->destroy(id => '1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    my $total_orders = $subclass->schema_instance->resultset('Orders')->count;
    ok($total_orders);

    my $total_items = $subclass->schema_instance->resultset('Items')->count;
    ok($total_items);


    ## Destroy a single order via instance
    {
        my $it = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);

        my $related_items = $order->count;
        is($related_items, 1);
        is($order->subtotal, 5.55);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };

        $order->destroy;

        my $reit = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 0);

        my $reorder = $reit->first;
        is($reorder, undef);

        my $remaining_orders = $subclass->schema_instance->resultset('Orders')->count;
        my $remaining_items = $subclass->schema_instance->resultset('Items')->count;

        is($remaining_orders, $total_orders - 1);
        is($remaining_items, $total_items - $related_items);

        $total_orders--;
        $total_items -= $related_items;
    };


    ## Destroy multiple orders with wildcard filter
    {
        my $orders = $subclass->load({id => '11111%'}, RETURNAS_ITERATOR);
        isa_ok($orders, 'Handel::Iterator');
        is($orders, 1);

        my $related_items = $orders->first->items->count;
        ok($related_items);

        $subclass->destroy({
            id => '111%'
        });

        $orders = $subclass->load({id => '11111%'}, RETURNAS_ITERATOR);
        isa_ok($orders, 'Handel::Iterator');
        is($orders, 0);

        my $remaining_orders = $subclass->schema_instance->resultset('Orders')->count;
        my $remaining_items = $subclass->schema_instance->resultset('Items')->count;

        is($remaining_orders, $total_orders - 1);
        is($remaining_items, $total_items - $related_items);
    };

};
