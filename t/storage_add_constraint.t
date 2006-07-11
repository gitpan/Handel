#!perl -wT
# $Id: storage_add_constraint.t 1255 2006-06-28 01:53:00Z claco $
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
    use_ok('Handel::Exception', ':try');
};


{
    ## Setup SQLite DB for tests
    my $dbfile  = "t/storage_add_constraint.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';

    unlink $dbfile;
    executesql($db, $create);

    my $constraint = sub{};

    ## create storage and add a constraint to constraints
    my $storage = Handel::Storage->new({
        schema_class    => 'Handel::Cart::Schema',
        schema_source   => 'Carts',
        connection_info => [$db],
    });
    isa_ok($storage, 'Handel::Storage');

    $storage->add_constraint('id', 'check id' => $constraint);
    is_deeply($storage->constraints, {id => {'check id' => $constraint}});

    my $new_constraint = sub{};
    $storage->add_constraint('name', 'first' => $new_constraint);

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $cart_class = $schema->class('Carts');
    is_deeply($storage->constraints, {'id' => {'check id' => $constraint}, 'name' => {first => $new_constraint}});
    is_deeply($cart_class->constraints, {'id' => {'check id' => $constraint}, 'name' => {first => $new_constraint}});

    ## throw exception when adding a constraint with an active schema instance
    {
        try {
            $storage->add_constraint('name', second => sub{});

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };
};
