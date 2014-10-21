#!perl -wT
# $Id: basic.t 675 2005-08-07 01:54:52Z claco $
use strict;
use warnings;
use Test::More tests => 23;

BEGIN {
    use_ok('Handel');
    use_ok('Handel::Cart');
    use_ok('Handel::Cart::Item');
    use_ok('Handel::Checkout');
    use_ok('Handel::Checkout::Plugin');
    use_ok('Handel::Constants');
    use_ok('Handel::Constraints');
    use_ok('Handel::Currency');
    use_ok('Handel::DBI');
    use_ok('Handel::Exception');
    use_ok('Handel::Iterator');
    use_ok('Handel::L10N');
    use_ok('Handel::L10N::en_us');
    use_ok('Handel::L10N::fr');
    use_ok('Handel::Order');
    use_ok('Handel::Order::Item');

    SKIP: {
        eval 'use Apache::AxKit::Language::XSP';
        skip 'AxKit not installed', 3 if $@;

        {
            ## squelch AxKit strict/warnings
            no strict;
            no warnings;
            use_ok('AxKit::XSP::Handel::Cart');
            use_ok('AxKit::XSP::Handel::Checkout');
            use_ok('AxKit::XSP::Handel::Order');
        };
    };

    SKIP: {
        eval 'use Template 2.07';
        skip 'Template Toolkit 2.07 not installed', 4 if $@;

        use_ok('Template::Plugin::Handel::Cart');
        use_ok('Template::Plugin::Handel::Checkout');
        use_ok('Template::Plugin::Handel::Constants');
        use_ok('Template::Plugin::Handel::Order');
    };
};
