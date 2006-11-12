#!perl -wT
# $Id: checkout_order.t 1481 2006-10-18 02:51:46Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 130;
    };

    use_ok('Handel::Checkout');
    use_ok('Handel::Constants', qw(:order));
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Order');
    use_ok('Handel::Subclassing::Order');
    use_ok('Handel::Subclassing::OrderOnly');
};


## throw exception when setting a bogus order class
{
    try {
        Handel::Checkout->order_class('Funklebean');

        fail('no exception thrown');
    } catch Handel::Exception::Checkout with {
        pass('caught Handel::Exception::Checkout');
    } otherwise {
        fail('failed to catch Handel::Exception');
    };
};


## unset something altogether
{
    is(Handel::Checkout->order_class, 'Handel::Order', 'order class is set');
    Handel::Checkout->order_class(undef);
    is(Handel::Checkout->order_class, undef, 'order class is unset');
    Handel::Checkout->order_class('Handel::Order');
    is(Handel::Checkout->order_class, 'Handel::Order', 'order class is reset');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);

&run('Handel::Checkout', 'Handel::Order', 1);
&run('Handel::Checkout', 'Handel::Subclassing::Order', 2);
&run('Handel::Checkout', 'Handel::Subclassing::OrderOnly', 3);

sub run {
    my ($subclass, $orderclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;

    $subclass->order_class($orderclass);

    ## test for Handel::Exception::Argument where first param is not a hashref
    ## no constraint_uuid check now. instead we just do nothing.
    {
        try {
            my $checkout = $subclass->new;

            $checkout->order('1234');
        } catch Handel::Exception::Checkout with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where order option is not a hashref
    {
        try {
            my $checkout = $subclass->new({order => '1234'});

            ok(!$checkout->order);
        } catch Handel::Exception::Checkout with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where order object is not a Handel::Order object
    {
        try {
            my $checkout = $subclass->new;
            my $fake = bless {}, 'MyObject::Foo';
            $checkout->order($fake);

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where order option object is not a Handel::Order object
    {
        try {
            my $fake = bless {}, 'MyObject::Foo';
            my $checkout = $subclass->new({order => $fake});

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## assign the order using a uuid
    {
        my $checkout = $subclass->new;

        $checkout->order('11111111-1111-1111-1111-111111111111');

        my $order = $checkout->order;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $orderclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
    };


    ## assign the order using a uuid as new option
    {
        my $checkout = $subclass->new({order => '11111111-1111-1111-1111-111111111111'});
        my $order = $checkout->order;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $orderclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
    };


    ## assign the order using a search hash
    {
        my $checkout = $subclass->new;

        $checkout->order({
            id => '11111111-1111-1111-1111-111111111111',
            type => ORDER_TYPE_TEMP
        });

        my $order = $checkout->order;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $orderclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
    };


    ## assign the order using a search hash as a new option
    {
        my $checkout = $subclass->new({ order => {
            id => '11111111-1111-1111-1111-111111111111',
            type => ORDER_TYPE_TEMP}
        });

        my $order = $checkout->order;
        isa_ok($order, 'Handel::Order');
        isa_ok($order, $orderclass);
        is($order->id, '11111111-1111-1111-1111-111111111111');
        is($order->shopper, '11111111-1111-1111-1111-111111111111');
        is($order->type, ORDER_TYPE_TEMP);
        is($order->count, 2);
    };


    ## assign the order using a Handel::Order object
    {
        my $order = $orderclass->search({
            id => '11111111-1111-1111-1111-111111111111',
            type => ORDER_TYPE_TEMP
        })->first;
        my $checkout = $subclass->new;

        $checkout->order($order);

        my $loadedorder = $checkout->order;
        isa_ok($loadedorder, 'Handel::Order');
        isa_ok($loadedorder, $orderclass);
        is($loadedorder->id, '11111111-1111-1111-1111-111111111111');
        is($loadedorder->shopper, '11111111-1111-1111-1111-111111111111');
        is($loadedorder->type, ORDER_TYPE_TEMP);
        is($loadedorder->count, 2);
    };


    ## assign the order using a Handel::Order object as a new option
    {
        my $order = $orderclass->search({
            id => '11111111-1111-1111-1111-111111111111',
            type => ORDER_TYPE_TEMP
        })->first;
        my $checkout = $subclass->new({order => $order});

        my $loadedorder = $checkout->order;
        isa_ok($loadedorder, 'Handel::Order');
        isa_ok($loadedorder, $orderclass);
        is($loadedorder->id, '11111111-1111-1111-1111-111111111111');
        is($loadedorder->shopper, '11111111-1111-1111-1111-111111111111');
        is($loadedorder->type, ORDER_TYPE_TEMP);
        is($loadedorder->count, 2);
    };

};
