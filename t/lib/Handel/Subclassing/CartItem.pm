# $Id: CartItem.pm 1300 2006-07-08 01:12:16Z claco $
package Handel::Subclassing::CartItem;
use strict;
use warnings;
use base 'Handel::Cart::Item';

__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->create_accessors;

1;
