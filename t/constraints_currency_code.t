#!perl -wT
# $Id: constraints_currency_code.t 437 2005-03-18 02:13:35Z claco $
use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    use_ok('Handel::Constraints', qw(:all));
};

ok(constraint_currency_code('usd'));
ok(constraint_currency_code('USD'));
ok(!constraint_currency_code('USDD'));

SKIP: {
    eval 'use Locale::Currency';
    skip 'Locale::Currency not installed', 1 if $@;

    ok(!constraint_currency_code('ZZZ'));
};
