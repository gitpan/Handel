#!perl -wT
# $Id: base_update.t 1354 2006-08-06 00:11:31Z claco $
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
    my $dbfile  = "t/base_update.db";
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

    my $it = $schema->resultset('Carts')->search({id => 1});
    $it->result_class('Handel::Storage::Result');

    my $iterator = $storage->iterator_class->create_iterator($it, 'Handel::Base');
    my $cart = $iterator->next;

    is($cart->result->id, 1);
    is($cart->result->shopper, 1);
    is($cart->result->name, 'Cart1');
    is($cart->result->description, 'My Cart 1');

    $cart->result->set_column('name', 'UpdatedName');
    is($cart->result->name, 'UpdatedName');

    my $reit = $schema->resultset('Carts')->search({id => 1});
    $reit->result_class('Handel::Storage::Result');

    my $reiter = $storage->iterator_class->create_iterator($reit, 'Handel::Base');

    my $recart = $reiter->first;
    is($recart->result->name, 'Cart1');

    $cart->update;

    my $it2 = $schema->resultset('Carts')->search({id => 1});
    $it2->result_class('Handel::Storage::Result');

    my $reit2 = $storage->iterator_class->create_iterator($it2, 'Handel::Base');


    my $recart2 = $reit2->first;
    is($recart2->result->name, 'UpdatedName');
};
