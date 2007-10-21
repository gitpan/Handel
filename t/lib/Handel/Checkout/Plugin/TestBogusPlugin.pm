# $Id: /local/CPAN/Handel/trunk/t/lib/Handel/Checkout/Plugin/TestBogusPlugin.pm 1916 2007-06-24T15:35:46.298350Z claco  $
package Handel::Checkout::Plugin::TestBogusPlugin;
use strict;
use warnings;
use Handel::Constants qw(:checkout);

sub new {

};

sub register {
    my ($self, $ctx) = @_;

    $self->{'register_called'}++;
    $ctx->add_handler(CHECKOUT_PHASE_INITIALIZE, \&handler);
};

sub init {
    my ($self, $ctx) = @_;

    $self->{'init_called'}++;
};

sub setup {
    my ($self, $ctx) = @_;

    $self->{'setup_called'}++;
};

sub teardown {
    my ($self, $ctx) = @_;

    $self->{'teardown_called'}++;
};

sub handler {
    my ($self, $ctx) = @_;

    $self->{'handler_called'}++;
};

1;