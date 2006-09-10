#!perl -wT
# $Id: storage_copyable_item_columns.t 1409 2006-09-09 21:16:54Z claco $
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 4;

BEGIN {
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

is_deeply([sort $storage->copyable_item_columns], [qw/b c/]);
