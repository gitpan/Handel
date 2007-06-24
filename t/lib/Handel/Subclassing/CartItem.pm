# $Id: CartItem.pm 1915 2007-06-24 15:35:46Z claco $
package Handel::Subclassing::CartItem;
use strict;
use warnings;
use base qw/Handel::Cart::Item/;

__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->create_accessors;

1;
