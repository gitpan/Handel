#!perl -wT
# $Id: pod_coverage.t 16 2004-12-30 05:02:52Z claco $
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04 not installed' if $@;

my $trustme = { trustme => [qr/^new$/] };

all_pod_coverage_ok($trustme);
