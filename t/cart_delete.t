#!perl -wT
# $Id: cart_delete.t 1164 2006-05-23 23:59:47Z claco $
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
        plan tests => 107;
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
        my $dbfile  = "t/cart_delete_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/cart_create_table.sql';
        my $data    = 't/sql/cart_fake_data.sql';

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


    my $total_items = $subclass->schema_instance->resultset('Items')->count;
    ok($total_items);


    ## Delete a single cart item contents and validate counts
    {
        my $it = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $cart = $it->first;
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);

        my $related_items = $cart->count;
        is($related_items, 1);
        is($cart->subtotal, 9.99);
        is($cart->delete({sku => 'SKU3333'}), 1);
        is($cart->count, 0);
        is($cart->subtotal, 0);

        my $reit = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 1);

        my $recart = $reit->first;
        isa_ok($recart, 'Handel::Cart');
        isa_ok($recart, $subclass);
        is($recart->count, 0);
        is($recart->subtotal, 0.00);

        my $remaining_items = $subclass->schema_instance->resultset('Items')->count;
        is($remaining_items, $total_items - $related_items);

        $total_items -= $related_items;
    };


    ## Delete multiple cart item contents with wildcard filter and validate
    ## counts using the old style wildcards
    {
        my $it = $subclass->load({
            id => '33333333-3333-3333-3333-333333333333'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $cart = $it->first;
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);

        my $related_items = $cart->count;
        is($related_items, 2);
        is($cart->subtotal, 45.51);
        ok($cart->delete({sku => 'SKU%'}));
        is($cart->count, 0);
        is($cart->subtotal, 0);

        my $reit = $subclass->load({
            id => '33333333-3333-3333-3333-333333333333'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 1);

        my $recart = $reit->first;
        isa_ok($recart, 'Handel::Cart');
        isa_ok($recart, $subclass);
        is($recart->count, 0);
        is($recart->subtotal, 0.00);

        my $remaining_items = $subclass->schema_instance->resultset('Items')->count;
        is($remaining_items, $total_items - $related_items);
    };
};
