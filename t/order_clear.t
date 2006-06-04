#!perl -wT
# $Id: order_clear.t 1166 2006-05-28 02:35:11Z claco $
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
        plan tests =>44;
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
        my $dbfile  = "t/order_clear_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/order_create_table.sql';
        my $data    = 't/sql/order_fake_data.sql';

        unlink $dbfile;
        executesql($db, $create);
        executesql($db, $data);

        $ENV{'HandelDBIDSN'} = $db;
    };


    ## Clear order contents and validate counts
    {
        my $total_items = $subclass->schema_instance->resultset('Items')->count;
        ok($total_items);

        my $it = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $order = $it->first;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $subclass);

        my $related_items = $order->count;
        ok($related_items >= 1);

        $order->clear;
        is($order->count, 0);

        my $reorderit = $subclass->load({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($reorderit, 'Handel::Iterator');
        is($reorderit, 1);

        my $reorder = $reorderit->first;
        isa_ok($reorder, 'Handel::Order');
        isa_ok($reorder, $subclass);

        is($reorder->count, 0);

        my $remaining_items = $subclass->schema_instance->resultset('Items')->count;
        is($remaining_items, $total_items - $related_items);
    };

};
