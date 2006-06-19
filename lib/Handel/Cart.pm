# $Id: Cart.pm 1080 2006-01-19 02:05:22Z claco $
package Handel::Cart;
use strict;
use warnings;

BEGIN {
    use base 'Handel::DBI';
    use Handel::Constants qw(:cart :returnas);
    use Handel::Constraints qw(:all);
    use Handel::Currency;
    use Handel::L10N qw(translate);

    __PACKAGE__->mk_classdata(_item_class => 'Handel::Cart::Item');
};

__PACKAGE__->autoupdate(1);
__PACKAGE__->table('cart');
__PACKAGE__->iterator_class('Handel::Iterator');
__PACKAGE__->columns(All => qw(id shopper type name description));
__PACKAGE__->has_many(_items => 'Handel::Cart::Item', 'cart');
__PACKAGE__->add_constraint('id',      id      => \&constraint_uuid);
__PACKAGE__->add_constraint('shopper', shopper => \&constraint_uuid);
__PACKAGE__->add_constraint('type',    type    => \&constraint_cart_type);

sub new {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument(
        -details => translate('Param 1 is not a HASH reference') . '.') unless
            ref($data) eq 'HASH';

    if (!defined($data->{'id'}) || !constraint_uuid($data->{'id'})) {
        $data->{'id'} = $self->uuid;
    };

    if (!defined($data->{'type'})) {
        $data->{'type'} = CART_TYPE_TEMP;
    };

    if ($data->{'type'} == CART_TYPE_SAVED && !$data->{'name'}) {
        throw Handel::Exception::Constraint(
            -details => translate(
                'Cart name is required when creating a saved cart') . '.');
    };

    return $self->insert($data);
};

sub add {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
      translate(
          'Param 1 is not a HASH reference or Handel::Cart::Item') . '.') unless
              (ref($data) eq 'HASH' or $data->isa('Handel::Cart::Item'));

    if (ref($data) eq 'HASH') {
        if (!defined($data->{'id'}) || !constraint_uuid($data->{'id'})) {
            $data->{'id'} = $self->uuid;
        };

        return $self->add_to__items($data);
    } else {
        my %copy;

        foreach ($data->columns) {
            next if $_ =~ /^(id|cart)$/i;
            $copy{$_} = $data->$_;
        };

        $copy{'id'} = $self->uuid;

        return $self->add_to__items(\%copy);
    };
};

sub clear {
    my $self = shift;

    $self->_items->delete_all;

    return undef;
};

sub count {
    my $self  = shift;

    return $self->_items->count || 0;
};

sub delete {
    my ($self, $filter) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless
            ref($filter) eq 'HASH';

    ## I'd much rather use $self->_items->search_like, but it doesn't work that
    ## way yet. This should be fine as long as :weaken refs works.
    return $self->item_class->search_like(%{$filter},
        cart => $self->id)->delete_all;
};

sub destroy {
    my ($self, $filter) = @_;

    if (ref $self) {
        $self->SUPER::delete;
    } else {
        throw Handel::Exception::Argument( -details =>
            translate('Param 1 is not a HASH reference') . '.') unless
                ref($filter) eq 'HASH';

        my $carts = $self->load($filter, RETURNAS_ITERATOR);
        while (my $cart = $carts->next) {
            $cart->clear;
            $cart->SUPER::delete;
        };
    };

    return;
};

sub item_class {
    my ($class, $item_class) = @_;

    if ($item_class) {
        eval "require $item_class";

        require version;
        my $cdbiver = version->new(Class::DBI->VERSION);

        if ($cdbiver->numify < 3.000008) {
            undef(*_items);
            undef(*add_to__items);
            __PACKAGE__->has_many(_items => $item_class, 'cart');
        } else {
            $class->has_many(_items => $item_class, 'cart');
        };
    } else {
        return $class->_item_class;
    };
};

