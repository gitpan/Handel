# $Id: Checkout.pm 1409 2006-09-09 21:16:54Z claco $
package Handel::Subclassing::Checkout;
use strict;
use warnings;
use base qw/Handel::Checkout/;

__PACKAGE__->order_class('Handel::Subclassing::Order');

1;
