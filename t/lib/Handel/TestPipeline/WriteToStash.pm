# $Id: WriteToStash.pm 709 2005-08-11 01:25:20Z claco $
package Handel::TestPipeline::WriteToStash;
use strict;
use warnings;
use base 'Handel::Checkout::Plugin';
use Handel::Constants qw(:checkout :returnas);

sub register {
    my ($self, $ctx) = @_;

    $ctx->add_handler(CHECKOUT_PHASE_INITIALIZE, \&handler);
};

sub handler {
    my ($self, $ctx) = @_;

    $ctx->stash->{'WriteToStash'} = 'WrittenToStash';

    return CHECKOUT_HANDLER_OK;
};

1;