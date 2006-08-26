#!perl -wT
# $Id: storage_dbic_currency_columns.t 1381 2006-08-24 01:27:08Z claco $
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

my $currency_columns = [qw/name/];
my $storage = Handel::Storage::DBIC->new({
    schema_class     => 'Handel::Cart::Schema',
    schema_source    => 'Carts',
    connection_info  => [Handel::Test->init_schema(no_populate => 1)->dsn],
    currency_columns => $currency_columns
});


{
    isa_ok($storage, 'Handel::Storage');

    is_deeply([$storage->currency_columns], $currency_columns);

    $storage->currency_columns(qw/description/);
    is_deeply([$storage->currency_columns], [qw/description/]);

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $cart = $schema->resultset('Carts')->create({
        id => 1,
        shopper => 2,
        name => 'test',
        description => 'Christopher Laco'
    });
    is($cart->name, 'test');
    is($cart->description, 'Christopher Laco');
    isa_ok($cart->description, 'Handel::Currency');

    ## reset it all, and try a custom currency class
    $storage->schema_instance(undef);
    is($storage->_schema_instance, undef);

    $storage->currency_class('Handel::Subclassing::Currency');
    is($storage->currency_class, 'Handel::Subclassing::Currency');
    is(Handel::Storage->currency_class, 'Handel::Currency');

    my $new_schema = $storage->schema_instance;
    isa_ok($new_schema, 'Handel::Cart::Schema');

    my $new_cart = $new_schema->resultset('Carts')->create({
        id => 2,
        shopper => 2,
        name => 'foo',
        description => 'bar'
    });
    is($new_cart->name, 'foo');
    is($new_cart->description, 'bar');
    isa_ok($new_cart->description, 'Handel::Subclassing::Currency');
};
