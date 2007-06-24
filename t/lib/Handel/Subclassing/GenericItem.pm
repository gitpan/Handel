# $Id: GenericItem.pm 1915 2007-06-24 15:35:46Z claco $
package Handel::Subclassing::GenericItem;
use strict;
use warnings;
use base qw/Handel::Base/;
__PACKAGE__->storage_class('Handel::Storage');
__PACKAGE__->storage->_columns([qw/a b c/]);
__PACKAGE__->storage->_primary_columns([qw/a/]);

1;
