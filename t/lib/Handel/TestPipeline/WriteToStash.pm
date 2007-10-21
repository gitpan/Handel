# $Id: /local/CPAN/Handel/trunk/t/lib/Handel/TestPipeline/WriteToStash.pm 1916 2007-06-24T15:35:46.298350Z claco  $
package Handel::TestPipeline::WriteToStash;
use strict;
use warnings;
use base 'Handel::Checkout::Plugin';
use Handel::Constants qw(:checkout);

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
