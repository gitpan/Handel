#!perl -wT
# $Id: pod_coverage.t 26 2004-12-31 02:06:43Z claco $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04 not installed' if $@;

my $trustme = { trustme => [qr/^new$/] };

all_pod_coverage_ok($trustme);
