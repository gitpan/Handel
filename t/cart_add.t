#!perl -wT
# $Id: cart_add.t 1500 2006-10-24 02:49:21Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 246;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Cart::Item');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartItem');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);

&run('Handel::Cart', 'Handel::Cart::Item', 1);
&run('Handel::Subclassing::CartOnly', 'Handel::Cart::Item', 2);
&run('Handel::Subclassing::Cart', 'Handel::Subclassing::CartItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


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
        my $it = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $cart = $it->first;
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

        my $reit = $subclass->search({
            id => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($reit, 'Handel::Iterator');
        is($reit, 1);

        my $recart = $reit->first;
        isa_ok($recart, $subclass);
        is($recart->count, 3);

        my $reitemit = $cart->items({sku => 'SKU9999'});
        isa_ok($reitemit, 'Handel::Iterator');
        is($reitemit, 1);

        my $reitem = $reitemit->first;
        isa_ok($reitem, 'Handel::Cart::Item');
        isa_ok($reitem, $itemclass);
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
            description => 'Line Item SKU 8',
            cart        => '00000000-0000-0000-0000-000000000000'
        };
        if ($itemclass ne 'Handel::Cart::Item') {
            $data->{'custom'} = 'custom';
        };

        my $newitem = $itemclass->create($data);
        isa_ok($newitem, 'Handel::Cart::Item');
        isa_ok($newitem, $itemclass);

        my $it = $subclass->search({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($it, 'Handel::Iterator');
        is($it, 1);

        my $cart = $it->first;
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);

        my $item = $cart->add($newitem);
        isa_ok($item, 'Handel::Cart::Item');
        isa_ok($item, $itemclass);
        is($item->cart, $cart->id);
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

        my $recartit = $subclass->search({
            id => '22222222-2222-2222-2222-222222222222'
        });
        isa_ok($recartit, 'Handel::Iterator');
        is($recartit, 1);

        my $recart = $recartit->first;
        isa_ok($recart, $subclass);
        isa_ok($recart, 'Handel::Cart');
        is($recart->count, 2);

        my $reitemit = $cart->items({sku => 'SKU8888'});
        isa_ok($reitemit, 'Handel::Iterator');
        is($reitemit, 1);

        my $reitem = $reitemit->first;
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


## add a new item by passing a Handel::Cart::Item where object has no column
## accessor methods, but the result does
{
    local *Handel::Cart::Item::can = sub {};

    my $data = {
        sku         => 'SKU8888',
        quantity    => 1,
        price       => 1.11,
        description => 'Line Item SKU 8',
        cart        => '00000000-0000-0000-0000-000000000001'
    };

    my $newitem = Handel::Cart::Item->create($data);
    isa_ok($newitem, 'Handel::Cart::Item');

    my $it = Handel::Cart->search({
        id => '22222222-2222-2222-2222-222222222222'
    });
    isa_ok($it, 'Handel::Iterator');
    is($it, 1);

    my $cart = $it->first;
    isa_ok($cart, 'Handel::Cart');


    my $item = $cart->add($newitem);
    isa_ok($item, 'Handel::Cart::Item');
    is($item->cart, $cart->id);
    is($item->sku, 'SKU8888');
    is($item->quantity, 1);
    is($item->price, 1.11);
    is($item->description, 'Line Item SKU 8');
    is($item->total, 1.11);

    is($cart->count, 3);
    is($cart->subtotal, 12.21);

    my $recartit = Handel::Cart->search({
        id => '22222222-2222-2222-2222-222222222222'
    });
    isa_ok($recartit, 'Handel::Iterator');
    is($recartit, 1);

    my $recart = $recartit->first;
    isa_ok($recart, 'Handel::Cart');
    is($recart->count, 3);

    my $reitemit = $cart->items({sku => 'SKU8888'});
    isa_ok($reitemit, 'Handel::Iterator');
    is($reitemit, 2);

    my $reitem = $reitemit->first;
    isa_ok($reitem, 'Handel::Cart::Item');
    is($reitem->cart, $cart->id);
    is($reitem->sku, 'SKU8888');
    is($reitem->quantity, 1);
    is($reitem->price, 1.11);
    is($reitem->description, 'Line Item SKU 8');
    is($reitem->total, 1.11);
};


## add a new item by passing a Handel::Cart::Item where object has no column
## accessor methods and no result accessor methods
{
    no warnings 'once';
    no warnings 'redefine';

    local *Handel::Cart::Item::can = sub {};
    local *Handel::Storage::DBIC::Result::can = sub {return 1 if $_[1] eq 'sku'};

    my $data = {
        sku         => 'SKU8888',
        quantity    => 1,
        price       => 1.11,
        description => 'Line Item SKU 8',
        cart        => '00000000-0000-0000-0000-000000000002'
    };

    my $newitem = Handel::Cart::Item->create($data);
    isa_ok($newitem, 'Handel::Cart::Item');

    my $it = Handel::Cart->search({
        id => '22222222-2222-2222-2222-222222222222'
    });
    isa_ok($it, 'Handel::Iterator');
    is($it, 1);

    my $cart = $it->first;
    isa_ok($cart, 'Handel::Cart');


    my $item = $cart->add($newitem);
    isa_ok($item, 'Handel::Cart::Item');
    is($item->cart, $cart->id);
    is($item->sku, 'SKU8888');
    is($item->quantity, 1);
    is($item->price, 0);
    is($item->description, undef);
    is($item->total, 0);

    is($cart->count, 4);
    is($cart->subtotal, 12.21);

    my $recartit = Handel::Cart->search({
        id => '22222222-2222-2222-2222-222222222222'
    });
    isa_ok($recartit, 'Handel::Iterator');
    is($recartit, 1);

    my $recart = $recartit->first;
    isa_ok($recart, 'Handel::Cart');
    is($recart->count, 4);

    my $reitemit = $cart->items();
    isa_ok($reitemit, 'Handel::Iterator');
    is($reitemit, 4);

    my $reitem = $reitemit->last;
    isa_ok($reitem, 'Handel::Cart::Item');
    is($reitem->cart, $cart->id);
    is($reitem->sku, 'SKU8888');
    is($reitem->quantity, 1);
    is($reitem->price, 0);
    is($reitem->description, undef);
    is($reitem->total, 0);
};
