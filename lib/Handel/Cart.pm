# $Id: Cart.pm 1202 2006-06-04 18:59:10Z claco $
package Handel::Cart;
use strict;
use warnings;

BEGIN {
    use Handel;
    use Handel::Constants qw/:cart :returnas/;
    use Handel::Constraints qw/:all/;
    use Handel::Currency;
    use Handel::L10N qw/translate/;

    use base qw/Handel::Storage/;
    __PACKAGE__->schema_class('Handel::Cart::Schema');
    __PACKAGE__->schema_source('Carts');
    __PACKAGE__->item_class('Handel::Cart::Item');
    __PACKAGE__->setup_column_accessors;

    __PACKAGE__->add_constraint('id',      id      => \&constraint_uuid);
    __PACKAGE__->add_constraint('shopper', shopper => \&constraint_uuid);
    __PACKAGE__->add_constraint('type',    type    => \&constraint_cart_type);
    __PACKAGE__->add_constraint('name',    name    => \&constraint_cart_name);

    __PACKAGE__->default_values({
        id   => \&Handel::Storage::uuid,
        type => CART_TYPE_TEMP
    });
};

sub new {
    my ($class, $data) = @_;
    $class = ref $class || $class;

    throw Handel::Exception::Argument(
        -details => translate('Param 1 is not a HASH reference') . '.') unless
            ref($data) eq 'HASH';

    my $self = bless {
        storage => $class->schema_instance->resultset($class->schema_source)->create($data)
    }, $class;

    return $self;
};

sub add {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
      translate(
          'Param 1 is not a HASH reference or Handel::Cart::Item') . '.') unless
              (ref($data) eq 'HASH' or $data->isa('Handel::Cart::Item'));

    if (ref($data) eq 'HASH') {
        return bless {
            storage => $self->storage->create_related($self->item_relationship, $data)
        }, $self->item_class;
    } else {
        my %copy;

        foreach ($data->storage->columns) {
            next if $_ =~ /^(id|cart)$/i;
            $copy{$_} = $data->storage->$_;
        };

        return bless {
            storage => $self->storage->create_related($self->item_relationship, \%copy)
        }, $self->item_class;
    };
};

sub clear {
    my $self = shift;

    $self->storage->delete_related($self->item_relationship);

    return undef;
};

sub count {
    my $self  = shift;

    return $self->storage->count_related($self->item_relationship) || 0;
};

sub delete {
    my ($self, $filter) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless
            ref($filter) eq 'HASH';

    $filter = $self->_migrate_wildcards($filter);

    return $self->storage->delete_related($self->item_relationship, $filter);
};

sub destroy {
    my ($self, $filter) = @_;

    if (ref $self) {
        $self->storage->delete;
    } else {
        throw Handel::Exception::Argument( -details =>
            translate('Param 1 is not a HASH reference') . '.') unless
                ref($filter) eq 'HASH';

        $filter = $self->_migrate_wildcards($filter);

        $self->schema_instance->resultset($self->schema_source)->search($filter)->delete_all;
    };

    return;
};

sub items {
    my ($self, $filter) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless(
            ref($filter) eq 'HASH' or !$filter);

    $filter = $self->_migrate_wildcards($filter);

    if (wantarray) {
        my @items = $self->storage->search_related($self->item_relationship, $filter)->all;

        return map {bless {storage => $_}, $self->item_class} @items;
    } else {
        my $iterator = $self->storage->search_related_rs($self->item_relationship, $filter);
        $iterator->result_class($self->item_class);

        return $iterator;
    };
};

sub load {
    my ($class, $filter) = @_;
    $class = ref $class || $class;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless(
            ref($filter) eq 'HASH' or !$filter);

    $filter = $class->_migrate_wildcards($filter);

    if (wantarray) {
        my @carts = $class->schema_instance->resultset($class->schema_source)->search($filter)->all;

        return map {bless {storage => $_}, $class} @carts;
    } else {
        my $iterator = $class->schema_instance->resultset($class->schema_source)->search_rs($filter);
        $iterator->result_class($class);

        return $iterator;
    };
};

