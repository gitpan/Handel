#!perl -wT
# $Id: storage_dbic_delete.t 1380 2006-08-23 01:57:36Z claco $
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
        plan tests => 17;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $schema = Handel::Test->init_schema;
my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        $schema->dsn
    ]
});


## delete all items w/ no params
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 3);
is($storage->schema_instance->resultset('Items')->search->count, 5);
ok($storage->delete);
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 0);
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 0);


## delete all items w/ CDBI wildcards
Handel::Test->populate_schema($schema, clear => 1);
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 3);
is($storage->schema_instance->resultset('Items')->search->count, 5);
ok($storage->delete({ description => 'Test%'}));
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 1);
is($storage->schema_instance->resultset('Items')->search->count, 2);


## delete all items w/ DBIC wildcards
Handel::Test->populate_schema($schema, clear => 1);
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 3);
is($storage->schema_instance->resultset('Items')->search->count, 5);
ok($storage->delete({ description => {like => 'Test%'}}));
is($storage->schema_instance->resultset($storage->schema_source)->search->count, 1);
is($storage->schema_instance->resultset('Items')->search->count, 2);
