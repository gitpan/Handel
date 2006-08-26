#!perl -wT
# $Id: storage_dbic_add_columns.t 1379 2006-08-22 02:21:53Z claco $
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
        plan tests => 20;
    };

    use_ok('Handel::Storage::DBIC');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema->dsn
    ]
});


## We have nothing
is($storage->_columns_to_add, undef);


## Add generic without schema instance adds to collection
$storage->add_columns(qw/foo/);
is($storage->_schema_instance, undef);
is_deeply($storage->_columns_to_add, [qw/foo/]);
$storage->_columns_to_add(undef);


## Add w/info without schema instance
$storage->add_columns(bar => {accessor => 'baz'});
is($storage->_schema_instance, undef);
is_deeply($storage->_columns_to_add, [bar => {accessor => 'baz'}]);
$storage->_columns_to_add(undef);


## Add to a connected schema
my $schema = $storage->schema_instance;
ok(!$schema->source($storage->schema_source)->has_column('custom'));
ok(!$schema->class($storage->schema_source)->can('custom'));
$storage->add_columns('custom');
is_deeply($storage->_columns_to_add, [qw/custom/]);
ok($schema->source($storage->schema_source)->has_column('custom'));
ok($schema->class($storage->schema_source)->can('custom'));
$storage->_columns_to_add(undef);
my $cart = $schema->resultset($storage->schema_source)->single({id => '11111111-1111-1111-1111-111111111111'});
ok($cart->can('custom'));
is($cart->custom, 'custom');
$schema->source($storage->schema_source)->remove_columns('custom');


## Add w/info to a connected schema
ok(!$schema->source($storage->schema_source)->has_column('custom'));
ok(!$schema->class($storage->schema_source)->can('baz'));
$storage->add_columns(custom => {accessor => 'baz'});
is_deeply($storage->_columns_to_add, [custom => {accessor => 'baz'}]);
ok($schema->source($storage->schema_source)->has_column('custom'));
ok($schema->class($storage->schema_source)->can('baz'));
$cart = $schema->resultset($storage->schema_source)->single({id => '11111111-1111-1111-1111-111111111111'});
ok($cart->can('baz'));
is($cart->baz, 'custom');
