# $Id: /local/Handel/trunk/t/lib/Handel/Subclassing/Base3.pm 1569 2007-06-24T15:35:46.298350Z claco  $
package Handel::Subclassing::Base3;
use strict;
use warnings;
use base qw/Handel::Subclassing::Base1/;

__PACKAGE__->storage_class('Handel::Subclassing::Storage');

1;
