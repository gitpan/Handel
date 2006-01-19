# $Id: OrdersCart.pm 1050 2006-01-05 01:34:35Z claco $
package Handel::Subclassing::OrdersCart;
use strict;
use warnings;
use base 'Handel::Cart';

sub load {
    my ($self, $filter, $wantiterator)  = @_;

    $Handel::Subclassing::OrdersCart::Loads++;

    return $self->SUPER::load($filter, $wantiterator);
};

1;
