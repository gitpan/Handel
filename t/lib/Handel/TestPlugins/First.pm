# $Id: First.pm 577 2005-07-09 02:23:55Z claco $
package Handel::TestPlugins::First;
use strict;
use warnings;
use base 'Handel::Checkout::Plugin';
use Handel::Constants qw(:checkout);

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

    return CHECKOUT_STATUS_OK;
};

1;