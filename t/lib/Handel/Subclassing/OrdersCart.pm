# $Id: OrdersCart.pm 1915 2007-06-24 15:35:46Z claco $
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
