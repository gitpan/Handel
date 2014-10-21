#!perl -wT
# $Id: basic.t 1321 2006-07-11 00:43:58Z claco $
use strict;
use warnings;
use Test::More tests => 49;

BEGIN {
    use_ok('Handel');
    use_ok('Handel::Base');
    use_ok('Handel::Cart');
    use_ok('Handel::Cart::Item');
    use_ok('Handel::Cart::Schema');
    use_ok('Handel::Checkout');
    use_ok('Handel::Checkout::Message');
    use_ok('Handel::Checkout::Plugin');
    use_ok('Handel::Checkout::Plugin::MarkOrderSaved');
    use_ok('Handel::Checkout::Plugin::AssignOrderNumber');
    use_ok('Handel::Checkout::Stash');
    use_ok('Handel::Components::Constraints');
    use_ok('Handel::Components::DefaultValues');
    use_ok('Handel::Components::Validation');
    use_ok('Handel::ConfigReader');
    use_ok('Handel::Constants');
    use_ok('Handel::Constraints');
    use_ok('Handel::Currency');
    use_ok('Handel::Exception');
    use_ok('Handel::Iterator');
    use_ok('Handel::L10N');
    use_ok('Handel::L10N::en_us');
    use_ok('Handel::L10N::fr');
    use_ok('Handel::L10N::zh_tw');
    use_ok('Handel::Order');
    use_ok('Handel::Order::Item');
    use_ok('Handel::Order::Schema');
    use_ok('Handel::Schema');
    use_ok('Handel::Schema::Cart');
    use_ok('Handel::Schema::Cart::Item');
    use_ok('Handel::Schema::Order');
    use_ok('Handel::Schema::Order::Item');
    use_ok('Handel::Storage');
    use_ok('Handel::Storage::Cart');
    use_ok('Handel::Storage::Order');

    {
        ## no need for the deprected warnings here
        local $SIG{__WARN__} = sub{};

        use_ok('Handel::Compat');
    };

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

    SKIP: {
        eval 'use Catalyst 5.7';
        skip 'Catalyst 5.7 not installed', 6 if $@;

        use_ok('Catalyst::Helper::Handel::Scaffold');
        use_ok('Catalyst::Helper::Controller::Handel::Cart');
        use_ok('Catalyst::Helper::Controller::Handel::Checkout');
        use_ok('Catalyst::Helper::Controller::Handel::Order');
        use_ok('Catalyst::Helper::Model::Handel::Cart');
        use_ok('Catalyst::Helper::Model::Handel::Order');
    };
};
