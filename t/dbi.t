#!perl -wT
# $Id: dbi.t 26 2004-12-31 02:06:43Z claco $
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Handel::DBI');
};

my $filter   = {foo => 'bar'};
my $wildcard = {foo => 'bar%'};

ok(! Handel::DBI::has_wildcard($filter));
ok(Handel::DBI::has_wildcard($wildcard));
ok(Handel::DBI::uuid);
