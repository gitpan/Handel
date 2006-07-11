# $Id: Order.pm 1305 2006-07-08 19:38:24Z claco $
package Handel::Storage::Order;
use strict;
use warnings;
use Handel::Constants qw/:order/;
use Handel::Constraints qw/:all/;
use base qw/Handel::Storage/;

__PACKAGE__->setup({
    schema_class   => 'Handel::Order::Schema',
    schema_source  => 'Orders',
    item_class     => 'Handel::Order::Item',
    cart_class     => 'Handel::Cart',
    constraints    => {
        id       => {'Check Id'       => \&constraint_uuid},
        shopper  => {'Check Shopper'  => \&constraint_uuid},
        type     => {'Check Type'     => \&constraint_order_type},
        shipping => {'Check Shopping' => \&constraint_price},
        handling => {'Check Handling' => \&constraint_price},
        subtotal => {'Check Subtotal' => \&constraint_price},
        tax      => {'Check Tax'      => \&constraint_price},
        total    => {'Check Total'    => \&constraint_price}
    },
    currency_columns => [qw/shipping handling subtotal tax total/],
    default_values => {
        id         => __PACKAGE__->can('new_uuid'),
        type       => ORDER_TYPE_TEMP,
        shipping => 0,
        handling => 0,
        subtotal => 0,
        tax      => 0,
        total    => 0
    }
});

1;
__END__

-head1 NAME

Handel::Storage::Order - Default storage configuration for Handel::Order

=head1 SYNOPSIS

    package Handel::Order;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->storage_class('Handel::Storage::Order');

=head1 DESCRIPTION

Handel::Storage::Order is a subclass of L<Handel::Storage|Handel::Storage> that
contains all of the default settings used by Handel::Order.

=head1 SEE ALSO

L<Handel::Order>, L<Handel::Storage>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
