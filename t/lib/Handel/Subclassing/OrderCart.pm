# $Id: OrderCart.pm 1915 2007-06-24 15:35:46Z claco $
package Handel::Subclassing::OrderCart;
use strict;
use warnings;
use base qw/Handel::Order/;

__PACKAGE__->cart_class('Handel::Subclassing::OrdersCart');
__PACKAGE__->create_accessors;

1;
