#!perl -wT
# $Id: storage_dbic_column_accessors.t 1379 2006-08-22 02:21:53Z claco $
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
        plan tests => 48;
    };

    use_ok('Handel::Storage::DBIC');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema(no_populate => 1)->dsn
    ]
});


## return column accessors for unconnect schema as-is
my $accessors = $storage->column_accessors;
is(scalar keys %{$accessors}, 5);
ok(exists $accessors->{'id'});
ok(exists $accessors->{'shopper'});
ok(exists $accessors->{'type'});
ok(exists $accessors->{'name'});
ok(exists $accessors->{'description'});
is($accessors->{'id'}, 'id');
is($accessors->{'shopper'}, 'shopper');
is($accessors->{'type'}, 'type');
is($accessors->{'name'}, 'name');
is($accessors->{'description'}, 'description');


## add a normal column, %col_info, and remove column to unconnected schema
$storage->_columns_to_add(['foo', 'bar' => {accessor => 'baz'}]);
$storage->_columns_to_remove(['name']);
$accessors = $storage->column_accessors;
is(scalar keys %{$accessors}, 6);
ok(exists $accessors->{'id'});
ok(exists $accessors->{'shopper'});
ok(exists $accessors->{'type'});
ok(!exists $accessors->{'name'});
ok(exists $accessors->{'description'});
ok(exists $accessors->{'foo'});
ok(exists $accessors->{'bar'});
is($accessors->{'id'}, 'id');
is($accessors->{'shopper'}, 'shopper');
is($accessors->{'type'}, 'type');
is($accessors->{'description'}, 'description');
is($accessors->{'foo'}, 'foo');
is($accessors->{'bar'}, 'baz');
$storage->_columns_to_add(undef);
$storage->_columns_to_remove(undef);


## get normal columns from connected schema
my $schema = $storage->schema_instance;
$accessors = $storage->column_accessors;
is(scalar keys %{$accessors}, 5);
ok(exists $accessors->{'id'});
ok(exists $accessors->{'shopper'});
ok(exists $accessors->{'type'});
ok(exists $accessors->{'name'});
ok(exists $accessors->{'description'});
is($accessors->{'id'}, 'id');
is($accessors->{'shopper'}, 'shopper');
is($accessors->{'type'}, 'type');
is($accessors->{'description'}, 'description');


## get normal columns from connected schema w/accessor
$schema->source($storage->schema_source)->add_columns('custom' => {accessor => 'baz'});
$accessors = $storage->column_accessors;
is(scalar keys %{$accessors}, 6);
ok(exists $accessors->{'id'});
ok(exists $accessors->{'shopper'});
ok(exists $accessors->{'type'});
ok(exists $accessors->{'name'});
ok(exists $accessors->{'description'});
ok(exists $accessors->{'custom'});
is($accessors->{'id'}, 'id');
is($accessors->{'shopper'}, 'shopper');
is($accessors->{'type'}, 'type');
is($accessors->{'description'}, 'description');
is($accessors->{'custom'}, 'baz');
