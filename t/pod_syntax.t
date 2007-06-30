#!perl -wT
# $Id: /local/Handel/trunk/t/pod_syntax.t 1569 2007-06-24T15:35:46.298350Z claco  $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

    eval 'use Test::Pod 1.00';
    plan skip_all => 'Test::Pod 1.00 not installed' if $@;
};

all_pod_files_ok();
