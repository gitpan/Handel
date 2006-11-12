#!perl -wT
# $Id: cart_destroy.t 1492 2006-10-22 23:52:28Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 84;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', qw(:cart));
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);
my $altschema = Handel::Test->init_schema(db_file => 'althandel.db', namespace => 'Handel::AltSchema');

&run('Handel::Cart', 'Handel::Cart::Item', 1);
&run('Handel::Subclassing::CartOnly', 'Handel::Cart::Item', 2);
&run('Handel::Subclassing::Cart', 'Handel::Subclassing::CartItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


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
        my $it = $subclass->search({
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

        my $reit = $subclass->search({
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
        my $carts = $subclass->search({description => {like => 'Saved%'}});
        isa_ok($carts, 'Handel::Iterator');
        is($carts, 1);

        my $related_items = $carts->first->items->count;
        ok($related_items);

        $subclass->destroy({
            description => {like => 'Saved%'}
        });

        $carts = $subclass->search({description => {like => 'Saved%'}});
        isa_ok($carts, 'Handel::Iterator');
        is($carts, 0);

        my $remaining_carts = $subclass->storage->schema_instance->resultset('Carts')->count;
        my $remaining_items = $subclass->storage->schema_instance->resultset('Items')->count;

        is($remaining_carts, $total_carts - 1);
        is($remaining_items, $total_items - $related_items);
    };


    ## Destroy carts on an instance
    {
        my $instance = bless {}, $subclass;
        my $carts = $subclass->search;
        isa_ok($carts, 'Handel::Iterator');
        is($carts, 1);

        $instance->destroy({
            description => {like => '%'}
        });

        $carts = $subclass->search;
        isa_ok($carts, 'Handel::Iterator');
        is($carts, 0);
    };
};



## pass in storage instead
{
    my $storage = Handel::Cart->storage_class->new;
    local $ENV{'HandelDBIDSN'} = $altschema->dsn;

    is($altschema->resultset('Carts')->search({id => '11111111-1111-1111-1111-111111111111'})->count, 1, 'cart found in alt storage');
    Handel::Cart->destroy({
        id => '11111111-1111-1111-1111-111111111111'
    }, {
        storage => $storage
    });
    is($altschema->resultset('Carts')->search({id => '11111111-1111-1111-1111-111111111111'})->count, 0, 'cart removed from alt storage');
};


## don't unset self if no result is returned
{
    my $storage = Handel::Cart->storage_class->new;
    local $ENV{'HandelDBIDSN'} = $altschema->dsn;

    my $cart = Handel::Cart->search({id => '22222222-2222-2222-2222-222222222222'}, {storage => $storage})->first;
    ok($cart);

    no warnings 'redefine';
    local *Handel::Storage::DBIC::Result::delete = sub {};
    $cart->destroy;
    ok($cart);
};
