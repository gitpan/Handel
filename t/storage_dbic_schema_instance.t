#!perl -wT
# $Id: storage_dbic_schema_instance.t 1381 2006-08-24 01:27:08Z claco $
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::Test;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 41;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $dsn = Handel::Test->init_schema(no_populate => 1)->dsn;
my $constraints = {
    id   => {'check_id' => sub{}},
    name => {'check_name' => sub{}}
};

my $storage = Handel::Storage::DBIC->new({
    cart_class         => 'Handel::Cart',
    schema_class       => 'Handel::Cart::Schema',
    schema_source      => 'Carts',
    default_values     => {id => 1, name => 'New Cart'},
    validation_profile => {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]},
    add_columns        => [qw/custom/],
    remove_columns     => [qw/description/],
    constraints        => $constraints,
    currency_columns   => [qw/name/],
    connection_info => [
        $dsn
    ]
});


{
    ## create a new storage and check schema_instance configuration
    isa_ok($storage, 'Handel::Storage');

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $cart_class = $schema->class('Carts');
    my $item_class = $schema->class('Items');
    my $cart_source = $schema->source('Carts');
    my $item_source = $schema->source('Items');

    ## make sure we're running clones unique classes
    like($cart_class, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/);
    like($item_class, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Items/);

    ## make sure we loaded the validation profile Component and values
    ok($cart_class->isa('Handel::Components::Validation'));
    is_deeply($cart_class->validation_profile, {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]});
    ok(!$item_class->isa('Handel::Components::Validation'));

    ## make sure we loaded the default values Component and values
    ok($cart_class->isa('Handel::Components::DefaultValues'));
    is_deeply($cart_class->default_values, {id => 1, name => 'New Cart'});
    ok(!$item_class->isa('Handel::Components::DefaultValues'));

    ## make sure we loaded the constraints Component and values
    ok($cart_class->isa('Handel::Components::Constraints'));
    is_deeply($cart_class->constraints, $constraints);
    ok(!$item_class->isa('Handel::Components::Constraints'));

    ## make sure we added/removed columns
    my %columns = map {$_ => 1} $cart_source->columns;
    ok(exists $columns{'custom'}, 'column custom not added');
    ok(!exists $columns{'description'}, 'column description not removed');

    ## make sure we set inflate/deflate
    ok($cart_class->column_info('name')->{'_inflate_info'}->{'inflate'});
    ok($cart_class->column_info('name')->{'_inflate_info'}->{'deflate'});

    ## pass in a schema_instance and recheck schema configuration
    my $new_schema = Handel::Cart::Schema->connect($dsn);
    isa_ok($new_schema, 'Handel::Cart::Schema');

    $storage->schema_instance($new_schema);

    $new_schema = $storage->schema_instance;

    my $new_cart_class = $new_schema->class('Carts');
    my $new_item_class = $new_schema->class('Items');
    my $new_cart_source = $new_schema->source('Carts');
    my $new_item_source = $new_schema->source('Items');

    ## make sure we're not the first schema in disguise
    isnt($cart_class, $new_cart_class);
    isnt($item_class, $new_item_class);

    ## make sure we're running clones unique classes
    like($new_cart_class, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/);
    like($new_item_class, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Items/);

    ## make sure we loaded the validation profile Component and values
    ok($new_cart_class->isa('Handel::Components::Validation'));
    is_deeply($new_cart_class->validation_profile, {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]});
    ok(!$new_item_class->isa('Handel::Components::Validation'));

    ## make sure we loaded the default values Component and values
    ok($new_cart_class->isa('Handel::Components::DefaultValues'));
    is_deeply($new_cart_class->default_values, {id => 1, name => 'New Cart'});
    ok(!$new_item_class->isa('Handel::Components::DefaultValues'));

    ## make sure we loaded the constraints Component and values
    ok($new_cart_class->isa('Handel::Components::Constraints'));
    is_deeply($new_cart_class->constraints, $constraints);
    ok(!$new_item_class->isa('Handel::Components::Constraints'));

    ## make sure we added/removed columns
    my %new_columns = map {$_ => 1} $new_cart_source->columns;
    ok(exists $new_columns{'custom'}, 'column custom not added');
    ok(!exists $new_columns{'description'}, 'column description not removed');

    ## throw exception if schema_class is empty
    {
        try {
            my $storage = Handel::Storage::DBIC->new({
                schema_source   => 'Carts',
                connection_info => [$dsn]
            });
            $storage->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
            like(shift, qr/no schema_class/i)
        } otherwise {
            fail;
        };
    };

    ## throw exception if schema_source is empty
    {
        try {
            my $storage = Handel::Storage::DBIC->new({
                schema_class    => 'Handel::Cart::Schema',
                connection_info => [$dsn]
            });
            $storage->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
            like(shift, qr/no schema_source/i)
        } otherwise {
            fail;
        };
    };

    ## throw exception if item_relationship is missing
    {
        try {
            my $storage = Handel::Storage::DBIC->new({
                schema_class      => 'Handel::Cart::Schema',
                schema_source     => 'Carts',
                item_class        => 'Handel::Cart::Item',
                item_relationship => 'foo',
                connection_info   => [$dsn]
            });
            $storage->schema_instance;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
            like(shift, qr/no relationship named/i)
        } otherwise {
            fail;
        };
    };
};
