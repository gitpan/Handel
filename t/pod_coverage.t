#!perl -wT
# $Id: pod_coverage.t 289 2005-03-04 02:31:57Z claco $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04' if $@;

eval 'use Pod::Coverage 0.14';
plan skip_all => 'Pod::Coverage 0.14 not installed' if $@;

my $trustme = {
    trustme =>
    [qr/^(accessor_name|stringify|FETCH|STORE|DELETE|EXISTS|CLEAR|new|load|uuid|guid|parse_(char|end|start)|start_document)$/]
};

all_pod_coverage_ok($trustme);
