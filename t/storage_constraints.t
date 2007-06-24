#!perl -wT
# $Id: storage_constraints.t 1915 2007-06-24 15:35:46Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 3;

    use_ok('Handel::Storage');
};


my $constraints = {
    'name'        => {'check_name' => \&check_name},
    'description' => {'check_description' => \&check_description}
};

my $storage = Handel::Storage->new;
isa_ok($storage, 'Handel::Storage');


$storage->constraints($constraints);
is_deeply($storage->constraints, $constraints, 'set constraints');
