# $Id: OrderItem.pm 1302 2006-07-08 19:34:03Z claco $
package Handel::Subclassing::OrderItem;
use strict;
use warnings;
use base 'Handel::Order::Item';

__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->create_accessors;

1;
