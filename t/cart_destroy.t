#!perl -wT
# $Id: cart_destroy.t 1300 2006-07-08 01:12:16Z claco $
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
        plan tests => 68;
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
        my $dbfile  = "t/cart_destroy_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/cart_create_table.sql';
        my $data    = 't/sql/cart_fake_data.sql';

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


    my $total_carts = $subclass->storage->schema_instance->resultset('Carts')->count;
    ok($total_carts);

    my $total_items = $subclass->storage->schema_instance->resultset('Items')->count;
    ok($total_items);


    ## Destroy a single cart via instance
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

        $cart->destroy;

        my $reit = $subclass->load({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 0);

        my $recart = $reit->first;
        is($recart, undef);

        my $remaining_carts = $subclass->storage->schema_instance->resultset('Carts')->count;
        my $remaining_items = $subclass->storage->schema_instance->resultset('Items')->count;

        is($remaining_carts, $total_carts - 1);
        is($remaining_items, $total_items - $related_items);

        $total_carts--;
        $total_items -= $related_items;
    };


    ## Destroy multiple carts with wildcard filter
    {
        my $carts = $subclass->load({description => {like => 'Saved%'}}, RETURNAS_ITERATOR);
        isa_ok($carts, 'Handel::Iterator');
        is($carts, 1);

        my $related_items = $carts->first->items->count;
        ok($related_items);

        $subclass->destroy({
            description => {like => 'Saved%'}
        });

        $carts = $subclass->load({description => {like => 'Saved%'}}, RETURNAS_ITERATOR);
        isa_ok($carts, 'Handel::Iterator');
        is($carts, 0);

        my $remaining_carts = $subclass->storage->schema_instance->resultset('Carts')->count;
        my $remaining_items = $subclass->storage->schema_instance->resultset('Items')->count;

        is($remaining_carts, $total_carts - 1);
        is($remaining_items, $total_items - $related_items);
    };

};
