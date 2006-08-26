#!perl -wT
# $Id: storage_copyable_item_columns.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 4;

BEGIN {
    use_ok('Handel::Base');
    use_ok('Handel::Storage');
};

my $storage = Handel::Storage->new({
    item_class => 'Handel::Subclassing::GenericItem'
});
isa_ok($storage, 'Handel::Storage');

is_deeply([sort $storage->copyable_item_columns], [qw/b c/]);
