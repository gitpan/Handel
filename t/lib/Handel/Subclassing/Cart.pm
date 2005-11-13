# $Id: Cart.pm 897 2005-10-06 01:36:16Z claco $
package Handel::Subclassing::Cart;
use strict;
use warnings;
use base 'Handel::Cart';

__PACKAGE__->add_columns('custom');
__PACKAGE__->item_class('Handel::Subclassing::Item');

1;
