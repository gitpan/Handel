#!perl -wT
# $Id: storage_dbic_currency_format.t 1417 2006-09-16 02:19:18Z claco $
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

my $storage = Handel::Storage::DBIC->new({
    schema_class     => 'Handel::Cart::Schema',
    schema_source    => 'Items',
    currency_format  => 'FMT_NAME',
    currency_columns => [qw/price/],
    connection_info  => [
        Handel::Test->init_schema->dsn
    ]
});


my $item = $storage->search->first;
isa_ok($item->price, 'Handel::Currency');
is($item->price->_format, 'FMT_NAME');
is($item->price->format, '1.11 US Dollar');



$storage->currency_format('FMT_HTML');
$item = $storage->search->first;
isa_ok($item->price, 'Handel::Currency');
is($item->price->_format, 'FMT_HTML');
is($item->price->format, '&#x0024;1.11');


$storage->currency_format(undef);
$item = $storage->search->first;
isa_ok($item->price, 'Handel::Currency');
is($item->price->_format, undef);
is($item->price->format, '1.11 USD');


{
    local $ENV{'HandelCurrencyFormat'} = 'FMT_NAME';
    my $item = $storage->search->first;
    isa_ok($item->price, 'Handel::Currency');
    is($item->price->_format, undef);
    is($item->price->format, '1.11 US Dollar');
};


{
    my $item = $storage->search->first;
    isa_ok($item->price, 'Handel::Currency');
    is($item->price->_format, undef);
    is($item->price->format, '1.11 USD');
};
