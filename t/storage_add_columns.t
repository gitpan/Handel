#!perl -wT
# $Id: storage_add_columns.t 1217 2006-06-22 03:01:03Z claco $
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
        plan tests => 11;
    };

    use_ok('Handel::Storage');
};


{
    ## Setup SQLite DB for tests
    my $dbfile  = "t/storage_add_columns.db";
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

    ## add columns before the schema_instance is created
    $storage->add_columns(qw/one two/);

    my %add_columns = map {$_ => 1} @{$storage->_columns_to_add};
    ok(exists $add_columns{'one'}, 'column one not added');
    ok(exists $add_columns{'two'}, 'column two not added');

    my %class_columns = map {$_ => 1} $storage->schema_class->class('Carts')->columns;
    ok(!exists $class_columns{'one'}, 'column one exists in source class');
    ok(!exists $class_columns{'two'}, 'column two exists in source class');


    ## add columns to the schema_instance
    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $source = $schema->source('Carts');
    my %source_columns = map {$_ => 1} $source->columns;
    ok(exists $source_columns{'one'}, 'column one not added');
    ok(exists $source_columns{'two'}, 'column two not added');

    $storage->add_columns('three');
    my %new_source_columns = map {$_ => 1} $source->columns;
    ok(exists $new_source_columns{'three'}, 'column three not added');

    my %columns_to_add = map {$_ => 1} @{$storage->_columns_to_add};
    ok(exists $columns_to_add{'three'}, 'column three not in _columns_to_add');
};
