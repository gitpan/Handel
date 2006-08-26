#!perl -wT
# $Id: storage_new.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Test::More tests => 23;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    my $default_values = {
        foo => 'bar',
        baz => 'quix'
    };

    my $validation_profile = [
        param1 => [ ['NOT_BLANK'], ['LENGTH', 4, 10] ]
    ];

    my $constraints = {
        foo => {'check_foo' => sub{}},
        bar => {'check_bar' => sub{}}
    };

    my $add_columns = [qw/foo bar baz/];
    my $remove_columns = [qw/bar/];
    my $currency_columns = [qw/foo/];

    my $storage = Handel::Storage->new({
        cart_class         => 'Handel::Base',
        item_class         => 'Handel::Base',
        iterator_class     => 'Handel::Base',
        currency_class     => 'Handel::Base',
        autoupdate         => 2,
        default_values     => $default_values,
        validation_profile => $validation_profile,
        add_columns        => $add_columns,
        remove_columns     => $remove_columns,
        constraints        => $constraints,
        currency_columns   => $currency_columns,
    });

    isa_ok($storage, 'Handel::Storage');

    ## cart_class
    is($storage->cart_class, 'Handel::Base');
    is(Handel::Storage->cart_class, undef);

    ## item_class
    is($storage->item_class, 'Handel::Base');
    is(Handel::Storage->item_class, undef);

    ## iterator_class
    is($storage->iterator_class, 'Handel::Base');
    is(Handel::Storage->iterator_class, 'Handel::Iterator::List');

    ## currency_class
    is($storage->currency_class, 'Handel::Base');
    is(Handel::Storage->currency_class, 'Handel::Currency');

    ## autoupdate
    is($storage->autoupdate, 2);
    is(Handel::Storage->autoupdate, 1);

    ## default_values
    is_deeply($storage->default_values, $default_values);
    is(Handel::Storage->default_values, undef);

    ## validation_profile
    is_deeply($storage->validation_profile, $validation_profile);
    is(Handel::Storage->validation_profile, undef);

    ## constraints
    is_deeply($storage->constraints, $constraints);
    is(Handel::Storage->constraints, undef);

    ## add_columns
    is_deeply([$storage->columns], [qw/foo baz/]);
    is(Handel::Storage->columns, 0);

    ## currency_columns
    is_deeply([$storage->currency_columns], $currency_columns);
    is(Handel::Storage->currency_columns, 0);
};
