#!perl -wT
# $Id: base_item_class.t 1409 2006-09-09 21:16:54Z claco $
use strict;
use warnings;
use Class::Inspector;
use Test::More tests => 8;

BEGIN {
    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


{
    is(Handel::Base->item_class, undef);

    ## throw exception when setting a bogus item class
    {
        try {
            Handel::Base->cart_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception with {
            pass;
        } otherwise {
            fail;
        };
    };

    is(Handel::Base->item_class, undef);

    ok(!Class::Inspector->loaded('Handel::Cart::Item'));
    Handel::Base->item_class('Handel::Cart::Item');
    ok(Class::Inspector->loaded('Handel::Cart::Item'));

    Handel::Base->item_class(undef);
    is(Handel::Base->item_class, undef);
};
