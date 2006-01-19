# $Id: OrderCart.pm 1050 2006-01-05 01:34:35Z claco $
package Handel::Subclassing::OrderCart;
use strict;
use warnings;
use base 'Handel::Order';

__PACKAGE__->cart_class('Handel::Subclassing::OrdersCart');

1;
