#!perl -wT
# $Id: storage_remove_columns.t 1217 2006-06-22 03:01:03Z claco $
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 8;
    };

    use_ok('Handel::Storage');
};


{
    ## Setup SQLite DB for tests
    my $dbfile  = "t/storage_remove_columns.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';

    unlink $dbfile;
    executesql($db, $create);

    my $storage = Handel::Storage->new({
        schema_class    => 'Handel::Cart::Schema',
        schema_source   => 'Carts',
        connection_info => [$db]
    });
    isa_ok($storage, 'Handel::Storage');

    ## remove columns before the schema_instance is created
    $storage->remove_columns(qw/name/);

    my %remove_columns = map {$_ => 1} @{$storage->_columns_to_remove};
    ok(exists $remove_columns{'name'}, 'column name not removed');

    my %class_columns = map {$_ => 1} $storage->schema_class->class('Carts')->columns;
    ok(exists $class_columns{'name'}, 'column name is missing in source class');


    ## remove columns from the schema_instance
    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $source = $schema->source('Carts');
    my %source_columns = map {$_ => 1} $source->columns;
    ok(!exists $source_columns{'name'}, 'column name not removed');

    $storage->remove_columns('description');
    my %new_source_columns = map {$_ => 1} $source->columns;
    ok(!exists $new_source_columns{'description'}, 'column description not removed');

    my %columns_to_remove = map {$_ => 1} @{$storage->_columns_to_remove};
    ok(exists $columns_to_remove{'description'}, 'column descrtiption not in _columns_to_remove');
};
