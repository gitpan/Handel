#!perl -wT
# $Id: storage_check_constraints.t 1555 2006-11-09 01:46:20Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 10;

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
    pass('caught argument exception');
    like(shift, qr/not a HASH/i, 'not a has in message');
} otherwise {
    fail('other exception caught');
};


# do nothing if no constraints are set
my $data = {};
ok($storage->check_constraints($data), 'passed constraint checks');


# set the constraints
$storage->constraints({
    id => {'Check Id Format' => \&constraint_uuid, 'Check without sub' => undef}
});


## throw exception if constraints fail
try {
    local $ENV{'LANG'} = 'en';
    $storage->check_constraints($data);

    fail('no exception thrown');
} catch Handel::Exception::Constraint with {
    pass('caught constraint exception');
    like(shift, qr/failed database constraints: Check Id Format\(id\)/i, 'failed constraint in message');
} otherwise {
    fail('other exception caught');
};

# make it work people
$data->{'id'} = '00000000-0000-0000-0000-000000000000';
ok($storage->check_constraints($data), 'passed constraint checks');

