#!perl -wT
# $Id: storage_remove_constraints.t 1255 2006-06-28 01:53:00Z claco $
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
        plan tests => 9;
    };

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    ## Setup SQLite DB for tests
    my $dbfile  = "t/storage_remove_constraints.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';

    unlink $dbfile;
    executesql($db, $create);

    my $sub = sub{};
    my $constraints = {
        'id' => {'check id' => $sub},
        'name' => {'check name' => $sub},
        'name' => {'check type' => $sub}
    };

    ## create storage and add constrainta
    my $storage = Handel::Storage->new({
        schema_class    => 'Handel::Cart::Schema',
        schema_source   => 'Carts',
        connection_info => [$db],
        constraints     => $constraints
    });
    isa_ok($storage, 'Handel::Storage');

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $cart_class = $schema->class('Carts');
    is_deeply($storage->constraints, $constraints);
    is_deeply($cart_class->constraints, $constraints);

    ## throw exception when removing a constraint with an active schema instance
    {
        try {
            $storage->remove_constraints('name');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };

    $storage->_schema_instance(undef);
    is_deeply($storage->constraints, $constraints);

    $storage->remove_constraints('name');
    is_deeply($storage->constraints, {'id' => {'check id' => $sub}});
};
