#!perl -wT
# $Id: storage_dbic_process_error.t 1381 2006-08-24 01:27:08Z claco $
use strict;
use warnings;
use lib 't/lib';
use Handel::Test;
use Test::More;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 7;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema->dsn
    ]
});


## pass an exception object right on through
try {
    local $ENV{'LANG'} = 'en';
    Handel::Storage::DBIC::process_error(Handel::Exception->new);

    fail('no exception thrown');
} catch Handel::Exception with {
    isa_ok(shift, 'Handel::Exception');
} otherwise {
    fail;
};


## catch 'is not unique' DBIC errors
try {
    local $ENV{'LANG'} = 'en';
    $storage->schema_instance->resultset($storage->schema_source)->create({
        id      => '11111111-1111-1111-1111-111111111111',
        shopper => '11111111-1111-1111-1111-111111111111'
    });

    fail('no exception thrown');
} catch Handel::Exception::Constraint with {
    pass;
    like(shift, qr/id value already exists/);
} otherwise {
    fail;
};


## catch other DBIC errors
try {
    local $ENV{'LANG'} = 'en';
    $storage->schema_instance->resultset('Foo')->create({
        id => '11111111-1111-1111-1111-111111111111'
    });

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass;
    like(shift, qr/Can't find source/);
} otherwise {
    fail;
};
