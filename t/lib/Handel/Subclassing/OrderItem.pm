# $Id: /local/Handel/trunk/t/lib/Handel/Subclassing/OrderItem.pm 1569 2007-06-24T15:35:46.298350Z claco  $
package Handel::Subclassing::OrderItem;
use strict;
use warnings;
use base qw/Handel::Order::Item/;

__PACKAGE__->storage->add_columns('custom');
__PACKAGE__->create_accessors;

1;
