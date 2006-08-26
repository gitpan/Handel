#!perl -wT
# $Id: base_create_accessors.t 1386 2006-08-26 01:46:16Z claco $
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 10;

BEGIN {
    use_ok('Handel::Base');
};

no warnings 'redefine';
my $accessors = {a => 'a', b => 'b', c => 'd'};

sub Handel::Storage::column_accessors {
    return $accessors;
};

sub Handel::Base::get_column {
    pass;
};

Handel::Base->storage_class('Handel::Subclassing::Storage');
is(Handel::Base->accessor_map, undef);

Handel::Base->create_accessors;
can_ok('Handel::Base', 'a');
can_ok('Handel::Base', 'b');
can_ok('Handel::Base', 'd');
ok(!Handel::Base->can('c'));
is_deeply(Handel::Base->accessor_map, $accessors);

Handel::Base->a;
Handel::Base->b;
Handel::Base->d;
