#!perl -wT
# $Id: pod_syntax.t 6 2004-12-28 23:33:59Z claco $
use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 not installed' if $@;

all_pod_files_ok();