sub restore {
    my ($self, $data, $mode) = @_;

    $mode ||= CART_MODE_REPLACE;

    throw Handel::Exception::Argument( -details =>
        translate(
            'Param 1 is not a HASH reference or Handel::Cart') . '.') unless(
                ref($data) eq 'HASH' or $data->isa('Handel::Cart'));

    if (ref $data eq 'HASH') {
        $data = $self->_migrate_wildcards($data);
    };

    my @carts = (ref($data) eq 'HASH') ?
        $self->load($data)->all : $data;

    if ($mode == CART_MODE_REPLACE) {
        $self->clear;

        my $first = $carts[0];
        $self->name($first->name);
        $self->description($first->description);

        foreach (@carts) {
            my @items = $_->items->all;
            foreach my $item (@items) {
                $self->add($item);
            };
        };
    } elsif ($mode == CART_MODE_MERGE) {
        foreach (@carts) {
            my @items = $_->items->all;
            foreach my $item (@items) {
                if (my $exists = $self->items({sku => $item->sku})->first){
                    $exists->quantity($item->quantity + $exists->quantity);
                } else {
                    $self->add($item);
                };
            };
        };
    } elsif ($mode == CART_MODE_APPEND) {
        foreach (@carts) {
            my @items = $_->items->all;
            foreach my $item (@items) {
                $self->add($item);
            };
        };
    } else {
        return new Handel::Exception::Argument(-text =>
            translate('Unknown restore mode'));
    };
};

sub save {
    my $self = shift;
    $self->type(CART_TYPE_SAVED);

    return undef;
};

sub subtotal {
    my $self     = shift;
    my $it       = $self->items();
    my $subtotal = 0.00;

    while (my $item = $it->next) {
        $subtotal += ($item->total);
    };

    return Handel::Currency->new($subtotal);
};

1;
__END__

=head1 NAME

Handel::Cart - Module for maintaining shopping cart contents

=head1 SYNOPSIS

    use Handel::Cart;

    my $cart = Handel::Cart->new({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });

    $cart->add({
        sku      => 'SKU1234',
        quantity => 1,
        price    => 1.25
    });

    my $iterator = $cart->items;
    while (my $item = $iterator->next) {
        print $item->sku;
        print $item->price;
        print $item->total;
    };
    $item->subtotal;

=head1 DESCRIPTION

C<Handel::Cart> is quick and dirty component for maintaining simple shopping
cart data.

While C<Handel::Cart> subclasses L<Class::DBI>, it is strongly recommended that
you not use its methods unless it's absolutely necessary. Stick to the
documented methods here and you'll be safe should I decide to implement some
other data access mechanism. :-)

=head1 CONSTRUCTOR

There are two ways to create a new cart object. You can either pass a hashref
into C<new> containing all the required values needed to create a new shopping
cart record or pass a hashref into C<load> containing the search criteria to use
to load an existing shopping cart.

=over

=item C<Handel::Cart-E<gt>new(\%data)>

    my $cart = Handel::Cart->new({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        name    => 'My Shopping Cart'
    });

=item C<Handel::Cart-E<gt>load([\%filter, $wantiterator])>

    my $cart = Handel::Cart->load({
        id => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });

You can also omit \%filter to load all available carts.

    my @carts = Handel::Cart->load();

In scalar context C<load> returns a C<Handel::Cart> object if there is a single
result, or a L<Handel::Iterator> object if there are multiple results. You can
force C<load> to always return an iterator even if only one cart exists by
setting the C<$wantiterator> parameter to C<RETURNAS_ITERATOR>.

    my $iterator = Handel::Cart->load(undef, RETURNAS_ITERATOR);
    while (my $item = $iterator->next) {
        print $item->sku;
    };

See L<Handel::Contstants> for the available C<RETURNAS> options.

A C<Handel::Exception::Argument> exception is thrown if the first parameter is
not a hashref.

=back

=head1 METHODS

=head2 item_class($classname)

