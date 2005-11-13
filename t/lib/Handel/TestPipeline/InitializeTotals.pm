# $Id: InitializeTotals.pm 837 2005-09-19 22:56:39Z claco $
package Handel::TestPipeline::InitializeTotals;
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

    if (my $order = $ctx->order) {

        my $subtotal = 0;

        eval {
            my $items = $order->items(undef, RETURNAS_ITERATOR);
            while (my $item = $items->next) {
                $item->total($item->quantity*$item->price);
                $subtotal += $item->total;
            };
            $order->subtotal($subtotal);
        };

        if ($@) {
            $ctx->add_message($@);
            return CHECKOUT_HANDLER_ERROR;
        } else {
            return CHECKOUT_HANDLER_OK;
        };
    } else {
        $ctx->add_message('No order was loaded');

        return CHECKOUT_HANDLER_ERROR;
    };
};

1;