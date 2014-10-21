#!perl -wT
# $Id: checkout_plugins.t 554 2005-06-26 01:18:27Z claco $
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 59;

BEGIN {
    use_ok('Handel::Checkout');
};

SKIP: {
    diag "Waiting on Module::Pluggable 2.9 Taint Fixes";

    eval 'use Module::Pluggable 2.9';
    skip 'Module::Pluggable >= 2.9 not installed', 58 if $@;

    ## Load all plugins in a new path
    {
        local $ENV{'HandelPluginPaths'} = 'Handel::TestPlugins';

        my $checkout = Handel::Checkout->new;
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 1);
        ok(exists $plugins{'Handel::TestPlugins::First'});
        ok(!exists $plugins{'Handel::OtherTestPlugins::Second'});
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

        my $plugin = $plugins{'Handel::TestPlugins::First'};
        isa_ok($plugin, 'Handel::Checkout::Plugin');
        ok($plugin->{'init_called'});
        ok($plugin->{'register_called'});

        isa_ok($checkout->{'handlers'}->{1}->[0]->[0], 'Handel::TestPlugins::First');
        is(ref $checkout->{'handlers'}->{1}->[0]->[1], 'CODE');
        $checkout->{'handlers'}->{1}->[0]->[1]->($plugin);
        ok($plugin->{'handler_called'});
    };


    ## Load all plugins in two new paths; space seperated
    {
        local $ENV{'HandelPluginPaths'} = 'Handel::TestPlugins Handel::OtherTestPlugins';

        my $checkout = Handel::Checkout->new;
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 2);
        ok(exists $plugins{'Handel::TestPlugins::First'});
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

        foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
            my $plugin = $plugins{$_};

            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'});
            ok($plugin->{'register_called'});
        };
    };


    ## Load all plugins in two new paths; comma seperated
    {
        local $ENV{'HandelPluginPaths'} = 'Handel::TestPlugins, Handel::OtherTestPlugins';

        my $checkout = Handel::Checkout->new;
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        is(scalar keys %plugins, 2);
        ok(exists $plugins{'Handel::TestPlugins::First'});
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

        foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second)) {
            my $plugin = $plugins{$_};
            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'});
            ok($plugin->{'register_called'});
        };
    };


    ## Load all plugins in three new paths; comma and space seperated
    {
        local $ENV{'HandelPluginPaths'} = 'Handel::TestPlugins, Handel::OtherTestPlugins Handel::Checkout::Plugin';

        my $checkout = Handel::Checkout->new;
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 3);
        ok(exists $plugins{'Handel::TestPlugins::First'});
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

        foreach (qw(Handel::TestPlugins::First Handel::OtherTestPlugins::Second Handel::Checkout::Plugin::TestPlugin)) {
            my $plugin = $plugins{$_};
            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'});
            ok($plugin->{'register_called'});
        };
    };


    ## Load all plugins in an additional path
    {
        local $ENV{'HandelAddPluginPaths'} = 'Handel::OtherTestPlugins';

        my $checkout = Handel::Checkout->new;
        my %plugins = map { ref $_ => $_ } $checkout->plugins;

        ok(scalar keys %plugins >= 2);
        ok(exists $plugins{'Handel::Checkout::Plugin::TestPlugin'});
        ok(exists $plugins{'Handel::OtherTestPlugins::Second'});
        ok(!exists $plugins{'Handel::TestPlugins::First'});
        ok(!exists $plugins{'Handel::Checkout::Plugin::TestBogusPlugin'});

        foreach (qw(Handel::OtherTestPlugins::Second Handel::Checkout::Plugin::TestPlugin)) {
            my $plugin = $plugins{$_};
            isa_ok($plugin, 'Handel::Checkout::Plugin');
            ok($plugin->{'init_called'});
            ok($plugin->{'register_called'});
        };
    };
};