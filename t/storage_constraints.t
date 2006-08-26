#!perl -wT
# $Id: storage_constraints.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('Handel::Storage');
};


my $constraints = {
    'name'        => {'check_name' => \&check_name},
    'description' => {'check_description' => \&check_description}
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


$storage->constraints($constraints);
is_deeply($storage->constraints, $constraints);
