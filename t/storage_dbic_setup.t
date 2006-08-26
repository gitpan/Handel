#!perl -wT
# $Id: storage_dbic_setup.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Test::More tests => 15;

BEGIN {
    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Order::Schema');
};

my $storage = Handel::Storage::DBIC->new;
$storage->setup({
    connection_info      => ['mydsn'],
    constraints_class    => 'Handel::Base',
    default_values_class => 'Handel::Base',
    item_relationship    => 'myitems',
    schema_class         => 'Handel::Base',
    schema_instance      => Handel::Order::Schema->connect,
    schema_source        => 'Orders',
    table_name           => 'mytable',
    validation_class     => 'Handel::Base'
});

is_deeply($storage->connection_info, ['mydsn']);
is($storage->constraints_class, 'Handel::Base');
is($storage->default_values_class, 'Handel::Base');
is($storage->item_relationship, 'myitems');
is($storage->schema_class, 'Handel::Order::Schema');
is($storage->schema_source, 'Orders');
is($storage->table_name, 'mytable');
is($storage->validation_class, 'Handel::Base');


## throw exception if no result is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->setup;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass;
    like(shift, qr/not a HASH/i);
} otherwise {
    fail;
};


## throw exception if no result is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->setup({});

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass;
    like(shift, qr/schema instance/i);
} otherwise {
    fail;
};
