#!perl -wT
# $Id: dbi.t 6 2004-12-28 23:33:59Z claco $
use Test::More tests => 4;

BEGIN {
    use_ok('Handel::DBI');
};

my $filter   = {foo => 'bar'};
my $wildcard = {foo => 'bar%'};

ok(! Handel::DBI::has_wildcard($filter));
ok(Handel::DBI::has_wildcard($wildcard));
ok(Handel::DBI::uuid);
