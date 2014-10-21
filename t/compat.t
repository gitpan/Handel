#!perl -w
# $Id: /local/CPAN/Handel/trunk/t/compat.t 1963 2007-08-22T02:36:42.709186Z claco  $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 15;

    local $ENV{'LANGUAGE'} = 'en'; 
    local $SIG{__WARN__} = sub {
        like(shift, qr/deprecated/);
    };
    use_ok('Handel::Compat');
    
    ## load Handel::Base for tests.
    ## in the wild, the superclasses already have it
    use_ok('Handel::Base');
    use_ok('Handel::Constraints', 'constraint_uuid');
    push @Handel::Compat::ISA, 'Handel::Base';
};

Handel::Base->storage_class('Handel::Storage::DBIC');

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

Handel::Compat->iterator_class('Handel::Base');
is(Handel::Compat->iterator_class, 'Handel::Base');
is(Handel::Compat->storage->iterator_class, 'Handel::Base');

Handel::Compat->table('foo');
is(Handel::Compat->table, 'foo');
is(Handel::Compat->storage->table_name, 'foo');

ok(constraint_uuid(Handel::Compat::uuid));
ok(constraint_uuid(Handel::Compat->uuid));
