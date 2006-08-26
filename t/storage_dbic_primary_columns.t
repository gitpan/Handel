#!perl -wT
# $Id: storage_dbic_primary_columns.t 1379 2006-08-22 02:21:53Z claco $
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
        plan tests => 11;
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


## get primary columns on unconnected schema
is($storage->_primary_columns, undef);
is_deeply([$storage->primary_columns], [qw/id/]);


## set primary columns on unconnected storage
$storage->primary_columns(qw/id shopper/);
is_deeply($storage->_primary_columns, [qw/id shopper/]);
is_deeply([$storage->primary_columns], [qw/id shopper/]);
is_deeply([$storage->schema_class->source($storage->schema_source)->primary_columns], [qw/id/]);
$storage->_primary_columns(undef);


## get/set primary columns from schema instance
my $schema = $storage->schema_instance;
is_deeply([$storage->primary_columns], [qw/id/]);
is_deeply([$schema->source($storage->schema_source)->primary_columns], [qw/id/]);
$storage->primary_columns(qw/id shopper/);
is_deeply([$storage->primary_columns], [qw/id shopper/]);
is_deeply([$schema->source($storage->schema_source)->primary_columns], [qw/id shopper/]);
