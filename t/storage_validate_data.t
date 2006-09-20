#!perl -wT
# $Id: storage_validate_data.t 1420 2006-09-20 02:35:20Z claco $
use strict;
use warnings;
use Test::More tests => 11;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


## throw exception if no hash ref is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->validate_data;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass;
    like(shift, qr/not a HASH/);
} otherwise {
    diag shift;
    fail;
};


## throw exception if not ARRAYREF for FV::S
try {
    local $ENV{'LANG'} = 'en';
    $storage->validation_profile({});
    $storage->validate_data({});

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass;
    like(shift, qr/requires an ARRAYREF/);
} otherwise {
    diag shift;
    fail;
};


## just do it
$storage->validation_profile([
    name => ['NOT_BLANK'],
    description => ['NOT_BLANK', ['LENGTH', 2, 4]]
]);

my $results = $storage->validate_data({
    name => 'foo', description => 'bar'
});
isa_ok($results, 'FormValidator::Simple::Results');
ok($results->success);



## bad data!
$results = $storage->validate_data({
    name => '', description => 'stuffs'
});
isa_ok($results, 'FormValidator::Simple::Results');
ok(!$results->success);
