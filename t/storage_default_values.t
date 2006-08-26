#!perl -wT
# $Id: storage_default_values.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


my $default_values = {
    name        => 'My Default Name',
    description => sub{'My Default Description'}
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');

$storage->default_values($default_values);
is_deeply($storage->default_values, $default_values);
