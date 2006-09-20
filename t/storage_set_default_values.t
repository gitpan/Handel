#!perl -wT
# $Id: storage_set_default_values.t 1420 2006-09-20 02:35:20Z claco $
use strict;
use warnings;
use Test::More tests => 7;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


## throw exception if no hash ref is passed
try {
    local $ENV{'LANG'} = 'en';
    $storage->set_default_values;

    fail('no exception thrown');
} catch Handel::Exception::Argument with {
    pass;
    like(shift, qr/not a HASH/i);
} otherwise {
    diag shift;
    fail;
};


# do nothing if no defaults are set
my $data = {};
$storage->set_default_values($data);
is_deeply($data, {});


# set the defaults
$storage->default_values({
    col1 => 'foo', col2 => sub{'bar'}
});
$storage->set_default_values($data);
is_deeply([sort %{$data}], [qw/bar col1 col2 foo/]);
