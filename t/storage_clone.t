#!perl -wT
# $Id: storage_clone.t 1409 2006-09-09 21:16:54Z claco $
use strict;
use warnings;
use Test::More tests => 25;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    ## create a new storage and check configuration
    my $sub = sub{};
    my $storage = Handel::Storage->new({
        default_values     => {id => 1, name => 'New Cart'},
        validation_profile => {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]},
        add_columns        => [qw/one two/],
        remove_columns     => [qw/name/],
        constraints        => {
            id   => {'check_id' => $sub},
            name => {'check_name' => $sub}},
        currency_columns   => [qw/one/]
    });
    isa_ok($storage, 'Handel::Storage');

    my $clone = $storage->clone;
    isa_ok($clone, 'Handel::Storage');
    
    is_deeply($clone, $storage);
    
    ## make them diverge
    $clone->iterator_class('Handel::Base');
    is($clone->iterator_class, 'Handel::Base');
    is($storage->iterator_class, 'Handel::Iterator::List');

    $clone->currency_class('Handel::Base');
    is($clone->currency_class, 'Handel::Base');
    is($storage->currency_class, 'Handel::Currency');
    
    $clone->autoupdate(3);
    is($clone->autoupdate, 3);
    is($storage->autoupdate, 1);

    $clone->default_values->{id} = 2;
    is_deeply($clone->default_values, {id => 2, name => 'New Cart'});
    is_deeply($storage->default_values, {id => 1, name => 'New Cart'});

    $clone->validation_profile->{'cart'} = [qw/foo/];
    is_deeply($clone->validation_profile, {cart=>['foo']});
    is_deeply($storage->validation_profile, {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]});

    $clone->add_columns('quix');
    is_deeply($clone->_columns, [qw/one two quix/]);
    is_deeply($storage->_columns, [qw/one two/]);
    
    $clone->remove_columns('two');
    is_deeply($clone->_columns, [qw/one quix/]);
    is_deeply($storage->_columns, [qw/one two/]);
    
    my $foo = sub{};
    $clone->add_constraint('foo', 'check foo', $foo);
    is_deeply($clone->constraints, {
            id   => {'check_id' => $sub},
            name => {'check_name' => $sub},
            foo  => {'check foo' => $foo}
    });
    is_deeply($storage->constraints, {
            id   => {'check_id' => $sub},
            name => {'check_name' => $sub}
    });

    push @{$clone->_currency_columns}, 'dongle';
    is_deeply([sort $clone->currency_columns], [qw/dongle one/]);
    is_deeply([$storage->currency_columns], [qw/one/]);

    undef $clone;

    ## throw exception as a class method
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $storage = Handel::Storage->clone;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
            like(shift, qr/not a class/i);
        } otherwise {
            fail;
        };
    };
};
