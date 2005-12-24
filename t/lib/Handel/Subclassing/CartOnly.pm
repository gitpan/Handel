# $Id: CartOnly.pm 1043 2005-12-24 03:40:20Z claco $
package Handel::Subclassing::CartOnly;
use strict;
use warnings;
use base 'Handel::Cart';

__PACKAGE__->add_columns('custom');

1;