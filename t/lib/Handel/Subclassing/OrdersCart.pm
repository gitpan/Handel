# $Id: OrdersCart.pm 1355 2006-08-07 01:51:41Z claco $
package Handel::Subclassing::OrdersCart;
use strict;
use warnings;
use base 'Handel::Cart';

sub search {
    my ($self, $filter, $wantiterator)  = @_;

    $Handel::Subclassing::OrdersCart::Searches++;

    return $self->SUPER::search($filter, $wantiterator);
};

1;
