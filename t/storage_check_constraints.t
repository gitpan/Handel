#!perl -wT
# $Id: storage_check_constraints.t 1421 2006-09-20 23:04:22Z claco $
use strict;
use warnings;
use Test::More tests => 10;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Constraints', 'constraint_uuid');
};


my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


## throw exception if no hash ref is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->check_constraints;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass;
    like(shift, qr/not a HASH/i);
} otherwise {
    diag shift;
    fail;
};


# do nothing if no constraints are set
my $data = {};
ok($storage->check_constraints($data));


# set the constraints
$storage->constraints({
    id => {'Check Id Format' => \&constraint_uuid}
});


## throw exception if constraints fail
try {
    local $ENV{'LANG'} = 'en';
    $storage->check_constraints($data);

    fail('no exception thrown');
} catch Handel::Exception::Constraint with {
    pass;
    like(shift, qr/failed database constraints: Check Id Format\(id\)/i);
} otherwise {
    diag shift;
    fail;
};

# make it work people
$data->{'id'} = '00000000-0000-0000-0000-000000000000';
ok($storage->check_constraints($data));

