#!perl -wT
# $Id: storage_column_accessors.t 1385 2006-08-25 02:42:03Z claco $
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
is(scalar keys %{$storage->column_accessors}, 0);


## add columns, and get them back
$storage->_columns([qw/foo bar baz/]);
is_deeply([sort %{$storage->column_accessors}], [qw/bar bar baz baz foo foo/]);
