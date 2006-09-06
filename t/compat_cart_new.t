#!perl -wT
# $Id: compat_cart_new.t 1360 2006-08-09 03:17:09Z claco $
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
        plan tests => 160;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Subclassing::Cart');
    use_ok('Handel::Subclassing::CartOnly');
    use_ok('Handel::Constants', ':cart');
    use_ok('Handel::Constraints', 'constraint_uuid');
    use_ok('Handel::Exception', ':try');

    local $SIG{__WARN__} = sub {
        like(shift, qr/deprecated/);
    };
    use_ok('Handel::Compat');
};


## This is a hack, but it works. :-)
&run('Handel::Cart', 'Handel::Cart::Item', 1);
&run('Handel::Subclassing::CartOnly', 'Handel::Cart::Item', 2);
&run('Handel::Subclassing::Cart', 'Handel::Subclassing::CartItem', 3);

sub run {
    my ($subclass, $itemclass, $dbsuffix) = @_;


    ## Setup SQLite DB for tests
    {
        my $dbfile  = "t/compat_cart_new_$dbsuffix.db";
        my $db      = "dbi:SQLite:dbname=$dbfile";
        my $create  = 't/sql/cart_create_table.sql';
        my $data    = 't/sql/cart_fake_data.sql';

        unlink $dbfile;
        executesql($db, $create);
        executesql($db, $data);

        $ENV{'HandelDBIDSN'} = $db;

        no strict 'refs';
        unshift @{"$subclass\:\:ISA"}, 'Handel::Compat' unless $subclass->isa('Handel::Compat');
        unshift @{"itemclass\:\:ISA"}, 'Handel::Compat' unless $itemclass->isa('Handel::Compat');
    };


    ## test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            my $cart = $subclass->new(sku => 'SKU1234');

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
            my $cart = $subclass->new({
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
            my $cart = $subclass->new({
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
            my $cart = $subclass->new({
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
            my $cart = $subclass->new(\%data);

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
            my $cart = $subclass->new({
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
        my $cart = $subclass->new({
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

        eval 'use Locale::Currency::Format';
        if ($@) {
            is($cart->subtotal->format, 0);
            is($cart->subtotal->format('CAD'), 0);
            is($cart->subtotal->format(undef, 'FMT_NAME'), 0);
            is($cart->subtotal->format('CAD', 'FMT_NAME'), 0);
        } else {
            is($cart->subtotal->format, '0.00 USD');
            is($cart->subtotal->format('CAD'), '0.00 CAD');
            is($cart->subtotal->format(undef, 'FMT_NAME'), '0.00 US Dollar');
            is($cart->subtotal->format('CAD', 'FMT_NAME'), '0.00 Canadian Dollar');
        };
    };


    ## add a new temp cart and supply a manual id
    {
        my $cart = $subclass->new({
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
        my $cart = $subclass->new({
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
        my $cart = $subclass->new({
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