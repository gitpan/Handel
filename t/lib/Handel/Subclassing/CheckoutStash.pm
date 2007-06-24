# $Id: CheckoutStash.pm 1915 2007-06-24 15:35:46Z claco $
package Handel::Subclassing::CheckoutStash;
use strict;
use warnings;
use base qw/Handel::Checkout/;

__PACKAGE__->stash_class('Handel::Subclassing::Stash');

1;
