# $Id: ReadFromStash.pm 1915 2007-06-24 15:35:46Z claco $
package Handel::TestPipeline::ReadFromStash;
use strict;
use warnings;
use base 'Handel::Checkout::Plugin';
use Handel::Constants qw(:checkout);

sub register {
    my ($self, $ctx) = @_;

    $ctx->add_handler(CHECKOUT_PHASE_DELIVER, \&handler);
};

sub handler {
    my ($self, $ctx) = @_;

    $self->{'ReadFromStash'} = $ctx->stash->{'WriteToStash'};

    return CHECKOUT_HANDLER_OK;
};

1;
