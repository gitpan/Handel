#!perl -w
# $Id: style_perl_critic.t 1415 2006-09-14 00:54:13Z claco $
use strict;
use warnings;
use Test::More;

plan skip_all => 'set TEST_CRITIC or TEST_PRIVATE to enable this test' unless $ENV{TEST_CRITIC} || $ENV{TEST_PRIVATE};

eval 'use Test::Perl::Critic 0.07';
plan skip_all => 'Test::Perl::Critic 0.07 not installed' if $@;

Test::Perl::Critic->import(
    -profile  => 't/style_perl_critic.rc',
    -severity => 1,
    -format   => "%m at line %l, column %c: %p Severity %s\n\t%r"
);

all_critic_ok();
