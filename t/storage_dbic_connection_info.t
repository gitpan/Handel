#!perl -wT
# $Id: /local/Handel/trunk/t/storage_dbic_connection_info.t 1569 2007-06-24T15:35:46.298350Z claco  $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 4;

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
    is_deeply($storage->connection_info, $connection, 'connection information was set');

    $storage->connection_info(undef);
    is($storage->connection_info, undef, 'connection info was unset');
};
