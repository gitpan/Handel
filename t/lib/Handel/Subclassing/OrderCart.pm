# $Id: /local/CPAN/Handel/t/lib/Handel/Subclassing/OrderCart.pm 1043 2007-06-24T15:35:46.298350Z claco  $
package Handel::Subclassing::OrderCart;
use strict;
use warnings;
use base qw/Handel::Order/;

__PACKAGE__->cart_class('Handel::Subclassing::OrdersCart');
__PACKAGE__->create_accessors;

1;
