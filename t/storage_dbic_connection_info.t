#!perl -wT
# $Id: storage_dbic_connection_info.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Handel::Storage::DBIC');
};


{
    my $connection = ['MyDSN', 'MyUser', 'Mypass', {}];

    my $storage = Handel::Storage::DBIC->new({
        schema_class    => 'Handel::Cart::Schema',
        schema_source   => 'Carts',
        connection_info => $connection
    });
    isa_ok($storage, 'Handel::Storage');
    is_deeply($storage->connection_info, $connection);

    $storage->connection_info(undef);
    is($storage->connection_info, undef);
};
