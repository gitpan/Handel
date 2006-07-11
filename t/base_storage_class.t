#!perl -wT
# $Id: base_storage_class.t 1268 2006-06-30 02:06:54Z claco $
use strict;
use warnings;
use Class::Inspector;
use lib 't/lib';
use Test::More tests => 9;

BEGIN {
    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


{
    my $base = bless {}, 'Handel::Base';
    
    is($base->storage_class, 'Handel::Storage');
    
    ok(!Class::Inspector->loaded('Handel::Subclassing::Storage'));
    $base->storage_class('Handel::Subclassing::Storage');
    is($base->storage_class, 'Handel::Subclassing::Storage');
    ok(Class::Inspector->loaded('Handel::Subclassing::Storage'));

    ## throw exception when setting a bogus storage class
    {
        try {
            $base->storage_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };

    is($base->storage_class, 'Handel::Subclassing::Storage');
    $base->storage_class(undef);
    is($base->storage_class, undef);
};
