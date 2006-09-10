#!perl -wT
# $Id: storage_dbic_copyable_item_columns.t 1409 2006-09-09 21:16:54Z claco $
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
        plan tests => 8;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class       => 'Handel::Cart::Schema',
    schema_source      => 'Carts',
    item_storage_class => 'Handel::Storage::DBIC::Cart::Item',
    connection_info    => [
        Handel::Test->init_schema(no_populate => 1)->dsn
    ]
});


## get copyable item columns
is_deeply([sort $storage->copyable_item_columns], [qw/description price quantity sku/]);


## add another primary and make sure it disappears
$storage->schema_instance->source('Items')->set_primary_key(qw/id sku/);
is_deeply([sort $storage->copyable_item_columns], [qw/description price quantity/]);


## no item storage
try {
    local $ENV{'LANG'} = 'en';
    $storage->item_storage_class(undef);
    $storage->item_storage(undef);
    $storage->copyable_item_columns;

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass;
    like(shift, qr/no item storage/i);
} otherwise {
    fail;
};


## no item relationship
try {
    local $ENV{'LANG'} = 'en';
    $storage->item_relationship(undef);
    $storage->copyable_item_columns;

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass;
    like(shift, qr/no item relationship/i);
} otherwise {
    fail;
};
