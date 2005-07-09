#!perl -wT
# $Id: checkout_phases.t 580 2005-07-09 16:29:25Z claco $
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
        plan tests => 11;
    };

    use_ok('Handel::Checkout');
    use_ok('Handel::Constants', qw(:checkout));
    use_ok('Handel::Exception', ':try');
};


## Check for Handel::Exception::Argument when we pass something other
## than an array reference
{
    try {
        my $checkout = Handel::Checkout->new;

        $checkout->phases('1234');
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};



## Check for Handel::Exception::Argument when we pass something other
## than an array reference in news' phases option
{
    try {
        my $checkout = Handel::Checkout->new({phases => '1234'});
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## Set the phases and make sure they stick
{
    my $checkout = Handel::Checkout->new;

    $checkout->phases([CHECKOUT_PHASE_AUTHORIZE]);

    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    is(scalar @{$phases}, 1);
    is($phases->[0], CHECKOUT_PHASE_AUTHORIZE);
};


## Set the phases using news' phases option and make sure they stick
{
    my $checkout = Handel::Checkout->new({phases => [CHECKOUT_PHASE_DELIVER]});
    my $phases = $checkout->phases;
    isa_ok($phases, 'ARRAY');
    is(scalar @{$phases}, 1);
    is($phases->[0], CHECKOUT_PHASE_DELIVER);
};