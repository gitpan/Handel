#!perl -wT
# $Id: storage_dbic_constraints.t 1381 2006-08-24 01:27:08Z claco $
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
        plan tests => 25;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $constraints = {
    'name'        => {'check_name' => \&check_name},
    'description' => {'check_description' => \&check_description}
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    constraints     => $constraints,
    connection_info => [
        Handel::Test->init_schema(no_populate => 1)->dsn
    ]
});


{
    isa_ok($storage, 'Handel::Storage');

    is_deeply($storage->constraints, $constraints);

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $class = $schema->class('Carts');
    ok($class->isa('Handel::Components::Constraints'));

    is_deeply($class->constraints, $constraints);

    my $cart = $schema->resultset('Carts')->create({
        id => 1,
        shopper => 2,
        name => 'test',
        description => 'Christopher Laco'
    });
    is($cart->name, 'test');
    is($cart->description, 'ChristopherLaco');

    ## throw exception when setting a constraints with open schema_instance
    {
        try {
            $storage->constraints({
                field => {'do_field' => sub{}}
            });

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## throw exception when setting a bogus constraint class
    {
        try {
            $storage->constraints_class('Funklebean');

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };

    ## reset it all, and try a custom constraints class
    $storage->schema_instance(undef);
    is($storage->_schema_instance, undef);

    $storage->constraints_class('Handel::TestComponents::Constraints');
    is($storage->constraints_class, 'Handel::TestComponents::Constraints');

    my $new_schema = $storage->schema_instance;
    isa_ok($new_schema, 'Handel::Cart::Schema');
    ok($new_schema->class('Carts')->isa('Handel::TestComponents::Constraints'));
    ok(!$schema->class('Carts')->isa('Handel::TestComponents::Constraints'));
};

sub check_name {
    my $value = defined $_[0] ? shift : '';
    my ($object, $column, $changing) = @_;

    ok($value);
    isa_ok($object, 'DBIx::Class::ResultSource::Table');
    is($column, 'name');
    isa_ok($changing, 'HASH');

    like($value, qr/^(.*){2,3}$/);
};

sub check_description {
    my $value = defined $_[0] ? shift : '';
    my ($object, $column, $changing) = @_;

    ok($value);
    isa_ok($object, 'DBIx::Class::ResultSource::Table');
    is($column, 'description');
    isa_ok($changing, 'HASH');

    $value =~ s/\s+//g;
    $changing->{$column} = $value;

    return 1;
};
