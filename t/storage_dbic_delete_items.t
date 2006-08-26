#!perl -wT
# $Id: storage_dbic_delete_items.t 1385 2006-08-25 02:42:03Z claco $
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
        plan tests => 17;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $testschema = Handel::Test->init_schema;
my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        $testschema->dsn
    ]
});


## delete all items from a cart
is($storage->schema_instance->resultset('Items')->search->count, 5);
my $schema = $storage->schema_instance;
my $cart = $schema->resultset($storage->schema_source)->single({id => '11111111-1111-1111-1111-111111111111'});
my $result = bless {'storage_result' => $cart}, 'GenericResult';
ok($storage->delete_items($result));
is($storage->schema_instance->resultset('Items')->search->count, 3);
Handel::Test->populate_schema($testschema, clear => 1);


## delete items using CDBI wildcard
is($storage->schema_instance->resultset('Items')->search->count, 5);
ok($storage->delete_items($result, {sku => 'SKU22%'}));
is($storage->schema_instance->resultset('Items')->search->count, 4);
Handel::Test->populate_schema($testschema, clear => 1);


## delete items using DBIC wildcard
is($storage->schema_instance->resultset('Items')->search->count, 5);
ok($storage->delete_items($result, {sku => {like => 'SKU22%'}}));
is($storage->schema_instance->resultset('Items')->search->count, 4);


## throw exception if no result is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->delete_items;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass;
    like(shift, qr/no result/i);
} otherwise {
    fail;
};


## throw exception when adding an item to something with incorrect relationship
try {
    local $ENV{'LANG'} = 'en';
    $storage->item_relationship('bogus');
    $storage->delete_items($result, {
        id       => '99999999-9999-9999-9999-999999999999',
        sku      => 'ABC-123',
        quantity => 2,
        price    => 2.22
    });

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass;
    like(shift, qr/no such relationship/i);
} otherwise {
    fail;
};


## throw exception when adding an item with no defined relationship
try {
    local $ENV{'LANG'} = 'en';
    $storage->item_relationship(undef);
    $storage->delete_items($result, {
        id       => '99999999-9999-9999-9999-999999999999',
        sku      => 'ABC-123',
        quantity => 2,
        price    => 2.22
    });

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass;
    like(shift, qr/no item relationship defined/i);
} otherwise {
    fail;
};


package GenericResult;
sub storage_result {return shift->{'storage_result'}};
1;
