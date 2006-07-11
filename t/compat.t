#!perl -w
# $Id: compat.t 1318 2006-07-10 23:42:32Z claco $
use strict;
use warnings;
use Test::More tests => 16;

BEGIN {
    local $SIG{__WARN__} = sub {
        like(shift, qr/deprecated/);
    };
    use_ok('Handel::Compat');
    
    ## load Handel::Base for tests.
    ## in the wild, the superclasses already have it
    use_ok('Handel::Base');
    push @Handel::Compat::ISA, 'Handel::Base';
};

my $filter   = {foo => 'bar'};
my $wildcard = {foo => 'bar%'};

ok(! Handel::Compat::has_wildcard($filter));
ok(Handel::Compat::has_wildcard($wildcard));
ok(Handel::Compat::uuid);

Handel::Compat->add_columns(qw/foo bar baz/);
is_deeply(Handel::Compat->storage->_columns_to_add, [qw/foo bar baz/]);

my $constraint = sub {};
Handel::Compat->add_constraint('Check Id', id => $constraint);
is_deeply(Handel::Compat->storage->constraints, {'id', {'Check Id' => $constraint}});

Handel::Compat->item_class('Handel::Base');
is(Handel::Compat->item_class, 'Handel::Base');
is(Handel::Compat->storage->item_class, 'Handel::Base');

Handel::Compat->cart_class('Handel::Base');
is(Handel::Compat->cart_class, 'Handel::Base');
is(Handel::Compat->storage->cart_class, 'Handel::Base');

Handel::Compat->iterator_class('Handel::Base');
is(Handel::Compat->iterator_class, 'Handel::Base');
is(Handel::Compat->storage->iterator_class, 'Handel::Base');

Handel::Compat->table('foo');
is(Handel::Compat->table, 'foo');
is(Handel::Compat->storage->table_name, 'foo');

