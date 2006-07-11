# $Id: Base3.pm 1267 2006-06-30 02:05:44Z claco $
package Handel::Subclassing::Base3;
use strict;
use warnings;
use base qw/Handel::Subclassing::Base1/;

__PACKAGE__->storage_class('Handel::Subclassing::Storage');

1;
