#!perl -wT
# $Id: storage_dbic_add_item.t 1385 2006-08-25 02:42:03Z claco $
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
        plan tests => 15;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema->dsn
    ]
});


## add item to cart
my $schema = $storage->schema_instance;
my $cart = $schema->resultset($storage->schema_source)->single({id => '11111111-1111-1111-1111-111111111111'});
my $result = bless {'storage_result' => $cart}, 'GenericResult';

my $item = $storage->add_item($result, {
    id       => '99999999-9999-9999-9999-999999999999',
    sku      => 'ABC-123',
    quantity => 2,
    price    => 2.22
});
isa_ok($item, $storage->result_class);
is($item->id, '99999999-9999-9999-9999-999999999999');
is($item->sku, 'ABC-123');
is($item->quantity, 2);
is($item->price, 2.22);


## throw exception if no result is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->add_item;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass;
    like(shift, qr/no result/i);
} otherwise {
    fail;
};


## throw exception if no hash ref is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->add_item($result);

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass;
    like(shift, qr/not a HASH/);
} otherwise {
    fail;
};


## throw exception when adding an item to something with incorrect relationship
try {
    local $ENV{'LANG'} = 'en';
    $storage->add_item($item, {
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
    $storage->add_item($item, {
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
