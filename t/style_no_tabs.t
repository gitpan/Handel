#!perl -wT
# $Id: /local/CPAN/Handel/t/style_no_tabs.t 1048 2007-07-21T02:27:09.400002Z claco  $
use strict;
use warnings;
use lib 't/lib';
use Handel::Test;

plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

eval 'use Test::NoTabs 0.03';
plan skip_all => 'Test::NoTabs 0.03 not installed' if $@;

all_perl_files_ok('lib');
