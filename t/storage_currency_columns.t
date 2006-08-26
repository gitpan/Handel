#!perl -wT
# $Id: storage_currency_columns.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Test::More tests => 8;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


## start w/ nothing
is($storage->_currency_columns, undef);
is($storage->currency_columns, 0);


## add columns, and get them back
$storage->_columns([qw/foo bar baz fap/]);
$storage->_currency_columns([qw/foo bar/]);
is_deeply([$storage->currency_columns], [qw/foo bar/]);


## throw exception when primary column doesn't exists in columns
{
    try {
        $storage->currency_columns(qw/bar quix/);

        fail('no exception thrown');
    } catch Handel::Exception::Storage with {
        pass;
        like(shift, qr/does not exist/i);
    } otherwise {
        fail;
    };
};
