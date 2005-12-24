# $Id: Checkout.pm 1043 2005-12-24 03:40:20Z claco $
package Handel::Subclassing::Checkout;
use strict;
use warnings;
use base 'Handel::Checkout';

__PACKAGE__->order_class('Handel::Subclassing::Order');

1;
