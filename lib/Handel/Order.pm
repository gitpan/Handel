# $Id: Order.pm 1314 2006-07-10 00:29:55Z claco $
package Handel::Order;
use strict;
use warnings;

BEGIN {
    use Handel;
    use Handel::Checkout;
    use Handel::Constants qw/:checkout :returnas :order/;
    use Handel::Constraints qw/:all/;
    use Handel::Currency;
    use Handel::L10N qw/translate/;
    use Scalar::Util qw/blessed/;

    use base qw/Handel::Base/;
    __PACKAGE__->storage_class('Handel::Storage::Order');
    __PACKAGE__->mk_group_accessors('inherited', qw/ccn cctype ccm ccy ccvn ccname ccissuenumber ccstartdate ccenddate/);
    __PACKAGE__->create_accessors;
};

sub new {
    my ($class, $data, $process) = @_;

    throw Handel::Exception::Argument(
        -details => translate('Param 1 is not a HASH reference') . '.') unless
            ref($data) eq 'HASH';

    my $cart = delete $data->{'cart'};
    my $is_uuid = constraint_uuid($cart);

    if (defined $cart) {
        throw Handel::Exception::Argument( -details =>
          translate(
              'Cart reference is not a HASH reference or Handel::Cart') . '.') unless
                  (ref($cart) eq 'HASH' or (blessed($cart) && $cart->isa('Handel::Cart')) or $is_uuid);

        if (ref $cart eq 'HASH') {
            $cart = $class->storage->cart_class->load($cart)->first;

            throw Handel::Exception::Order( -details =>
                translate(
                    'Could not find a cart matching the supplied search criteria') . '.') unless $cart;
        } elsif ($is_uuid) {
            $cart = $class->storage->cart_class->load({id => $cart})->first;

            throw Handel::Exception::Order( -details =>
                translate(
                    'Could not find a cart matching the supplied search criteria') . '.') unless $cart;
        };

        throw Handel::Exception::Order( -details =>
            translate(
                'Could not create a new order because the supplied cart is empty') . '.') unless
                    $cart->count > 0;
    };

    if (defined $cart) {
        $data->{'shopper'} = $cart->shopper unless $data->{'shopper'};
    };

    my $order = bless {
        result => $class->storage->schema_instance->resultset($class->storage->schema_source)->create($data),
        autoupdate => $class->storage->autoupdate
    }, ref $class || $class;


    if (defined $cart) {
        $class->copy_cart($order, $cart);
        $class->copy_cart_items($order, $cart);
    };

    if ($process) {
        my $checkout = Handel::Checkout->new;
        $checkout->order($order);

        my $status = $checkout->process([CHECKOUT_PHASE_INITIALIZE]);
        if ($status == CHECKOUT_STATUS_OK) {
            $checkout->order->update;
        } else {
            $order->destroy;
            undef $order;
        };
        undef $checkout;
    };

    return $order;
};

sub copy_cart {
    my ($self, $order, $cart) = @_;

    if ($cart->shopper && !$order->shopper) {
        $order->shopper($cart->shopper);
    };

    $order->subtotal($cart->subtotal);
    $order->update;
};

sub copy_cart_items {
    my ($self, $order, $cart) = @_;
    my %columns = map {$_ => $_} $order->storage->schema_class->source($order->storage->item_class->storage->schema_source)->columns;

    foreach my $item ($cart->items) {
        my %copy;

        foreach ($cart->storage->item_class->storage->schema_class->source($cart->storage->item_class->storage->schema_source)->columns) {
            next if $_ =~ /^(id|cart)$/i;
            next unless (exists $columns{$_});

            $copy{$_} = $item->result->$_;
        };

        $copy{'total'} = $copy{'quantity'}*$copy{'price'};

        $order->result->create_related($order->storage->item_relationship, \%copy);
    };
};

