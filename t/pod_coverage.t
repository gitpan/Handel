#!perl -wT
# $Id: pod_coverage.t 88 2005-01-30 03:06:07Z claco $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04' if $@;

eval 'use Pod::Coverage 0.14';
plan skip_all => 'Pod::Coverage 0.14 not installed' if $@;

my $trustme = {
    trustme => [qr/^(new|parse_(char|end|start)|start_document)$/]
};

all_pod_coverage_ok($trustme);
