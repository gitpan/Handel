# $Id: Cart.pm 1328 2006-07-12 22:54:56Z claco $
package Handel::Storage::Cart;
use strict;
use warnings;
use Handel::Constants qw/:cart/;
use Handel::Constraints qw/:all/;
use base qw/Handel::Storage/;

__PACKAGE__->setup({
    schema_class   => 'Handel::Cart::Schema',
    schema_source  => 'Carts',
    item_class     => 'Handel::Cart::Item',
    constraints    => {
        id         => {'Check Id'      => \&constraint_uuid},
        shopper    => {'Check Shopper' => \&constraint_uuid},
        type       => {'Check Type'    => \&constraint_cart_type},
        name       => {'Check Name'    => \&constraint_cart_name}
    },
    default_values => {
        id         => __PACKAGE__->can('new_uuid'),
        type       => CART_TYPE_TEMP
    }
});

1;
__END__

=head1 NAME

Handel::Storage::Cart - Default storage configuration for Handel::Cart

=head1 SYNOPSIS

    package Handel::Cart;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->storage_class('Handel::Storage::Cart');

=head1 DESCRIPTION

Handel::Storage::Cart is a subclass of L<Handel::Storage|Handel::Storage> that
contains all of the default settings used by Handel::Cart.

=head1 SEE ALSO

L<Handel::Cart>, L<Handel::Storage>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
