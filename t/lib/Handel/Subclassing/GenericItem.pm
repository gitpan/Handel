# $Id: /local/Handel/trunk/t/lib/Handel/Subclassing/GenericItem.pm 1569 2007-06-24T15:35:46.298350Z claco  $
package Handel::Subclassing::GenericItem;
use strict;
use warnings;
use base qw/Handel::Base/;
__PACKAGE__->storage_class('Handel::Storage');
__PACKAGE__->storage->_columns([qw/a b c/]);
__PACKAGE__->storage->_primary_columns([qw/a/]);

1;
