#!perl -wT
# $Id: storage_dbic_schema_class.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Class::Inspector;
use Test::More tests => 9;

BEGIN {
    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};


{
    my $storage = Handel::Storage::DBIC->new();
    isa_ok($storage, 'Handel::Storage::DBIC');

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
