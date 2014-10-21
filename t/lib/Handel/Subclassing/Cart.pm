# $Id: Cart.pm 1043 2005-12-24 03:40:20Z claco $
package Handel::Subclassing::Cart;
use strict;
use warnings;
use base 'Handel::Cart';

__PACKAGE__->add_columns('custom');
__PACKAGE__->item_class('Handel::Subclassing::CartItem');

1;
