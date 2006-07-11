# $Id: OrderCart.pm 1302 2006-07-08 19:34:03Z claco $
package Handel::Subclassing::OrderCart;
use strict;
use warnings;
use base 'Handel::Order';

__PACKAGE__->storage->cart_class('Handel::Subclassing::OrdersCart');
__PACKAGE__->create_accessors;

1;
