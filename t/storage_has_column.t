#!perl -wT
# $Id: storage_has_column.t 1555 2006-11-09 01:46:20Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 4;

    use_ok('Handel::Storage');
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');

$storage->_columns([qw/foo bar baz/]);

ok($storage->has_column('bar'), 'added bar column');
ok(!$storage->has_column('quix'), 'added quix column');
