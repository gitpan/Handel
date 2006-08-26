#!perl -wT
# $Id: storage_columns.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use_ok('Handel::Storage');
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


## start w/ nothing
is($storage->_columns, undef);
is($storage->columns, 0);


## add columns, and get them back
$storage->_columns([qw/foo bar baz/]);
is_deeply([$storage->columns], [qw/foo bar baz/]);
