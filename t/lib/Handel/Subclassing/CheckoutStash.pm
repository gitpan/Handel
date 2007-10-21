# $Id: /local/CPAN/Handel/trunk/t/lib/Handel/Subclassing/CheckoutStash.pm 1916 2007-06-24T15:35:46.298350Z claco  $
package Handel::Subclassing::CheckoutStash;
use strict;
use warnings;
use base qw/Handel::Checkout/;

__PACKAGE__->stash_class('Handel::Subclassing::Stash');

1;
