#!/usr/bin/perl -wT
# $Id: base_get_column.t 1560 2006-11-10 02:36:54Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'use Test::MockObject 0.07';
    if (!$@) {
        plan tests => 10;
    } else {
        plan skip_all => 'Test::MockObject 0.07 not installed';
    };

    use_ok('Handel::Base');
    use_ok('Handel::Exception', ':try');
};


## fake result object
my $result = Test::MockObject->new;
$result->set_always('col1', 'Column1');
$result->set_always('col2', 'Column2');


## set the result and basic accessor map
my $base = bless {}, 'Handel::Base';
$base->result($result);
$base->accessor_map({
    foo => 'col1'
});


## the magic happens here
is($base->get_column('foo'), 'Column1', 'get_column using accessor mapping');
is($base->get_column('col2'), 'Column2', 'get_column real name');


## throw exception when no column param is sent
{
    try {
        local $ENV{'LANG'} = 'en';
        $base->get_column;

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception thrown');
        like(shift, qr/no column/i, 'no column in exception message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## throw exception when column param is empty
{
    try {
        local $ENV{'LANG'} = 'en';
        $base->get_column('');

        fail('no exception thrown');
    } catch Handel::Exception::Argument with {
        pass('Argument exception thrown');
        like(shift, qr/no column/i, 'no column in exception message');
    } otherwise {
        fail('Other exception thrown');
    };
};


## throw exception as a class method
{
    try {
        local $ENV{'LANG'} = 'en';
        Handel::Base->get_column;

        fail('no exception thrown');
    } catch Handel::Exception with {
        pass('Argument exception thrown');
        like(shift, qr/not a class method/i, 'not a class method in message');
    } otherwise {
        fail('Other exception thrown');
    };
};
