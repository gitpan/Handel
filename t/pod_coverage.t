#!perl -wT
# $Id: pod_coverage.t 62 2005-01-10 02:21:14Z claco $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
eval 'use Pod::Coverage 0.14';
plan skip_all => 'Test::Pod::Coverage 1.04/Pod::Coverage 0.14 not installed' if
$@;

my $trustme = {
    trustme => [qr/^(new|parse_(char|end|start)|start_document)$/]
};

all_pod_coverage_ok($trustme);


