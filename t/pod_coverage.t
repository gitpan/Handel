#!perl -wT
# $Id: pod_coverage.t 210 2005-02-20 19:38:08Z claco $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04' if $@;

eval 'use Pod::Coverage 0.14';
plan skip_all => 'Pod::Coverage 0.14 not installed' if $@;

my $trustme = {
    trustme => [qr/^(new|load|uuid|guid|parse_(char|end|start)|start_document)$/]
};

all_pod_coverage_ok($trustme);
