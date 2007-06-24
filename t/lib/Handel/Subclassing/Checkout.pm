# $Id: Checkout.pm 1915 2007-06-24 15:35:46Z claco $
package Handel::Subclassing::Checkout;
use strict;
use warnings;
use base qw/Handel::Checkout/;

__PACKAGE__->order_class('Handel::Subclassing::Order');

1;
