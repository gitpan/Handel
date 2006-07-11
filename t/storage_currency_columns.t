#!perl -wT
# $Id: storage_currency_columns.t 1255 2006-06-28 01:53:00Z claco $
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 16;
    };

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    ## Setup SQLite DB for tests
    my $dbfile  = "t/storage_currency_columns.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';

    unlink $dbfile;
    executesql($db, $create);

    my $currency_columns = [qw/name/];

    my $storage = Handel::Storage->new({
        schema_class     => 'Handel::Cart::Schema',
        schema_source    => 'Carts',
        connection_info  => [$db],
        currency_columns => $currency_columns
    });
    isa_ok($storage, 'Handel::Storage');

    is_deeply($storage->currency_columns, $currency_columns);

    $storage->currency_columns([qw/description/]);
    is_deeply($storage->currency_columns, [qw/description/]);

    my $schema = $storage->schema_instance;
    isa_ok($schema, 'Handel::Cart::Schema');

    my $cart = $schema->resultset('Carts')->create({
        id => 1,
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
        name => 'foo',
        description => 'bar'
    });
    is($new_cart->name, 'foo');
    is($new_cart->description, 'bar');
    isa_ok($new_cart->description, 'Handel::Subclassing::Currency');
};
