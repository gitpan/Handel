#!perl -wT
# $Id: pod_coverage.t 42 2004-12-31 20:33:54Z claco $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
eval 'use Pod::Coverage 0.14';
plan skip_all => 'Test::Pod::Coverage 1.04/Pod::Coverage 0.14 not installed' if
$@;

my $trustme = { trustme => [qr/^new$/] };

all_pod_coverage_ok($trustme);

