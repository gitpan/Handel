#!perl -wT
# $Id: storage_dbic_add_constraint.t 1385 2006-08-25 02:42:03Z claco $
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
        plan tests => 7;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema(no_populate => 1)->dsn
    ]
});


## start w/ nothing
is($storage->constraints, undef);


## add constraint to unconnected schema
my $sub = sub{};
$storage->add_constraint('id', 'Check Id', $sub);
is_deeply($storage->constraints, {'id' => {'Check Id' => $sub}});


## throw exception when connected
my $schema = $storage->schema_instance;
is_deeply($schema->class($storage->schema_source)->constraints, {'id' => {'Check Id' => $sub}});

try {
    local $ENV{'LANG'} = 'en';
    $storage->add_constraint('name', second => sub{});

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass;
    like(shift, qr/existing schema instance/);
} otherwise {
    fail;
};
