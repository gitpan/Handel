# $Id: Cart.pm 1300 2006-07-08 01:12:16Z claco $
package Handel::Subclassing::Cart;
use strict;
use warnings;
use base 'Handel::Cart';

__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->storage->item_class('Handel::Subclassing::CartItem');
__PACKAGE__->create_accessors;

1;
