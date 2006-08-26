#!perl -wT
# $Id: storage_dbic_search.t 1381 2006-08-24 01:27:08Z claco $
use strict;
use warnings;
use lib 't/lib';
use Handel::Test;
use Test::More;
use Scalar::Util qw/refaddr/;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 33;
    };

    use_ok('Handel::Storage::DBIC');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage::DBIC->new({
    schema_class    => 'Handel::Cart::Schema',
    schema_source   => 'Carts',
    connection_info => [
        Handel::Test->init_schema->dsn
    ]
});


## get all results in list
{
    my @results = $storage->search;
    is(@results, 3);
    foreach my $result (@results) {
        isa_ok($result, $storage->result_class);
        is(refaddr $result->storage, refaddr $storage);
        like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/);
    };
};


## get all results as an iterator
{
    my $results = $storage->search;
    is($results->count, 3);
    isa_ok($results, $storage->iterator_class);
    while (my $result = $results->next) {
        isa_ok($result, $storage->result_class);
        is(refaddr $result->storage, refaddr $storage);
        like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/);
    };
};


## filter results using CDBI wildcards
{
    my $carts = $storage->search({ id => '1111%'});
    is($carts->count, 1);
    my $result = $carts->first;
    isa_ok($result, $storage->result_class);
    is(refaddr $result->storage, refaddr $storage);
    like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/);
    is($result->id, '11111111-1111-1111-1111-111111111111');
};


## filter results using DBIC wildcards
{
    my $carts = $storage->search({ id => {like => '1111%'}});
    is($carts->count, 1);
    my $result = $carts->first;
    isa_ok($result, $storage->result_class);
    is(refaddr $result->storage, refaddr $storage);
    like(ref $result->storage_result, qr/Handel::Storage::DBIC::[A-F0-9]{32}::Carts/);
    is($result->id, '11111111-1111-1111-1111-111111111111');
};
