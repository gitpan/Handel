#!perl -wT
# $Id: /local/CPAN/Handel/t/constraints_currency_code.t 1043 2007-06-24T15:35:46.298350Z claco  $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 7;

    use_ok('Handel::Constraints', qw(:all));
};

ok(!constraint_currency_code(undef),     'value is undefined');
ok(!constraint_currency_code(''),        'value is empty string');
ok(constraint_currency_code('usd'),      'value is lower case');
ok(constraint_currency_code('USD'),      'value is upper case');
ok(!constraint_currency_code('USDD'),    'value is too long');

SKIP: {
    eval 'use Locale::Currency';
    skip 'Locale::Currency not installed', 1 if $@;

    ok(!constraint_currency_code('ZZZ'), 'valid is invalid code');
};
