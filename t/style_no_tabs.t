#!perl -wT
# $Id: style_no_tabs.t 1389 2006-08-31 02:21:14Z claco $
use strict;
use warnings;
use Test::More;

plan skip_all => 'set TEST_NOTABS or TEST_PRIVATE to enable this test' unless $ENV{TEST_NOTABS} || $ENV{TEST_PRIVATE};

eval 'use Test::NoTabs 0.03';
plan skip_all => 'Test::NoTabs 0.03 not installed' if $@;

all_perl_files_ok('lib');
