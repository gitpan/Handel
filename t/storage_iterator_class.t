#!perl -wT
# $Id: storage_iterator_class.t 1273 2006-07-02 00:55:55Z claco $
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

    is($storage->iterator_class, 'Handel::Iterator');

    ## throw exception when setting a bogus iterator class
    {
        try {
            $storage->iterator_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };

    is($storage->iterator_class, 'Handel::Iterator');

    ok(!Class::Inspector->loaded('Handel::Base'));
    $storage->iterator_class('Handel::Base');
    ok(Class::Inspector->loaded('Handel::Base'));

    $storage->iterator_class(undef);
    is($storage->iterator_class, undef);
};
