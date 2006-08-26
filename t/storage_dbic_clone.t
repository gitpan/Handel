#!perl -wT
# $Id: storage_dbic_clone.t 1379 2006-08-22 02:21:53Z claco $
use strict;
use warnings;
use lib 't/lib';
use Handel::Test;
use Scalar::Util qw/refaddr/;
use Test::More;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 10;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema(no_populate => 1)->dsn
    ]
});


## not a class method
try {
    local $ENV{'LANG'} = 'en';

    Handel::Storage::DBIC->clone;

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass;
    like(shift, qr/class method/i);
} otherwise {
    fail;
};


## clone w/ disconnected schema
my $clone = $storage->clone;
is_deeply($storage, $clone);
isnt(refaddr $storage, refaddr $clone);


## clone w/connected schema
my $schema = $storage->schema_instance;
is(refaddr $storage->_schema_instance, refaddr $schema);
my $cloned = $storage->clone;
is($cloned->_schema_instance, undef);
is(refaddr $storage->schema_instance, refaddr $schema);

$storage->_schema_instance(undef);
is_deeply($storage, $cloned);