sub items {
    my ($self, $filter, $wantiterator) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless(
            ref($filter) eq 'HASH' or !$filter);

    $wantiterator ||= RETURNAS_AUTO;
    $filter       ||= {};

    my $wildcard = Handel::DBI::has_wildcard($filter);

    ## If the filter as a wildcard, push it through a fresh search_like since it
    ## doesn't appear to be available within a loaded object.
    if ((wantarray && $wantiterator != RETURNAS_ITERATOR) || $wantiterator == RETURNAS_LIST) {
        my @items = $wildcard ?
            $self->item_class->search_like(%{$filter}, cart => $self->id) :
            $self->_items(%{$filter});

        return @items;
    } elsif ($wantiterator == RETURNAS_ITERATOR) {
        my $iterator = $wildcard ?
            $self->item_class->search_like(%{$filter}, cart => $self->id) :
            $self->_items(%{$filter});

        return $iterator;
    } else {
        my $iterator = $wildcard ?
            $self->item_class->search_like(%{$filter}, cart => $self->id) :
            $self->_items(%{$filter});
        if ($iterator->count == 1 && $wantiterator != RETURNAS_ITERATOR && $wantiterator != RETURNAS_LIST) {
            return $iterator->next;
        } else {
            return $iterator;
        };
    };
};

sub load {
    my ($self, $filter, $wantiterator) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless(
            ref($filter) eq 'HASH' or !$filter);

    $wantiterator ||= RETURNAS_AUTO;

    ## only return array if wantarray and not explicitly asking for an iterator
    ## or we've explicitly asked for a list/array
    if ((wantarray && $wantiterator != RETURNAS_ITERATOR) || $wantiterator == RETURNAS_LIST) {
        my @carts = $filter ? $self->search_like(%{$filter}) :
            $self->retrieve_all;
        return @carts;
    ## return an iterator if explicitly asked for
    } elsif ($wantiterator == RETURNAS_ITERATOR) {
        my $iterator = $filter ?
            $self->search_like(%{$filter}) : $self->retrieve_all;

        return $iterator;
    ## full out auto
    } else {
        my $iterator = $filter ?
            $self->search_like(%{$filter}) : $self->retrieve_all;

        if ($iterator->count == 1 && $wantiterator != RETURNAS_ITERATOR && $wantiterator != RETURNAS_LIST) {
            return $iterator->next;
        } else {
            return $iterator;
        };
    };
};

sub restore {
    my ($self, $data, $mode) = @_;

    $mode ||= CART_MODE_REPLACE;

    throw Handel::Exception::Argument( -details =>
        translate(
            'Param 1 is not a HASH reference or Handel::Cart') . '.') unless(
                ref($data) eq 'HASH' or $data->isa('Handel::Cart'));

    my @carts = (ref($data) eq 'HASH') ?
        $self->search_like(%{$data}) : $data;

    if ($mode == CART_MODE_REPLACE) {
        $self->clear;

        my $first = $carts[0];
        $self->autoupdate(0);
        $self->name($first->name);
        $self->description($first->description);
        $self->update;
        $self->autoupdate(1);

        foreach (@carts) {
            my $iterator = $_->items(undef, 1);
            while (my $item = $iterator->next) {
                $self->add($item);
            };
        };
    } elsif ($mode == CART_MODE_MERGE) {
        foreach (@carts) {
            my $iterator = $_->items(undef, 1);
            while (my $item = $iterator->next) {
                if (my $exists = $self->items({sku => $item->sku})){
                    $exists->quantity($item->quantity + $exists->quantity);
                    $exists->update;
                } else {
                    $self->add($item);
                };
            };
        };
    } elsif ($mode == CART_MODE_APPEND) {
        foreach (@carts) {
            my $iterator = $_->items(undef, 1);
            while (my $item = $iterator->next) {
                $self->add($item);
            };
        };
    } else {
        return new Handel::Exception::Argument(-text =>
            translate('Unknown restore mode'));
    };
};

sub save {
    $_[0]->type(CART_TYPE_SAVED);

    return undef;
};

sub subtotal {
    my $self     = shift;
    my $it       = $self->items(undef, 1);
    my $subtotal = 0.00;

    while ( my $item = $it->next ) {
        $subtotal += ( $item->total );
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
