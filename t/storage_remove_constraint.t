#!perl -wT
# $Id: storage_remove_constraint.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Test::More tests => 9;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');

## start w/ nothing
is($storage->constraints, undef);

my $sub = {};
$storage->constraints({
    id => {
        'Check Id' => $sub,
        'Check It Again' => $sub
    }
});

## remove constraint from unconnected schema
$storage->remove_constraint('id', 'Check Id');
is_deeply($storage->constraints, {'id' => {'Check It Again' => $sub}});


## throw exception when no column is specified
try {
    local $ENV{'LANG'} = 'en';
    $storage->remove_constraint;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass;
    like(shift, qr/no column/i);
} otherwise {
    fail;
};

## throw exception when no name is specified
try {
    local $ENV{'LANG'} = 'en';
    $storage->remove_constraint('col');

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass;
    like(shift, qr/no constraint name/i);
} otherwise {
    fail;
};
