#!perl -wT
# $Id: /local/Handel/trunk/t/storage_column_accessors.t 1569 2007-06-24T15:35:46.298350Z claco  $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 5;

    use_ok('Handel::Storage');
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


## start w/ nothing
is($storage->_columns, undef, 'no columns set');
is(scalar keys %{$storage->column_accessors}, 0, 'no columns set');


## add columns, and get them back
$storage->_columns([qw/foo bar baz/]);
is_deeply([sort %{$storage->column_accessors}], [qw/bar bar baz baz foo foo/], 'added column');
