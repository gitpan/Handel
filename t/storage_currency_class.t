#!perl -wT
# $Id: storage_currency_class.t 1255 2006-06-28 01:53:00Z claco $
use strict;
use warnings;
use Class::Inspector;
use Test::More tests => 9;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    my $storage = Handel::Storage->new();
    isa_ok($storage, 'Handel::Storage');

    is($storage->currency_class, 'Handel::Currency');

    ## throw exception when setting a bogus currency class
    {
        try {
            $storage->currency_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };

    is($storage->currency_class, 'Handel::Currency');

    ok(!Class::Inspector->loaded('Handel::Base'));
    $storage->currency_class('Handel::Base');
    ok(Class::Inspector->loaded('Handel::Base'));

    $storage->currency_class(undef);
    is($storage->currency_class, undef);
};
