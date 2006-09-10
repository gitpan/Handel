#!perl -wT
# $Id: storage_has_column.t 1413 2006-09-10 18:34:58Z claco $
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Handel::Storage');
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');

$storage->_columns([qw/foo bar baz/]);

ok($storage->has_column('bar'));
ok(!$storage->has_column('quix'));
