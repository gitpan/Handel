# $Id: Base3.pm 1915 2007-06-24 15:35:46Z claco $
package Handel::Subclassing::Base3;
use strict;
use warnings;
use base qw/Handel::Subclassing::Base1/;

__PACKAGE__->storage_class('Handel::Subclassing::Storage');

1;
