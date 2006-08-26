#!perl -wT
# $Id: storage_add_constraint.t 1385 2006-08-25 02:42:03Z claco $
use strict;
use warnings;
use Test::More tests => 14;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    my $storage = Handel::Storage->new;
    isa_ok($storage, 'Handel::Storage');
    is($storage->constraints, undef);

    my $constraint = sub{};
    $storage->add_constraint('id', 'check id' => $constraint);
    is_deeply($storage->constraints, {id => {'check id' => $constraint}});

    my $new_constraint = sub{};
    $storage->add_constraint('name', 'first' => $new_constraint);

    is_deeply($storage->constraints, {'id' => {'check id' => $constraint}, 'name' => {first => $new_constraint}});

    ## throw exception when no column is passed
    {
        try {
            local $ENV{'LANG'} = 'en';
            $storage->add_constraint(undef, second => sub{});

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass;
            like(shift, qr/no column/i);
        } otherwise {
            fail;
        };
    };

    ## throw exception when no name is passed
    {
        try {
            local $ENV{'LANG'} = 'en';
            $storage->add_constraint('id', undef, sub{});

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass;
            like(shift, qr/no constraint name/i);
        } otherwise {
            fail;
        };
    };

    ## throw exception when no constraint is passed
    {
        try {
            local $ENV{'LANG'} = 'en';
            $storage->add_constraint('id', 'second' => undef);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass;
            like(shift, qr/no constraint/i);
        } otherwise {
            fail;
        };
    };

    ## throw exception when non-CODEREF is passed
    {
        try {
            local $ENV{'LANG'} = 'en';
            $storage->add_constraint('id', 'second' => []);

            fail('no exception thrown');
        } catch Handel::Exception::Argument with {
            pass;
            like(shift, qr/no constraint/i);
        } otherwise {
            fail;
        };
    };
};
