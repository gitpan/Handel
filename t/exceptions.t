#!perl -wT
# $Id: exceptions.t 837 2005-09-19 22:56:39Z claco $
use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('Handel::Exception', qw(:try));
};


## verify -text and -details propagation
{
    try {
        throw Handel::Exception::Argument(-text => 'foo');
    } catch Handel::Exception with {
        is(shift->text, 'foo')
    };

    try {
        throw Handel::Exception::Argument(-text => 'foo', -details => 'details');
    } catch Handel::Exception with {
        is(shift->text, 'foo: details')
    };
};