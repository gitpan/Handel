#!perl -wT
# $Id: pod_syntax.t 26 2004-12-31 02:06:43Z claco $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 not installed' if $@;

all_pod_files_ok();
