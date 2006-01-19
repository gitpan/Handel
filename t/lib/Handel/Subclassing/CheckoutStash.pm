# $Id: CheckoutStash.pm 1076 2006-01-19 02:00:55Z claco $
package Handel::Subclassing::CheckoutStash;
use strict;
use warnings;
use base 'Handel::Checkout';

__PACKAGE__->stash_class('Handel::Subclassing::Stash');

1;
