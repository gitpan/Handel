# $Id: /local/Handel/trunk/t/lib/Handel/Subclassing/Checkout.pm 1569 2007-06-24T15:35:46.298350Z claco  $
package Handel::Subclassing::Checkout;
use strict;
use warnings;
use base qw/Handel::Checkout/;

__PACKAGE__->order_class('Handel::Subclassing::Order');

1;
