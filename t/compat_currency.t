#!perl -wT
# $Id: compat_currency.t 1511 2006-10-27 18:40:38Z claco $
use strict;
use warnings;
use Test::More tests => 37;

BEGIN {
    use_ok('Handel::Compat::Currency');
    use_ok('Handel::Exception', ':try');
};

## test stringification and returns in the absence of
## Locale::Currency::Format
{
    my $currency = Handel::Compat::Currency->new(1.2);
    isa_ok($currency, 'Handel::Compat::Currency');
    is($currency, 1.2);

    is($currency->format, '1.20 USD');
    is($currency->format('CAD'), '1.20 CAD');
    is($currency->format(undef, 'FMT_NAME'), '1.20 US Dollar');
    is($currency->format('CAD', 'FMT_NAME'), '1.20 Canadian Dollar');
    
    is($currency->code, undef);
    is($currency->name, 'US Dollar');

    $currency->code('DKK');
    is($currency->code, 'DKK');
    is($currency->name, 'Danish Krone');
    is($currency->name('JPY'), 'Yen');

    $currency->code(undef);

    try {
        $currency->code('CRAP');

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


{
    my $currency = Handel::Compat::Currency->new(1);
    isa_ok($currency, 'Handel::Compat::Currency');
    is($currency, 1);

    try {
        $currency->convert('CRAP', 'CAD');

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };

    try {
        $currency->convert('USD', 'JUNK');

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };

    is($currency->convert('USD', 'USD'), undef);
    ok($currency->convert('USD', 'CAD'));

    {
        local $ENV{'HandelCurrencyCode'} = 'CAD';
        is($currency->convert(undef, 'CAD'), undef);
        ok($currency->convert(undef, 'USD'));
    }

    $currency->code('USD');
    is($currency->code, 'USD');
    is($currency->convert(undef, 'USD'), undef);
    is($currency->convert, undef);

    {
        $currency->code(undef);
        local $ENV{'HandelCurrencyCode'} = '';
        local $Handel::ConfigReader::Defaults{'HandelCurrencyCode'} = '';

        is($currency->convert, undef);


        try {
            $currency->convert(undef, 'CAD');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    {
        $currency->code(undef);
        local $ENV{'HandelCurrencyCode'} = 'USD';

        is($currency->convert, undef);
    };

    {
        no warnings 'redefine';
        local *Handel::Currency::convert = sub {};
        is($currency->convert('USD', 'CAD', 1), undef);
    };
};


{
    my $currency = Handel::Compat::Currency->new(1);
    isa_ok($currency, 'Handel::Compat::Currency');
    is($currency, 1);

    try {
        $currency->convert('ZZZ', 'CAD');

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };

    try {
        $currency->convert('USD', 'ZZZ');

        fail;
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


{
    my $currency = Handel::Compat::Currency->new(1.23);
    isa_ok($currency, 'Handel::Compat::Currency');
    is($currency, 1.23);

    ok($currency->convert('USD', 'CAD', 1, 'FMT_STANDARD') =~ / CAD$/);
    ok($currency->convert('USD', 'CAD', 0, 'FMT_STANDARD') !~ / CAD$/);
};
