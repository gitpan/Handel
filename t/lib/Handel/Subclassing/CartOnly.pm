# $Id: CartOnly.pm 897 2005-10-06 01:36:16Z claco $
package Handel::Subclassing::CartOnly;
use strict;
use warnings;
use base 'Handel::Cart';

__PACKAGE__->add_columns('custom');

1;