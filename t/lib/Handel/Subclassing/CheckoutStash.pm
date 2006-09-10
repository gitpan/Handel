# $Id: CheckoutStash.pm 1409 2006-09-09 21:16:54Z claco $
package Handel::Subclassing::CheckoutStash;
use strict;
use warnings;
use base qw/Handel::Checkout/;

__PACKAGE__->stash_class('Handel::Subclassing::Stash');

1;
