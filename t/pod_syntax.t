#!perl -wT
# $Id: pod_syntax.t 837 2005-09-19 22:56:39Z claco $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 not installed' if $@;

all_pod_files_ok();
