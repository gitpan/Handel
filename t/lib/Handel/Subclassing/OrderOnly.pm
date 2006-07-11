# $Id: OrderOnly.pm 1302 2006-07-08 19:34:03Z claco $
package Handel::Subclassing::OrderOnly;
use strict;
use warnings;
use base 'Handel::Order';

__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->create_accessors;

1;