Sets the name of the class to be used when returning or creating cart items.
While you can set this directly in your application, it's best to set it
in a custom subclass of Handel::Cart.

    package CustomCart;
    use strict;
    use warnings;
    use base 'Handel::Cart';

    __PACKAGE__->item_class('CustomCart::CustomItem';

    1;

=head2 Adding Cart Items

You can add items to the shopping cart by supplying a hashref containing the
required name/values or by passing in a newly create Handel::Cart::Item
object. If successful, C<add> will return a L<Handel::Cart::Item> object
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

=head2 Fetching Cart Items

You can retrieve all or some of the items contained in the cart via the C<items>
method. In a scalar context, items returns an iterator object which can be used
to cycle through items one at a time. In list context, it will return an array
containing all items.

=over

=item C<$cart-E<gt>items()>

    my $iterator = $cart->items;
    while (my $item = $iterator->next) {
        print $item->sku;
    };

    my @items = $cart->items;
    ...
    dosomething(\@items);

=item C<$cart-E<gt>items(\%filter [, $wantiterator])>

When filtering the items in the shopping cart in scalar context, a
C<Handel::Cart::Item> object will be returned if there is only one result. If
there are multiple results, a Handel::Iterator object will be returned
instead. You can force C<items> to always return a C<Handel::Iterator> object
even if only one item exists by setting the $wantiterator parameter to
C<RETURNAS_ITERATOR>.

    my $item = $cart->items({sku => 'SKU1234'}, RETURNAS_ITERATOR);
    if ($item->isa('Handel::Cart::Item)) {
        print $item->sku;
    } else {
        while ($item->next) {
            print $_->sku;
        };
    };

See the C<RETURNAS> constants in L<Handel::Constants> for other options.

In list context, filtered items return an array of items just as when items is
called without a filter specified.

    my @items - $cart->items((sku -> 'SKU1%'});

A C<Handel::Exception::Argument> exception is thrown if parameter one isn't a
hashref or undef.

=back

=head2 Removing Cart Items

=over

=item C<$cart-E<gt>clear()>

This method removes all items from the current cart object.

    $cart->clear;

=item C<$cart-E<gt>delete(\%filter)>

This method deletes the cart item(s) matching the supplied filter values and
returns the number of items deleted.

    if ( $cart->delete({id => '8D4B0BE1-C02E-11D2-A33D-00A0C94B8D0E'}) ) {
        print 'Item deleted';
    };

=back

=head2 Removing the Entire Cart

=over

=item C<$cart-E<gt>destroy(\%filter)>

=item C<Handel::Cart-E<gt>destroy(\%filter)>

When called used as an instance method, this will delete all items from the
current cart instance and delete the cart container. C<filter> will be ignored.

When called as a package method, this will delete all carts matching C<filter>.
A Handel::Exception::Argument exception will be thrown is C<filter> is not a
HASH reference.

=back

=head2 Saving Your Cart

By default every shopping cart created is considered temporary
(C<CART_TYPE_TEMP>) and could be deleted by cleanup processes at any time after
the defined inactivity period. This could also be considered characteristic of
whether the shopper id is from a temporary part of where it's used, or whether
it is generated and stored within a customer profile assigned during
authentication.

By saving your shopping cart, you are marking it as C<CART_TYPE_SAVED> and it
should be left alone by any cleanup processes and available to that shopper at
any time.

For all intents and purposes, a saved cart is a wishlist. At some point in the
future they may be treated differently.

=over

=item C<$cart-E<gt>save()>

=back

=head2 Restoring A Previously Saved Cart

There are two basic ways to restore a previously saved shopping cart into the
current shopping cart object. You may either pass in a hashref containing the
search criteria of the shopping cart(s) to restore or you can pass in an
existing C<Handel::Cart> object.

=over

=item C<$cart-E<gt>restore(\%search, [$mode])>

=item C<$cart-E<gt>restore($object, [$mode])>

=back

For either method, you may also specify the mode in which the cart should be
restored. $mode can be one of the following:

=over

=item C<CART_MODE_REPLACE>

All items in the current cart will be deleted before the saved cart is restored
into it. This is the default if no mode is specified.

=item C<CART_MODE_MERGE>

If an item with the same SKU exists in both the current cart and the saved cart,
the quantity of each will be added together and applied to the same sku in the
current cart. Any price differences are ignored and we assume that the price in
the current cart is more up to date.

=item C<CART_MODE_APPEND>

All items in the saved cart will be appended to the list of items in the current
cart. No effort will be made to merge items with the same SKU and duplicates
will be ignored.

A C<Handel::Exception::Argument> exception is thrown if the first parameter
isn't a hashref or a C<Handel::Cart> object.

=back

=head2 Misc. Methods

=over

=item C<$cart-E<gt>count()>

Returns the number of items in the cart object.

    my $numitems = $cart->count;

=item C<$cart-E<gt>description([$description])>

Returns/sets the description of the current cart.

=item C<$cart-E<gt>name([$name])>

Returns/set the name of the current cart.

=item C<$cart-E<gt>subtotal()>

Returns the current total price of all the items in the cart object. This is
equivalent to:

    my $iterator = $cart->items;
    while (my $item = $iterator->next) {
        $subtotal += $item->quantity*$item->price;
    };

Starting in version C<0.12>, C<subtotal> now returns a stringified L<Handel::Currency>
object. This can be used to format the price, and hopefully to convert it's currency
to another locale in the future.

=item C<$cart-E<gt>type()>

Returns the type of the current cart. Currently the two types are

=over

=item C<CART_TYPE_TEMP>

The cart is temporary and may be purges during any cleanup process after the
designated amount of inactivity.

=item C<CART_TYPE_SAVED>

The cart should be left untouched by any cleanup process and is available to the
shopper at any time.

=back

=back

=head1 SEE ALSO

L<Handel::Constants>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
