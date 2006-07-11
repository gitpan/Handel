#!perl -wT
# $Id: base_inflate_result.t 1272 2006-07-02 00:55:04Z claco $
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
        plan tests => 10;
    };

    use_ok('Handel::Storage');
    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


{
    ## Setup SQLite DB for tests
    my $dbfile  = "t/base_inflate_result.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';

    unlink $dbfile;
    executesql($db, $create);

    my $storage = Handel::Storage->new({
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts',
        connection_info    => [$db]
    });

    my $schema = $storage->schema_instance;

    $schema->resultset('Carts')->create({
        id => 1,
        shopper => 1,
        name => 'Cart1',
        description => 'My Cart 1'
    });

    my $iterator = $schema->resultset('Carts')->search({id => 1});
    $iterator->result_class('Handel::Base');
    
    isa_ok($iterator, 'Handel::Iterator');
    my $cart = $iterator->next;

    isa_ok($cart, 'Handel::Base');
    like(ref $cart->result, qr/Handel::Storage::[a-f0-9]{32}::Carts/i);

    is($cart->result->id, 1);
    is($cart->result->shopper, 1);
    is($cart->result->name, 'Cart1');
    is($cart->result->description, 'My Cart 1');
};
