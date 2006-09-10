# $Id: OrderCart.pm 1409 2006-09-09 21:16:54Z claco $
package Handel::Subclassing::OrderCart;
use strict;
use warnings;
use base qw/Handel::Order/;

__PACKAGE__->cart_class('Handel::Subclassing::OrdersCart');
__PACKAGE__->create_accessors;

1;