sub add {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
      translate(
          'Param 1 is not a HASH reference, Handel::Cart::Item or Handel::Order::Item') . '.') unless
              (ref($data) eq 'HASH' or $data->isa('Handel::Order::Item') or $data->isa('Handel::Cart::Item'));

    if (ref($data) eq 'HASH') {
        return bless {
            result => $self->result->create_related($self->storage->item_relationship, $data),
            autoupdate => $self->storage->item_class->storage->autoupdate
        }, $self->storage->item_class;
    } else {
        my %copy;

        foreach ($data->result->columns) {
            next if $_ =~ /^(id|orderid|cart)$/i;
            $copy{$_} = $data->result->$_;
        };
        if (blessed($data) && $data->isa('Handel::Cart::Item')) {
            $copy{'total'} = $data->total;
        };

        return bless {
            result => $self->result->create_related($self->storage->item_relationship, \%copy),
            autoupdate => $self->storage->item_class->storage->autoupdate
        }, $self->storage->item_class;
    };
};

sub clear {
    my $self = shift;

    $self->result->delete_related($self->storage->item_relationship);

    return undef;
};

sub count {
    my $self  = shift;

    return $self->result->count_related($self->storage->item_relationship) || 0;
};

sub delete {
    my ($self, $filter) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless
            ref($filter) eq 'HASH';

    $filter = $self->storage->_migrate_wildcards($filter);

    return $self->result->delete_related($self->storage->item_relationship, $filter);
};

sub destroy {
    my ($self, $filter) = @_;

    if (ref $self) {
        $self->result->delete;
    } else {
        throw Handel::Exception::Argument( -details =>
            translate('Param 1 is not a HASH reference') . '.') unless
                ref($filter) eq 'HASH';

        $filter = $self->storage->_migrate_wildcards($filter);

        $self->storage->schema_instance->resultset($self->storage->schema_source)->search($filter)->delete_all;
    };

    return;
};

sub items {
    my ($self, $filter) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless(
            ref($filter) eq 'HASH' or !$filter);

    $filter = $self->storage->_migrate_wildcards($filter);

    if (wantarray) {
        my @items = $self->result->search_related($self->storage->item_relationship, $filter)->all;

        return map {bless {result => $_, autoupdate => $self->storage->item_class->storage->autoupdate}, $self->storage->item_class} @items;
    } else {
        my $iterator = $self->result->search_related_rs($self->storage->item_relationship, $filter);
        $iterator->result_class($self->storage->item_class);

        return $iterator;
    };
};

sub load {
    my ($class, $filter) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless(
            ref($filter) eq 'HASH' or !$filter);

    $filter = $class->storage->_migrate_wildcards($filter);

    if (wantarray) {
        my @carts = $class->storage->schema_instance->resultset($class->storage->schema_source)->search($filter)->all;

        return map {bless {result => $_, autoupdate => $class->storage->autoupdate}, ref $class || $class} @carts;
    } else {
        my $iterator = $class->storage->schema_instance->resultset($class->storage->schema_source)->search_rs($filter);
        $iterator->result_class(ref $class || $class);

        return $iterator;
    };
};

sub reconcile {
    my ($self, $cart) = @_;

    my $is_uuid = constraint_uuid($cart);

    if (defined $cart) {
        throw Handel::Exception::Argument( -details =>
          translate(
              'Cart reference is not a HASH reference or Handel::Cart') . '.') unless
                  (ref($cart) eq 'HASH' or UNIVERSAL::isa($cart, 'Handel::Cart') or $is_uuid);

        if (ref $cart eq 'HASH') {
            $cart = $self->storage->cart_class->load($cart)->first;

            throw Handel::Exception::Order( -details =>
                translate(
                    'Could not find a cart matching the supplied search criteria') . '.') unless $cart;
        } elsif ($is_uuid) {
            $cart = $self->storage->cart_class->load({id => $cart})->first;

            throw Handel::Exception::Order( -details =>
                translate(
                    'Could not find a cart matching the supplied search criteria') . '.') unless $cart;
        };

        throw Handel::Exception::Order( -details =>
            translate(
                'Could not create a new order because the supplied cart is empty') . '.') unless
                    $cart->count > 0;
    };

    if ($self->subtotal != $cart->subtotal || $self->count != $cart->count) {
        $self->clear;
        $self->copy_cart($self, $cart);
        $self->copy_cart_items($self, $cart);
    };
};

