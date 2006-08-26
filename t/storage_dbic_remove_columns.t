#!perl -wT
# $Id: storage_dbic_remove_columns.t 1379 2006-08-22 02:21:53Z claco $
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
        plan tests => 10;
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


## We have nothing
is($storage->_columns_to_remove, undef);


## Remove without schema instance adds to collection
$storage->remove_columns(qw/foo/);
is($storage->_schema_instance, undef);
is_deeply($storage->_columns_to_remove, [qw/foo/]);
$storage->_columns_to_remove(undef);


## Remove from a connected schema
my $schema = $storage->schema_instance;
ok($schema->source($storage->schema_source)->has_column('name'));
ok($schema->class($storage->schema_source)->can('name'));
$storage->remove_columns('name');
is_deeply($storage->_columns_to_remove, [qw/name/]);
$schema->source('Carts')->remove_columns('name');
ok(!$schema->source($storage->schema_source)->has_column('name'));
my $cart = $schema->resultset($storage->schema_source)->single({id => '11111111-1111-1111-1111-111111111111'});

## dbic doesn't remove the accessor method, but it should throw and exception
try {
    local $ENV{'LANG'} = 'en';
    $cart->name;

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass;
} otherwise {
    fail;
};
