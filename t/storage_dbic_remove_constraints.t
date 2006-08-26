#!perl -wT
# $Id: storage_dbic_remove_constraints.t 1385 2006-08-25 02:42:03Z claco $
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
        plan tests => 8;
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


## start w/ nothing
is($storage->constraints, undef);

my $sub = {};
$storage->constraints({
    id => {
        'Check Id' => $sub,
        'Check It Again' => $sub
    },
    name => {
        'Check Name' => $sub,
        'Check Name Again' => $sub
    }
});


## remove constraint from unconnected schema
$storage->remove_constraints('name');
is_deeply($storage->constraints, {'id' => {'Check Id' => $sub, 'Check It Again' => $sub}});


## throw exception when no column is specified
try {
    local $ENV{'LANG'} = 'en';
    $storage->remove_constraints;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass;
    like(shift, qr/no column/i);
} otherwise {
    fail;
};

## throw exception when connected
my $schema = $storage->schema_instance;

try {
    local $ENV{'LANG'} = 'en';
    $storage->remove_constraints('name');

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass;
    like(shift, qr/existing schema instance/);
} otherwise {
    fail;
};
