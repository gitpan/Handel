#!perl -wT
# $Id: basic.t 61 2005-01-10 02:20:36Z claco $
use strict;
use warnings;
use Test::More tests => 12;

BEGIN {
    use_ok('Handel');
    use_ok('Handel::Cart');
    use_ok('Handel::Cart::Item');
    use_ok('Handel::Constants');
    use_ok('Handel::Constraints');
    use_ok('Handel::DBI');
    use_ok('Handel::Exception');
    use_ok('Handel::Iterator');
    use_ok('Handel::L10N');
    use_ok('Handel::L10N::en_us');
    use_ok('Handel::L10N::fr');

    SKIP: {
        eval 'use Apache::AxKit::Language::XSP';
        skip 'AxKit not installed', 1 if $@;

        {
            ##
            no strict;
            no warnings;
            use_ok('AxKit::XSP::Handel::Cart');
        };
    };
};
