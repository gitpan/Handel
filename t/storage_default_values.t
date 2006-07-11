#!perl -wT
# $Id: storage_default_values.t 1273 2006-07-02 00:55:55Z claco $
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
        plan tests => 16;
    };

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    ## Setup SQLite DB for tests
    my $dbfile  = "t/storage_default_values.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';

    unlink $dbfile;
    executesql($db, $create);

    my $default_values = {
        name        => 'My Default Name',
        description => sub{'My Default Description'}
    };

    my $storage = Handel::Storage->new({
        schema_class    => 'Handel::Cart::Schema',
        schema_source   => 'Carts',
        connection_info => [$db],
        default_values  => $default_values
    });
    isa_ok($storage, 'Handel::Storage');

    is_deeply($storage->default_values, $default_values);

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $class = $schema->class('Carts');
    ok($class->isa('Handel::Components::DefaultValues'));

    is_deeply($class->default_values, $default_values);

    my $cart = $schema->resultset('Carts')->create({id => 1});
    is($cart->name, 'My Default Name');
    is($cart->description, 'My Default Description');

    ## throw exception when setting a default_values with open schema_instance
    {
        try {
            $storage->default_values({
                field => 'foo'
            });

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };

    ## throw exception when setting a bogus defaults class
    {
        try {
            $storage->default_values_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };

    ## reset it all, and try a custom default values class
    $storage->schema_instance(undef);
    is($storage->_schema_instance, undef);

    $storage->default_values_class('Handel::TestComponents::DefaultValues');
    is($storage->default_values_class, 'Handel::TestComponents::DefaultValues');

    my $new_schema = $storage->schema_instance;
    isa_ok($new_schema, 'Handel::Cart::Schema');
    ok($new_schema->class('Carts')->isa('Handel::TestComponents::DefaultValues'));
    ok(!$schema->class('Carts')->isa('Handel::TestComponents::DefaultValues'));
};
