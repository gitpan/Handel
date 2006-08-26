#!perl -wT
# $Id: storage_remove_columns.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok('Handel::Storage');
};


## start with nothing
my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');
is($storage->_columns, undef);
is($storage->_primary_columns, undef);


$storage->_columns([qw/foo bar baz/]);
$storage->_primary_columns([qw/foo bar/]);
$storage->_currency_columns([qw/baz bar/]);

## remove a few columns
$storage->remove_columns(qw/foo baz/);
is_deeply($storage->_columns, [qw/bar/]);
is_deeply($storage->_primary_columns, [qw/bar/]);
is_deeply($storage->_currency_columns, [qw/bar/]);
