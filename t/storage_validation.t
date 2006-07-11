#!perl -wT
# $Id: storage_validation.t 1297 2006-07-07 22:37:05Z claco $
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    };
    eval 'require FormValidator::Simple';
    if ($@) {
        plan skip_all => 'FormValidator::Simple not installed';
    } else {
        plan tests => 18;
    };

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    ## Setup SQLite DB for tests
    my $dbfile  = "t/storage_validation.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';

    unlink $dbfile;
    executesql($db, $create);

    my $validation = [
        name => ['NOT_BLANK'],
        description => ['NOT_BLANK', ['LENGTH', 2, 4]]
    ];

    my $storage = Handel::Storage->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts',
        connection_info    => [$db],
        validation_profile => $validation
    });
    isa_ok($storage, 'Handel::Storage');

    is_deeply($storage->validation_profile, $validation);

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $class = $schema->class('Carts');
    ok($class->isa('Handel::Components::Validation'));

    is_deeply($class->validation_profile, $validation);


    ## throw exception when validation fails
    my $cart;
    {
        try {
            $cart = $schema->resultset('Carts')->create({
                id => 1,
                name => 'test'
            });

            fail('no exception thrown');
        } catch Handel::Exception::Validation with {
            isa_ok(shift->results, 'FormValidator::Simple::Results');
        } otherwise {
            fail;
        };
    };

    is($cart, undef);


    ## throw exception when setting a validation with open schema_instance
    {
        try {
            $storage->validation_profile([
                field => {'do_field' => sub{}}
            ]);

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };

    ## throw exception when setting a bogus validation class
    {
        try {
            $storage->validation_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };

    ## reset it all, and try a custom validation class
    $storage->schema_instance(undef);
    is($storage->_schema_instance, undef);

    $storage->validation_class('Handel::TestComponents::Validation');
    is($storage->validation_class, 'Handel::TestComponents::Validation');

    my $new_schema = $storage->schema_instance;
    isa_ok($new_schema, 'Handel::Cart::Schema');
    ok($new_schema->class('Carts')->isa('Handel::TestComponents::Validation'));
    ok(!$schema->class('Carts')->isa('Handel::TestComponents::Validation'));
    
    is($storage->validation_module, 'FormValidator::Simple');

    ## throw exception when setting a bogus validation class
    {
        try {
            $storage->validation_module('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };
};
