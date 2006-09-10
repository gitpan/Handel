#!perl -wT
# $Id: storage_setup.t 1409 2006-09-09 21:16:54Z claco $
use strict;
use warnings;
use Test::More tests => 21;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    ## setup a schema
    my $storage = Handel::Storage->new({
        iterator_class     => 'Handel::Base',
        currency_class     => 'Handel::Base',
        autoupdate         => 2,
        default_values     => {foo => 'bar',baz => 'quix'},
        validation_profile => [param1 => [ ['NOT_BLANK'], ['LENGTH', 4, 10] ]],
        add_columns        => [qw/foo bar baz/],
        remove_columns     => [qw/quix temp/],
        constraints        => {
            foo => {'check_foo' => sub{}},
            bar => {'check_bar' => sub{}}
        },
        currency_columns   => [qw/foo bar/]
    });

    isa_ok($storage, 'Handel::Storage');

    ## now call setup again and make sure it overides the old
    my $default_values = {
        foo => 'new',
        baz => 'old'
    };

    my $validation_profile = [
        param1 => [ ['BLANK'], ['ASCII', 2, 12] ]
    ];

    my $constraints = {
        one => sub{},
        two => sub{}
    };

    my $currency_columns = [qw/baz/];
    my $add_columns = [qw/one two three/];
    my $remove_columns = [qw/this that/];

    $storage->setup({
        iterator_class     => 'Handel::Iterator',
        currency_class     => 'Handel::Currency',
        autoupdate         => 3,
        default_values     => $default_values,
        validation_profile => $validation_profile,
        add_columns        => $add_columns,
        remove_columns     => $remove_columns,
        constraints        => $constraints,
        currency_columns   => $currency_columns
    });

    ## iterator_class
    is($storage->iterator_class, 'Handel::Iterator');
    is(Handel::Storage->iterator_class, 'Handel::Iterator::List');

    ## currency_class
    is($storage->currency_class, 'Handel::Currency');
    is(Handel::Storage->currency_class, 'Handel::Currency');

    ## autoupdate
    is($storage->autoupdate, 3);
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
    is_deeply([sort $storage->columns], [qw/bar baz foo one three two/]);
    is(Handel::Storage->columns, 0);

    ## currency_columns
    is_deeply([$storage->currency_columns], $currency_columns);
    is(Handel::Storage->currency_columns, 0);


    ## throw exception if setup gets no $args
    {
        try {
            local $ENV{'LANG'} = 'en';
            my $storage = Handel::Storage->new;
            $storage->setup();

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass;
            like(shift, qr/not a HASH/);
        } otherwise {
            fail;
        };
    };
};