1;
__END__

=head1 NAME

Handel::Order - Module for maintaining order contents

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

=head1 DESCRIPTION

C<Handel::Order> is a component for maintaining simple order records.

While C<Handel::Order> subclasses L<Class::DBI>, it is strongly recommended that
you not use its methods unless it's absolutely necessary. Stick to the
documented methods here and you'll be safe should I decide to implement some
other data access mechanism. :-)

=head1 CONSTRUCTOR

There are three ways to create a new order object. You can either pass a hashref
into C<new> containing all the required values needed to create a new order
record or pass a hashref into C<load> containing the search criteria to use
to load an existing order or set of orders.

B<BREAKING API CHANGE:> Starting in version 0.17_04, new no longer automatically
creates a checkout process for C<CHECKOUT_PHASE_INITIALIZE>. The C<$noprocess>
parameter has been renamed to C<$process>. The have the new order automatically
run a checkout process, set $process to 1.

B<NOTE:> Starting in version 0.17_02, the cart is no longer required! You can
create an order record that isn't associated with a current cart.

B<NOTE:> As of version 0.17_02, Order::subtotal and Order::Item:: total are
calculated once B<only> when creating an order from an existing cart. After that
order is created, any changes to items price/wuantity/totals and the orders subtotals
must be calculated manually and put into the database by the user though their methods.

If the cart key is passed, a new order record will be created from the specified
carts contents. The cart key can be a cart id (uuid), a cart object, or a has reference
contain the search criteria to load matching carts.

=over

=item C<Handel::Order-E<gt>new(\%data [, $process])>

    my $order = Handel::Order->new({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        id => '111111111-2222-3333-4444-555566667777',
        cart => $cartobject
    });

    my $order = Handel::Order->new({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        id => '111111111-2222-3333-4444-555566667777',
        cart => '11112222-3333-4444-5555-666677778888'
    });

    my $order = Handel::Order->new({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        id => '111111111-2222-3333-4444-555566667777',
        cart => {
            id => '11112222-3333-4444-5555-666677778888',
            type => CART_TYPE_TEMP
        }
    });

=item C<Handel::Order-E<gt>load([\%filter, $wantiterator])>

    my $order = Handel::Order->load({
        id => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });

You can also omit \%filter to load all available orders.

    my @orders = Handel::Order->load();

In scalar context C<load> returns a C<Handel::Order> object if there is a single
result, or a L<Handel::Iterator> object if there are multiple results. You can
force C<load> to always return an iterator even if only one cart exists by
setting the C<$wantiterator> parameter to C<RETURNAS_ITERATOR>.

    my $iterator = Handel::Order->load(undef, RETURNAS_ITERATOR);
    while (my $item = $iterator->next) {
        print $item->sku;
    };

See L<Handel::Constants> for the available C<RETURNAS> options.

A C<Handel::Exception::Argument> exception is thrown if the first parameter is
not a hashref.

=back

=head1 METHODS

=head2 add(\%data)

You can add items to the order by supplying a hashref containing the
required name/values or by passing in a newly create Handel::Order::Item
object. If successful, C<add> will return a L<Handel::Order::Item> object
reference.

Yes, I know. Why a hashref and not just a hash? So I can add new params
later if need be. Oh yeah, and "Because I Can". :-P

=over

=item C<$cart-E<gt>add(\%data)>

    my $item = $cart->add({
        shopper  => '10020400-E260-11CF-AE68-00AA004A34D5',
        sku      => 'SKU1234',
        quantity => 1,
        price    => 1.25
    });

=item C<$cart-E<gt>add($object)>

    my $item = Handel::Cart::Item->new({
        sku      => 'SKU1234',
        quantity => 1,
        price    => 1.25
    });
    ...
    $cart->add($item);

A C<Handel::Exception::Argument> exception is thrown if the first parameter
isn't a hashref or a C<Handel::Cart::Item> object.

=back

=head2 clear

This method removes all items from the current cart object.

    $cart->clear;

=head2 copy_cart

