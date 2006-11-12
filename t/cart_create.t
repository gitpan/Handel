#!perl -wT
# $Id: cart_create.t 1490 2006-10-22 01:56:21Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Scalar::Util qw/refaddr/;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 169;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Constraints', 'constraint_uuid');
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);
my $altschema = Handel::Test->init_schema(no_populate => 1, db_file => 'althandel.db', namespace => 'Handel::AltSchema');

&run('Handel::Cart', 'Handel::Cart::Item', 1);
&run('Handel::Subclassing::CartOnly', 'Handel::Cart::Item', 2);
&run('Handel::Subclassing::Cart', 'Handel::Subclassing::CartItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


    ## test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            my $cart = $subclass->create(sku => 'SKU1234');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Constraint during cart new for bogus shopper
    {
        try {
            my $cart = $subclass->create({
                id      => '11111111-1111-1111-1111-111111111111',
                shopper => 'crap'
            });

            fail;
        } catch Handel::Exception::Constraint with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Constraint during cart new for empty shopper
    {
        try {
            my $cart = $subclass->create({
                id      => '11111111-1111-1111-1111-111111111111'
            });

            fail;
        } catch Handel::Exception::Constraint with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Constraint during cart new when no name is
    ## specified and cart type has been set to CART_TYPE_SAVED
    {
        try {
            my $cart = $subclass->create({
                id      => '11111111-1111-1111-1111-111111111111',
                shopper => '33333333-3333-3333-3333-333333333333',
                type    => CART_TYPE_SAVED
            });

            fail;
        } catch Handel::Exception::Constraint with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## just for giggles, let's pass it in a different way
    {
        my %data = (id      => '11111111-1111-1111-1111-111111111111',
                    shopper => '33333333-3333-3333-3333-333333333333',
                    type    => CART_TYPE_SAVED
        );

        try {
            my $cart = $subclass->create(\%data);

            fail;
        } catch Handel::Exception::Constraint with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for raw db key violation
    {
        try {
            my $cart = $subclass->create({
                id      => '11111111-1111-1111-1111-111111111111',
                shopper => '11111111-1111-1111-1111-111111111111'
            });

            fail;
        } catch Handel::Exception::Constraint with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## add a new temp cart and test auto id creation
    {
        my $cart = $subclass->create({
            shopper => '11111111-1111-1111-1111-111111111111'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        ok(constraint_uuid($cart->id));
        is($cart->shopper, '11111111-1111-1111-1111-111111111111');
        is($cart->type, CART_TYPE_TEMP);
        is($cart->name, undef);
        is($cart->description, undef);
        is($cart->count, 0);
        is($cart->subtotal, 0);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, undef);
        };


        is($cart->subtotal->format, '0.00 USD');
        is($cart->subtotal->format('FMT_NAME'), '0.00 US Dollar');
        {
            local $ENV{'HandelCurrencyCode'} = 'CAD';
            is($cart->subtotal->format, '0.00 CAD');
            is($cart->subtotal->format('FMT_NAME'), '0.00 Canadian Dollar');
        };
    };


    ## add a new temp cart and supply a manual id
    {
        my $cart = $subclass->create({
            id      => '77777777-7777-7777-7777-777777777777',
            shopper => '77777777-7777-7777-7777-777777777777'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        ok(constraint_uuid($cart->id));
        is($cart->id, '77777777-7777-7777-7777-777777777777');
        is($cart->shopper, '77777777-7777-7777-7777-777777777777');
        is($cart->type, CART_TYPE_TEMP);
        is($cart->name, undef);
        is($cart->description, undef);
        is($cart->count, 0);
        is($cart->subtotal, 0);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, undef);
        };
    };


    ## add a new saved cart and test auto id creation
    {
        my $cart = $subclass->create({
            shopper => '88888888-8888-8888-8888-888888888888',
            type    => CART_TYPE_SAVED,
            name    => 'My Cart',
            description => 'My Cart Description'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        ok(constraint_uuid($cart->id));
        is($cart->shopper, '88888888-8888-8888-8888-888888888888');
        is($cart->type, CART_TYPE_SAVED);
        is($cart->name, 'My Cart');
        is($cart->description, 'My Cart Description');
        is($cart->count, 0);
        is($cart->subtotal, 0);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, undef);
        };
    };


    ## add a new saved cart and supply a manual id
    {
        my $cart = $subclass->create({
            id      => '99999999-9999-9999-9999-999999999999',
            shopper => '99999999-9999-9999-9999-999999999999',
            type    => CART_TYPE_SAVED,
            name    => 'My Cart',
            description => 'My Cart Description'
        });
        isa_ok($cart, 'Handel::Cart');
        isa_ok($cart, $subclass);
        ok(constraint_uuid($cart->id));
        is($cart->id, '99999999-9999-9999-9999-999999999999');
        is($cart->shopper, '99999999-9999-9999-9999-999999999999');
        is($cart->type, CART_TYPE_SAVED);
        is($cart->name, 'My Cart');
        is($cart->description, 'My Cart Description');
        is($cart->count, 0);
        is($cart->subtotal, 0);
        if ($subclass ne 'Handel::Cart') {
            is($cart->custom, undef);
        };
    };
};


## pass in storage instead
{
    my $storage = Handel::Cart->storage_class->new;
    local $ENV{'HandelDBIDSN'} = $altschema->dsn;

    my $cart = Handel::Cart->create({
        shopper => '88888888-8888-8888-8888-888888888888',
        type    => CART_TYPE_SAVED,
        name    => 'My Alt Cart',
        description => 'My Alt Cart Description'
    }, {
        storage => $storage
    });
    isa_ok($cart, 'Handel::Cart');
    ok(constraint_uuid($cart->id));
    is($cart->shopper, '88888888-8888-8888-8888-888888888888');
    is($cart->type, CART_TYPE_SAVED);
    is($cart->name, 'My Alt Cart');
    is($cart->description, 'My Alt Cart Description');
    is($cart->count, 0);
    is($cart->subtotal, 0);
    is(refaddr $cart->result->storage, refaddr $storage, 'storage option used');
    is($altschema->resultset('Carts')->search({name => 'My Alt Cart'})->count, 1, 'cart found in alt storage');
    is($schema->resultset('Carts')->search({name => 'My Alt Cart'})->count, 0, 'alt cart not in class storage');
};
