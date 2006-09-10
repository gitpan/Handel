# $Id: CartItem.pm 1409 2006-09-09 21:16:54Z claco $
package Handel::Subclassing::CartItem;
use strict;
use warnings;
use base qw/Handel::Cart::Item/;

__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->create_accessors;

1;