When creating a new order from an existing cart, C<copy_cart> will be called to
copy the carts contents into the new order object. If you are using custom cart
or order subclasses, the default copy_cart will only copy the fields declared in
Handel::Cart, ignoring any custom fields you may add.

To fix this, simply subclass Handel::Order and override copy_cart. As its
parameters, it will receive the order and cart objects.

    package CustomOrder;
    use base 'Handel::Order';

    sub copy_cart {
        my ($self, $order, $cart) = @_;

        # copy stock fields
        $self->SUPER::copy_cart($order, $cart);

        # now catch the custom ones
        $order->customfield($cart->customfield);
    };

=head2 copy_cart_items

When creating a new order from an existing cart, C<copy_cart_items> will be
called to copy the cart items into the new order object items. If you are using
custom cart or order subclasses, the default copy_cart_item will only copy the
fields declared in Handel::Cart::Item, ignoring any custom fields you may add.

To fix this, simply subclass Handel::Order and override copy_cart. As its
parameters, it will receive the order and cart objects.

    package CustomOrder;
    use base 'Handel::Order';

    __PACKAGE__->cart_class('CustomCart');

    sub copy_cart_items {
        my ($self, $order, $cart) = @_;
        my $items = $cart->items(undef, RETURNAS_ITERATOR);

        while (my $item = $items->next) {
            my %copy;

            foreach (CustomCart::Item->columns) {
                next if $_ =~ /^(id|cart)$/i;
                $copy{$_} = $item->$_;
            };

            $copy{'id'} = $self->uuid unless constraint_uuid($copy{'id'});
            $copy{'orderid'} = $order->id;
            $copy{'total'} = $copy{'quantity'}*$copy{'price'};

            $order->add_to__items(\%copy);
        };
    };

=head2 delete(\%filter)

This method deletes the order item(s) matching the supplied filter values and
returns the number of items deleted.

    if ( $cart->delete({id => '8D4B0BE1-C02E-11D2-A33D-00A0C94B8D0E'}) ) {
        print 'Item deleted';
    };

=head2 destroy(\%filter)

When called used as an instance method, this will delete all items from the
current cart instance and delete the cart container. C<filter> will be ignored.

When called as a package method, this will delete all carts matching C<filter>.
A Handel::Exception::Argument exception will be thrown is C<filter> is not a
HASH reference.

=head2 cart_class($orderclass)

Gets/Sets the name of the class to use when loading existing cart into the
new order. By default, it loads carts using Handel::Cart. While you can set this
directly in your application, it's best to set it in a custom subclass of
Handel::Order.

    package CustomOrder;
    use base 'Handel::Order';
    __PACKAGE__->cart_class('CustomCart');

=head2 item_class($classname)

