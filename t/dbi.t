#!perl -wT
# $Id: dbi.t 100 2005-02-03 02:22:22Z claco $
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
