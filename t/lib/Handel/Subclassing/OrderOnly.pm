# $Id: OrderOnly.pm 1043 2005-12-24 03:40:20Z claco $
package Handel::Subclassing::OrderOnly;
use strict;
use warnings;
use base 'Handel::Order';

__PACKAGE__->add_columns('custom');

1;
