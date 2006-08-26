#!perl -wT
# $Id: storage_add_columns.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use_ok('Handel::Storage');
};


## start with nothing
my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');
is($storage->_columns, undef);


## add a few columns
$storage->add_columns(qw/foo bar/);
$storage->add_columns(qw/baz/);
is_deeply($storage->_columns, [qw/foo bar baz/]);

$storage->add_columns;
is_deeply($storage->_columns, [qw/foo bar baz/]);
