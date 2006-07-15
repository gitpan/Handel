#!perl -wT
# $Id: pod_syntax.t 1338 2006-07-15 19:40:26Z claco $
use strict;
use warnings;
use Test::More;

plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 not installed' if $@;

all_pod_files_ok();
