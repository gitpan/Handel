# $Id: Item.pm 1314 2006-07-10 00:29:55Z claco $
package Handel::Order::Item;
use strict;
use warnings;

BEGIN {
    use Handel;
    use Handel::Constraints qw(:all);
    use Handel::Currency;
    use Handel::L10N qw(translate);

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

    my $self = bless {
        result => $class->storage->schema_instance->resultset($class->storage->schema_source)->create($data),
        autoupdate => $class->storage->autoupdate
    }, $class;

    return $self;
};

1;
__END__

=head1 NAME

Handel::Order::Item - Module representing an individual order line item

=head1 SYNOPSIS

    my $order = Handel::Order->new({
        id => '12345678-9098-7654-322-345678909876'
    });

    my $iterator = $order->items;
    while (my $item = $iterator->next) {
        print $item->sku;
        print $item->price;
        print $item->total;
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

This is a lazy operation. No actual item record is created until the item object
is passed into the C<add> method of a C<Handel::Order> object.

=head1 METHODS

=head2 description

Gets/sets the item description

=head2 id

Gets/sets the item id

=head2 price

Gets/sets the item price

=head2 quantity

Gets/sets the item quantity

=head2 sku

Gets/sets the item sku

=head2 total

Gets/sets the item total

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
