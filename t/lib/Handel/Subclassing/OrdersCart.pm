# $Id: /local/CPAN/Handel/trunk/t/lib/Handel/Subclassing/OrdersCart.pm 1916 2007-06-24T15:35:46.298350Z claco  $
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
