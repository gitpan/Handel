#!perl -wT
# $Id: storage_dbic_process_error.t 1560 2006-11-10 02:36:54Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 8;
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
    my $e = shift;
    isa_ok($e, 'Handel::Exception');
    like($e, qr/unspecified error/i, 'unspecified in message');
} otherwise {
    fail('other exception caught');
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
    pass('caught constraint exception');
    like(shift, qr/id value already exists/i, 'value exists in message');
} otherwise {
    fail('other exception caught');
};


## catch other DBIC errors
try {
    local $ENV{'LANG'} = 'en';
    $storage->schema_instance->resultset('Foo')->create({
        id => '11111111-1111-1111-1111-111111111111'
    });

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('caught storage exception');
    like(shift, qr/can't find source/i, 'source in massage');
} otherwise {
    fail('other exception caught');
};
