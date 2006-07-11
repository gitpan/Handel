#!perl -wT
# $Id: storage_schema_class.t 1242 2006-06-27 02:22:20Z claco $
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

    is($storage->schema_class, undef);

    ## throw exception when setting a bogus schema class
    {
        try {
            $storage->schema_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };

    is($storage->schema_class, undef);

    ok(!Class::Inspector->loaded('Handel::Base'));
    $storage->schema_class('Handel::Base');
    ok(Class::Inspector->loaded('Handel::Base'));

    $storage->schema_class(undef);
    is($storage->schema_class, undef);
};
