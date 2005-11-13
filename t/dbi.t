#!perl -wT
# $Id: dbi.t 837 2005-09-19 22:56:39Z claco $
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
