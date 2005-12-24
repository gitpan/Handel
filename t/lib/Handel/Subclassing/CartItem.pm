# $Id: CartItem.pm 1043 2005-12-24 03:40:20Z claco $
package Handel::Subclassing::CartItem;
use strict;
use warnings;
use base 'Handel::Cart::Item';

__PACKAGE__->add_columns('custom');

1;
