#!perl -wT
# $Id: config.t 267 2005-03-01 04:31:59Z claco $
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Handel::ConfigReader');
};

my $cfg = Handel::ConfigReader->new();
isa_ok($cfg, 'Handel::ConfigReader');

{
    local $ENV{'MySetting'} = 23;
    is($cfg->get('MySetting'), $ENV{'MySetting'});
    is($cfg->get('MyOtherSetting', 25), 25);
};
