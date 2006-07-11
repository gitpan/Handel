#!perl -wT
# $Id: order_delete.t 1303 2006-07-08 19:35:05Z claco $
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
        plan tests =>115;
    };

    use_ok('Handel::Order');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
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
        my $dbfile  = "t/order_delete_$dbsuffix.db";
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
            $subclass->delete(id => '1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    my $total_items = $subclass->storage->schema_instance->resultset('Items')->count;
    ok($total_items);


    ## Delete a single order item contents and validate counts
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

        is($order->delete({sku => 'SKU3333'}), 1);
        is($order->count, 0);
        is($order->subtotal, 5.55);

        my $reit = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 1);

        my $reorder = $reit->first;
        isa_ok($reorder, 'Handel::Order');
        isa_ok($reorder, $subclass);
        is($reorder->count, 0);
        is($reorder->subtotal, 5.55);
        if ($subclass ne 'Handel::Order') {
            is($reorder->custom, 'custom');
        };

        my $remaining_items = $subclass->storage->schema_instance->resultset('Items')->count;
        is($remaining_items, $total_items - $related_items);

        $total_items -= $related_items;
    };


    ## Delete multiple order item contents with wildcard filter and validate counts
    {
        my $it = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);

        my $related_items = $order->count;
        is($related_items, 2);
        is($order->subtotal, 5.55);
        if ($subclass ne 'Handel::Order') {
            is($order->custom, 'custom');
        };

        ok($order->delete({sku => 'SKU%'}));
        is($order->count, 0);
        is($order->subtotal, 5.55);

        my $reit = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 1);

        my $reorder = $reit->first;
        isa_ok($reorder, 'Handel::Order');
        isa_ok($reorder, $subclass);
        is($reorder->count, 0);
        is($reorder->subtotal, 5.55);
        if ($subclass ne 'Handel::Order') {
            is($reorder->custom, 'custom');
        };

        my $remaining_items = $subclass->storage->schema_instance->resultset('Items')->count;
        is($remaining_items, $total_items - $related_items);
    };

};
