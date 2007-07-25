#!perl -wT
# $Id: /local/Handel/trunk/t/style_no_tabs.t 1796 2007-07-21T02:28:17.957833Z claco  $
use strict;
use warnings;
use lib 't/lib';
use Handel::Test;

plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

eval 'use Test::NoTabs 0.03';
plan skip_all => 'Test::NoTabs 0.03 not installed' if $@;

all_perl_files_ok('lib');
