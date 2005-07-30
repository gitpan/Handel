#!perl -wT
# $Id: exceptions.t 618 2005-07-29 02:09:56Z claco $
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