Gets/Sets the name of the class to be used when returning or creating order items.
While you can set this directly in your application, it's best to set it
in a custom subclass of Handel::Order.

    package CustomOrder;
    use strict;
    use warnings;
    use base 'Handel::Order';

    __PACKAGE__->item_class('CustomOrder::CustomItem';

    1;

=head2 items([\%filter, [$wantiterator])

You can retrieve all or some of the items contained in the order via the C<items>
method. In a scalar context, items returns an iterator object which can be used
to cycle through items one at a time. In list context, it will return an array
containing all items.

    my $iterator = $order->items;
    while (my $item = $iterator->next) {
        print $item->sku;
    };

    my @items = $order->items;
    ...
    dosomething(\@items);

When filtering the items in the order in scalar context, a
C<Handel::Order::Item> object will be returned if there is only one result. If
there are multiple results, a Handel::Iterator object will be returned
instead. You can force C<items> to always return a C<Handel::Iterator> object
even if only one item exists by setting the $wantiterator parameter to
C<RETURNAS_ITERATOR>.

    my $item = $order->items({sku => 'SKU1234'}, RETURNAS_ITERATOR);
    if ($item->isa('Handel::Order::Item)) {
        print $item->sku;
    } else {
        while ($item->next) {
            print $_->sku;
        };
    };

See the C<RETURNAS> constants in L<Handel::Constants> for other options.

In list context, filtered items return an array of items just as when items is
called without a filter specified.

    my @items - $order->items((sku -> 'SKU1%'});

A C<Handel::Exception::Argument> exception is thrown if parameter one isn't a
hashref or undef.

=head2 reconcile($cart)

This method copies the specified carts items into the order only if the item
count or the subtotal differ.

The cart key can be a cart id (uuid), a cart object, or a hash reference
contain the search criteria to load matching carts.

=head2 billtofirstname

Gets/sets the bill to first name

=head2 billtolastname

Gets/sets the bill to last name

=head2 billtoaddress1

Gets/sets the bill to address line 1

=head2 billtoaddress2

Gets/sets the bill to address line 2

=head2 billtoaddress3

Gets/sets the bill to address line 3

=head2 billtocity

Gets/sets the bill to city

=head2 billtostate

Gets/sets the bill to state/province

=head2 billtozip

Gets/sets the bill to zip/postal code

=head2 billtocountry

Gets/sets the bill to country

=head2 billtodayphone

Gets/sets the bill to day phone number

=head2 billtonightphone

Gets/sets the bill to night phone number

=head2 billtofax

Gets/sets the bill to fax number

=head2 billtoemail

Gets/sets the bill to email address

=head2 ccn*

Gets/sets the credit cart number.

B<NOTE:> This field is stored in memory for the life of the order instance and
is not a real database field.

=head2 cctype*

Gets/sets the credit cart type.

B<NOTE:> This field is stored in memory for the life of the order instance and
is not a real database field.

=head2 ccm*

Gets/sets the credit cart expiration month.

B<NOTE:> This field is stored in memory for the life of the order instance and
is not a real database field.

=head2 ccy*

Gets/sets the credit cart expiration year.

B<NOTE:> This field is stored in memory for the life of the order instance and
is not a real database field.

=head2 ccvn*

Gets/sets the credit cart verification number.

B<NOTE:> This field is stored in memory for the life of the order instance and
is not a real database field.

=head2 ccname*

Gets/sets the credit cart holders name as it appears on the card.

B<NOTE:> This field is stored in memory for the life of the order instance and
is not a real database field.

=head2 ccissuenumber*

Gets/sets the credit cart issue number.

B<NOTE:> This field is stored in memory for the life of the order instance and
is not a real database field.

=head2 ccstartdate*

Gets/sets the credit cart start date.

B<NOTE:> This field is stored in memory for the life of the order instance and
is not a real database field.

=head2 ccenddate*

Gets/sets the credit cart end date.

B<NOTE:> This field is stored in memory for the life of the order instance and
is not a real database field.

=head2 comments

Gets/sets the comments for this order

=head2 count

Gets the number of items in the order

=head2 created

Gets/sets the created date of the order

=head2 handling

Gets/sets the handling charge

=head2 id

Gets/sets the record id

=head2 number

Gets/sets the order number

=head2 shipmethod

Gets/sets the shipping method

=head2 shipping

Gets/sets the shipping cost

=head2 shiptosameasbillto

Gets/sets the ship to same as bill to flag. When set, the ship to information
will be copied from the bill to

=head2 shiptofirstname

Gets/sets the ship to first name

=head2 shiptolastname

Gets/sets the ship to last name

=head2 shiptoaddress1

Gets/sets the ship to address line 1

=head2 shiptoaddress2

Gets/sets the ship to address line 2

=head2 shiptoaddress3

Gets/sets the ship to address line 3

=head2 shiptocity

Gets/sets the ship to city

=head2 shiptostate

Gets/sets the ship to state

=head2 shiptozip

Gets/sets the ship to zip/postal code

=head2 shiptocountry

Gets/sets the ship to country

=head2 shiptodayphone

Gets/sets the ship to day phone number

=head2 shiptonightphone

Gets/sets the ship to night phone number

=head2 shiptofax

Gets/sets the ship to fax number

=head2 shiptoemail

Gets/sets the ship to email address

=head2 shopper

Gets/sets the shopper id

=head2 subtotal

Gets/sets the orders subtotal

=head2 tax

Gets/sets the orders tax

=head2 total

Gets/sets the orders total

=head2 type

Gets/sets the order type

=head2 updated

Gets/sets the last updated date of the order

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
