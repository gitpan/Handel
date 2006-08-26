#!perl -w
# $Id: perl_critic.t 1378 2006-08-21 18:48:39Z claco $
use strict;
use warnings;
use Test::More;

plan skip_all => 'set TEST_CRITIC to enable this test' unless $ENV{TEST_CRITIC};

eval 'use Test::Perl::Critic 0.07';
plan skip_all => 'Test::Perl::Critic 0.07 not installed' if $@;

Test::Perl::Critic->import(
    -profile  => 't/perl_critic.rc',
    -severity => 1,
    -format   => "%m at line %l, column %c: %p Severity %s\n\t%r"
);

all_critic_ok();
