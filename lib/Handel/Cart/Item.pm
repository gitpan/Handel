# $Id: Item.pm 1314 2006-07-10 00:29:55Z claco $
package Handel::Cart::Item;
use strict;
use warnings;

BEGIN {
    use Handel;
    use Handel::Constraints qw(:all);
    use Handel::L10N qw(translate);

    use base qw/Handel::Base/;
    __PACKAGE__->storage({
        schema_class     => 'Handel::Cart::Schema',
        schema_source    => 'Items',
        currency_columns => [qw/price/],
        constraints      => {
            quantity     => {'Check Quantity' => \&constraint_quantity},
            price        => {'Check Price'    => \&constraint_price},
            id           => {'Check Id'       => \&constraint_uuid},
            cart         => {'Check Cart'     => \&constraint_uuid}
        },
        default_values   => {
            id           => __PACKAGE__->storage_class->can('new_uuid'),
            price        => 0,
            quantity     => 1
        }
    });
    __PACKAGE__->create_accessors;
};

sub new {
    my ($class, $data) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless
            ref($data) eq 'HASH';

    my $self = bless {
        result => $class->storage->schema_instance->resultset($class->storage->schema_source)->create($data),
        autoupdate => $class->storage->autoupdate
    }, $class;

    return $self;
};

sub total {
    my $self = shift;
    return $self->storage->currency_class->new($self->quantity * $self->price);
};

1;
__END__

=head1 NAME

Handel::Cart::Item - Module representing an individual shopping cart line item

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

=head2 new

You can create a new C<Handel::Cart::Item> object by calling the C<new> method:

    my $item = Handel::Cart::Item->new({
        sku => '1234',
        price => 1.23,
        quantity => 1
    });

    $item->quantity(2);

    print $item->total;

This is a lazy operation. No actual item record is created until the item object
is passed into the C<add> method of a C<Handel::Cart> object.

=head1 METHODS

=head2 sku

Returns or sets the sku (stock keeping unit/part number) for the cart item.

=head2 quantity

Returns or sets the quantity the cart item.

=head2 price

Returns or sets the price for the cart item.

Starting in version C<0.12>, price now returns a stringified
C<Handel::Currency> object. This can be used to format the price,
and convert its value from on currency to another.

=head2 total

Returns the total price for the cart item. This is really just
quantity*total and is provided for convenience.

Starting in version C<0.12>, subtotal now returns a stringified
C<Handel::Currency> object. This can be used to format the price,
and convert its value from on currency to another.

=head2 description

Returns or sets the description for the cart item.

=head1 SEE ALSO

L<Handel::Cart>, L<Handel::Currency>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/





