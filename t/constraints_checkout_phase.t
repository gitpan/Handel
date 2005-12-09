#!perl -wT
# $Id: constraints_checkout_phase.t 1007 2005-12-08 04:51:54Z claco $
use strict;
use warnings;
use Test::More tests => 18;

BEGIN {
    use_ok('Handel::Constraints', qw(:all));
    use_ok('Handel::Checkout');
    use_ok('Handel::Constants', qw(:checkout));
    use_ok('Handel::Exception', qw(:try));
};

ok(!constraint_checkout_phase('junk.foo'), 'alpha gibberish type');
ok(!constraint_checkout_phase(-14), 'negative number type');
ok(!constraint_checkout_phase(23), 'out of range type');
ok(constraint_checkout_phase(CHECKOUT_PHASE_INITIALIZE), 'checkout initialize phase');
ok(constraint_checkout_phase(CHECKOUT_PHASE_VALIDATE), 'checkout validation phase');
ok(constraint_checkout_phase(CHECKOUT_PHASE_AUTHORIZE), 'checkout authorization phase');
ok(constraint_checkout_phase(CHECKOUT_PHASE_FINALIZE), 'checkout finalization phase');
ok(constraint_checkout_phase(CHECKOUT_PHASE_DELIVER), 'checkout delivery phase');


## Added a new checkout phase
{
    Handel::Checkout->add_phase('CUSTOM_CHECKOUT_PHASE', 99, 1);
    can_ok('Handel::Constants', 'CUSTOM_CHECKOUT_PHASE');
    can_ok('main', 'CUSTOM_CHECKOUT_PHASE');
    ok(constraint_checkout_phase(Handel::Constants->CUSTOM_CHECKOUT_PHASE), 'custom checkout phase');
    ok(constraint_checkout_phase(&CUSTOM_CHECKOUT_PHASE), 'custom checkout phase');
    is(Handel::Constants->CUSTOM_CHECKOUT_PHASE, 99);
    is(&CUSTOM_CHECKOUT_PHASE, 99);
};
