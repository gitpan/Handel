package Handel::Cart::Item;
use strict;
use warnings;

BEGIN {
    use base 'Handel::DBI';
    use Handel::Constraints qw(:all);
};

__PACKAGE__->table('cart_items');
__PACKAGE__->autoupdate(0);
__PACKAGE__->iterator_class('Handel::Iterator');
__PACKAGE__->columns( All => qw(id cart sku quantity price description) );
__PACKAGE__->columns( Essential => qw(id cart sku quantity price description) );
__PACKAGE__->add_constraint( 'quantity', quantity => \&constraint_quantity );
__PACKAGE__->add_constraint( 'price',    price    => \&constraint_price );
__PACKAGE__->add_constraint( 'id',       id       => \&constraint_uuid );
__PACKAGE__->add_constraint( 'cart',     cart     => \&constraint_uuid );

sub new {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless
            ref($data) eq 'HASH';

    if (!defined($data->{'id'}) || !constraint_uuid($data->{'id'})) {
        $data->{'id'} = $self->uuid;
    };

    return $self->construct($data);
};

sub total {
    my $self = shift;
    return $self->quantity * $self->price;
};

1;
__END__

=head1 NAME

Handel::Cart::Item - Module representing an indivudal shopping cart line item

=head1 VERSION

    $Id: Item.pm 34 2004-12-31 02:13:03Z claco $

=head1 SYNOPSIS

    use Handel::Cart::Item;

    my $item = Handel::Cart::Item->new({
        sku => '1234',
        price => 1.23,
        quantity => 1
    });

    $cart->add($item);

=head1 DESCRIPTION

C<Handel::Cart::Item> is used in two main ways. First, you can create new line
items and add them to an existing cart object:

    use Handel::Cart::Item;

    my $item = Handel::Cart::Item->new({
        sku => '1234',
        price => 1.23,
        quantity => 1
    });

    $cart->add($item);

Second, the C<items> method of any valid C<Handel::Cart> object returns a
collection of C<Handel::Cart::Item> objects:

    my @items = $cart->items;
    foreach (@items) {
        print $_->sku;
    };

=head1 CONSTRUCTOR

You can create a new C<Handel::Cart::Item> object by call the C<new> method:

    my $item = Handel::Cart::Item->new({
        sku => '1234',
        price => 1.23,
        quantity => 1
    });

This is a lazy operation. No actual item record is created until the item object
is passed into the carts C<add> method.

=head1 METHODS

=head2 C<$item-E<gt>total>

Returns the total price for the cart item. This is really just quantity*total
and is provided for convenience.

=head1 SEE ALSO

L<Handel::Cart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/




