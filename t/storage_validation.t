#!perl -wT
# $Id: storage_validation.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};

my $validation = [
    name => ['NOT_BLANK'],
    description => ['NOT_BLANK', ['LENGTH', 2, 4]]
];

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


$storage->validation_profile($validation);
is_deeply($storage->validation_profile, $validation);
