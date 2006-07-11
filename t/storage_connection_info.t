#!perl -wT
# $Id: storage_connection_info.t 1242 2006-06-27 02:22:20Z claco $
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Handel::Storage');
};


{
    my $connection = ['MyDSN', 'MyUser', 'Mypass', {}];

    my $storage = Handel::Storage->new({
        schema_class    => 'Handel::Cart::Schema',
        schema_source   => 'Carts',
        connection_info => $connection
    });
    isa_ok($storage, 'Handel::Storage');
    is_deeply($storage->connection_info, $connection);

    $storage->connection_info(undef);
    is($storage->connection_info, undef);
};
