# $Id: Item.pm 1335 2006-07-15 02:43:12Z claco $
package Handel::Order::Item;
use strict;
use warnings;

BEGIN {
    use Handel;
    use Handel::Constraints qw/:all/;
    use Handel::Currency;
    use Handel::L10N qw/translate/;

    use base qw/Handel::Base/;
    __PACKAGE__->storage({
        schema_class     => 'Handel::Order::Schema',
        schema_source    => 'Items',
        currency_columns => [qw/price total/],
        constraints      => {
            quantity     => {'Check Quantity' => \&constraint_quantity},
            price        => {'Check Price'    => \&constraint_price},
            total        => {'Check Total'    => \&constraint_price},
            id           => {'Check Id'       => \&constraint_uuid},
            orderid      => {'Check Order Id' => \&constraint_uuid}
        },
        default_values   => {
            id           => __PACKAGE__->storage_class->can('new_uuid'),
            price        => 0,
            quantity     => 1,
            total        => 0
        }
    });
    __PACKAGE__->create_accessors;
};

sub new {
    my ($class, $data) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless
            ref($data) eq 'HASH';

    my $result = $class->storage->schema_instance->resultset($class->storage->schema_source)->create($data);
    return $class->create_result($result);
};

1;
__END__

=head1 NAME

Handel::Order::Item - Module representing an individual order line item

=head1 SYNOPSIS

    use Handel::Order;
    
    my $order = Handel::Order->new({
        id => '12345678-9098-7654-322-345678909876'
    });
    
    my $iterator = $order->items;
    while (my $item = $iterator->next) {
        print $item->sku;
        print $item->price;
        print $item->total;
    };

=head1 DESCRIPTION

Handel::Order::Item is used in two main ways. First, you can create or edit
order items individually:

    use Handel::Order::Item;
    
    my $item = Handel::Order::Item->new({
        cart => '11111111-1111-1111-1111-111111111111',
        sku => '1234',
        price => 1.23,
        quantity => 1
    });

As a general rule, you probably want to add/edit items using the order objects
C<items> and C<add> methods below instead.

Second, the C<items> method of any valid Handel::Order object returns a
collection of Handel::Order::Item objects:

    my @items = $order->items;
    foreach (@items) {
        print $_->sku;
    };

=head1 CONSTRUCTOR

=head2 new

You can create a new C<Handel::Order::Item> object by calling the C<new> method:

    my $item = Handel::Order::Item->new({
        sku => '1234',
        price => 1.23,
        quantity => 1,
        total => 1.23
    });
    
    $item->quantity(2);
    
    print $item->total;

=head1 COLUMNS

The following methods are mapped to columns in the default order schema.
These methods may or may not be available in any subclasses, or in situations
where a custom schema is being used that has different column names.

=head2 id

Returns the id of the current order item.

    print $item->id;

See L<Handel::Schema::Order::Item/id> for more information about this column.

=head2 orderid

Gets/sets the id of the order this item belongs to.

    $item->order('11111111-1111-1111-1111-111111111111');
    print $item->order;

See L<Handel::Schema::Order::Item/cart> for more information about this column.

=head2 sku

=over

=item Arguments: $sku

=back

Gets/sets the sku (stock keeping unit/part number) for the order item.

    $item->sku('ABC123');
    print $item->sku;

See L<Handel::Schema::Order::Item/sku> for more information about this column.

=head2 quantity

=over

=item Arguments: $quantity

=back

Gets/sets the quantity, or the number of this item being purchased.

    $item->quantity(3);
    print $item->quantity;

By default, the value supplied will be checked against
L<Handel::Constraints/constraint_quantity> to verify it is within the valid
range of values.

See L<Handel::Schema::Order::Item/quantity> for more information about this
column.

=head2 price

=over

=item Arguments: $price

=back

Gets/sets the price for the order item. The price is returned as a stringified
L<Handel::Currency|Handel::Currency> object.

    $item->price(12.95);
    print $item->price;
    print $item->price->format;


See L<Handel::Schema::Order::Item/price> for more information about this column.

=head2 total

Gets/sets the total price for the order item as a stringified
L<Handel::Currency|Handel::Currency> object.

    $item->total(12.95);
    print $item->total;
    print $item->total->format;

See L<Handel::Schema::Order::Item/total> for more information about this column.

=head2 description

=over

=item Arguments: $description

=back

Gets/sets the description for the current order item.

    $item->description('Best Item Ever');
    print $item->description;

See L<Handel::Schema::Order::Item/description> for more information about this
column.

=head1 SEE ALSO

L<Handel::Order>, L<Handel::Schema::Order::Item>, L<Handel::Currency>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
