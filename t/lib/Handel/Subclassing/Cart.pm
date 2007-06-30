# $Id: /local/Handel/trunk/t/lib/Handel/Subclassing/Cart.pm 1569 2007-06-24T15:35:46.298350Z claco  $
package Handel::Subclassing::Cart;
use strict;
use warnings;
use base qw/Handel::Cart/;

__PACKAGE__->item_class('Handel::Subclassing::CartItem');
__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->create_accessors;

1;
