# $Id: OrdersCart.pm 1409 2006-09-09 21:16:54Z claco $
package Handel::Subclassing::OrdersCart;
use strict;
use warnings;
use base qw/Handel::Cart/;

sub search {
    my ($self, $filter, $wantiterator)  = @_;

    $Handel::Subclassing::OrdersCart::Searches++;

    return $self->SUPER::search($filter, $wantiterator);
};

1;
