#!perl -wT
# $Id: storage_column_accessors.t 1279 2006-07-03 16:46:27Z claco $
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
        plan tests => 73;
    };

    use_ok('Handel::Storage');
};


## Setup SQLite DB for tests
my $dbfile  = "t/storage_column_accessors.db";
my $db      = "dbi:SQLite:dbname=$dbfile";
my $create  = 't/sql/cart_create_table.sql';

unlink $dbfile;
executesql($db, $create);


## check the normal columns
{
    my $storage = Handel::Storage->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts'
    });

    my $accessors = $storage->column_accessors;

    is(scalar keys %{$accessors}, 5);
    foreach (qw/id shopper type name description/) {
        ok(exists $accessors->{$_});
        is($accessors->{$_}, $_);
    };
};


## try adding columns before schema instance
{
    my $storage = Handel::Storage->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts',
        add_columns        => [qw/foo/]
    });

    my $accessors = $storage->column_accessors;

    is(scalar keys %{$accessors}, 6);
    foreach (qw/id shopper type name description foo/) {
        ok(exists $accessors->{$_});
        is($accessors->{$_}, $_);
    };
};


## try removing columns before schema instance
{
    my $storage = Handel::Storage->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts',
        remove_columns     => [qw/description/]
    });

    my $accessors = $storage->column_accessors;

    is(scalar keys %{$accessors}, 4);
    foreach (qw/id shopper type name/) {
        ok(exists $accessors->{$_});
        is($accessors->{$_}, $_);
    };
};


## try with an accessr in the schema itself before schema instance
{
    my $storage = Handel::Storage->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts'
    });

    $storage->schema_class->source('Carts')->add_column(foo => {accessor => 'bar'});

    my $accessors = $storage->column_accessors;

    is(scalar keys %{$accessors}, 6);
    foreach (qw/id shopper type name description/) {
        ok(exists $accessors->{$_});
        is($accessors->{$_}, $_);
    };
    ok(exists $accessors->{'foo'});
    is($accessors->{'foo'}, 'bar');
    
    $storage->schema_class->source('Carts')->remove_column('foo');
};


## try with an accessr in add_columns before schema instance
{
    my $storage = Handel::Storage->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts',
        add_columns        => [bar => {accessor => 'baz'}]
    });

    my $accessors = $storage->column_accessors;

    is(scalar keys %{$accessors}, 6);
    foreach (qw/id shopper type name description/) {
        ok(exists $accessors->{$_});
        is($accessors->{$_}, $_);
    };
    ok(exists $accessors->{'bar'});
    is($accessors->{'bar'}, 'baz');
};



## try with an accessr in add_columns after schema instance
{
    my $storage = Handel::Storage->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts',
        connection_info    => [$db]
    });

    my $schema = $storage->schema_instance;
    $storage->add_columns(bar => {accessor => 'baz', data_type => 'int'});
    my $accessors = $storage->column_accessors;

    is(scalar keys %{$accessors}, 6);
    foreach (qw/id shopper type name description/) {
        ok(exists $accessors->{$_});
        is($accessors->{$_}, $_);
    };
    ok(exists $accessors->{'bar'});
    is($accessors->{'bar'}, 'baz');
};
