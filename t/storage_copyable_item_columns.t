#!perl -wT
# $Id: storage_copyable_item_columns.t 1555 2006-11-09 01:46:20Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 4;

    use_ok('Handel::Base');
    use_ok('Handel::Storage');
};

my $storage = Handel::Storage->new({
    item_storage => Handel::Storage->new({
        add_columns     => [qw/a b c/],
        primary_columns => ['a']
    })
});
isa_ok($storage, 'Handel::Storage');

is_deeply([sort $storage->copyable_item_columns], [qw/b c/], 'got copyable item columns');
