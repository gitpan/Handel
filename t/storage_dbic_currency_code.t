#!perl -wT
# $Id: storage_dbic_currency_code.t 1417 2006-09-16 02:19:18Z claco $
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
        plan tests => 16;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class     => 'Handel::Cart::Schema',
    schema_source    => 'Items',
    currency_code    => 'CAD',
    currency_columns => [qw/price/],
    connection_info  => [
        Handel::Test->init_schema->dsn
    ]
});


my $item = $storage->search->first;
isa_ok($item->price, 'Handel::Currency');
is($item->price->code, 'CAD');
is($item->price->format, '1.11 CAD');

$storage->currency_code('DKK');
$item = $storage->search->first;
isa_ok($item->price, 'Handel::Currency');
is($item->price->code, 'DKK');
is($item->price->format, '1,11 DKK');


$storage->currency_code(undef);
$item = $storage->search->first;
isa_ok($item->price, 'Handel::Currency');
is($item->price->code, undef);


{
    local $ENV{'HandelCurrencyCode'} = 'CAD';
    my $item = $storage->search->first;
    isa_ok($item->price, 'Handel::Currency');
    is($item->price->code, undef);
    is($item->price->format, '1.11 CAD');
};


{
    my $item = $storage->search->first;
    isa_ok($item->price, 'Handel::Currency');
    is($item->price->code, undef);
    is($item->price->format, '1.11 USD');
};
