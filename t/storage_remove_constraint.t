#!perl -wT
# $Id: storage_remove_constraint.t 1247 2006-06-27 18:52:15Z claco $
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
    use_ok('Handel::Exception', ':try');
};


{
    ## Setup SQLite DB for tests
    my $dbfile  = "t/storage_remove_constraint.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';

    unlink $dbfile;
    executesql($db, $create);

    ## create storage and add constraint
    my $storage = Handel::Storage->new({
        schema_class    => 'Handel::Cart::Schema',
        schema_source   => 'Carts',
        connection_info => [$db],
    });
    isa_ok($storage, 'Handel::Storage');

    my $constraint = sub{};
    $storage->add_constraint('id', 'check id' => $constraint);
    $storage->add_constraint('name', 'check name' => $constraint);

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $cart_class = $schema->class('Carts');
    is_deeply($storage->constraints, {'id' => {'check id' => $constraint}, 'name' => {'check name' => $constraint}});
    is_deeply($cart_class->constraints, {'id' => {'check id' => $constraint}, 'name' => {'check name' => $constraint}});

    ## throw exception when adding a constraint with an active schema instance
    {
        try {
            $storage->add_constraint('name', 'second' => sub{});

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };

    $storage->_schema_instance(undef);
    is_deeply($storage->constraints, {'id' => {'check id' => $constraint}, 'name' => {'check name' => $constraint}});

    $storage->remove_constraint('name', 'check name');
    is_deeply($storage->constraints, {'id' => {'check id' => $constraint}});

    $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    $cart_class = $schema->class('Carts');
    is_deeply($cart_class->constraints, {'id' => {'check id' => $constraint}});
};
