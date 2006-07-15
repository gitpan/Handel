# $Id: Cart.pm 1335 2006-07-15 02:43:12Z claco $
package Handel::Cart;
use strict;
use warnings;

BEGIN {
    use Handel;
    use Handel::Constants qw/:cart/;
    use Handel::Constraints qw/:all/;
    use Handel::L10N qw/translate/;

    use base qw/Handel::Base/;
    __PACKAGE__->storage_class('Handel::Storage::Cart');
    __PACKAGE__->create_accessors;
};

sub new {
    my ($class, $data) = @_;

    throw Handel::Exception::Argument(
        -details => translate('Param 1 is not a HASH reference') . '.') unless
            ref($data) eq 'HASH';

    my $result = $class->storage->schema_instance->resultset($class->storage->schema_source)->create($data);
    return $class->create_result($result);
};

sub add {
    my ($self, $data) = @_;

    throw Handel::Exception::Argument( -details =>
      translate(
          'Param 1 is not a HASH reference or Handel::Cart::Item') . '.') unless
              (ref($data) eq 'HASH' or $data->isa('Handel::Cart::Item'));

    if (ref($data) eq 'HASH') {
        return $self->storage->item_class->create_result(
            $self->result->create_related($self->storage->item_relationship, $data)
        );
    } else {
        my %copy;

        foreach ($data->result->columns) {
            next if $_ =~ /^(id|cart)$/i;
            $copy{$_} = $data->result->$_;
        };

        return $self->storage->item_class->create_result(
            $self->result->create_related($self->storage->item_relationship, \%copy)
        );
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
        my $result = $self->result->delete;
        if ($result) {
            undef ($self);
        } 
        return $result;
    } else {
        throw Handel::Exception::Argument( -details =>
            translate('Param 1 is not a HASH reference') . '.') unless
                ref($filter) eq 'HASH';

        $filter = $self->storage->_migrate_wildcards($filter);

        return $self->storage->schema_instance->resultset($self->storage->schema_source)->search($filter)->delete_all;
    };

    return;
};

sub items {
    my ($self, $filter) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless(
            ref($filter) eq 'HASH' or !$filter);

    $filter = $self->storage->_migrate_wildcards($filter);

    my $iterator = $self->result->search_related($self->storage->item_relationship, $filter);
    $iterator->result_class($self->storage->item_class);
    
    if (wantarray) {
        return $iterator->all;
    } else {
        return $iterator;
    };
};

sub load {
    my ($class, $filter) = @_;

    throw Handel::Exception::Argument( -details =>
        translate('Param 1 is not a HASH reference') . '.') unless(
            ref($filter) eq 'HASH' or !$filter);

    $filter = $class->storage->_migrate_wildcards($filter);

    my $iterator = $class->storage->schema_instance->resultset($class->storage->schema_source)->search_rs($filter);
    $iterator->result_class(ref $class || $class);

    if (wantarray) {
        return $iterator->all;
    } else {
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
        $data = $self->storage->_migrate_wildcards($data);
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

    return $self->storage->currency_class->new($subtotal);
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

Handel::Cart is component for maintaining simple shopping cart data.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: \%data

=back

Creates a new shopping cart object containing the specified data.

    my $cart = Handel::Cart->new({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        name    => 'My Shopping Cart'
    });

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if the first parameter is not a hashref.

=head1 METHODS

=head2 add

=over

=item Arguments: \%data | $item

=back

Adds a new item to the current shopping cart and returns an instance of the
item class specified in cart object storage. You can either pass the item
data as a hash reference:

    my $item = $cart->add({
        shopper  => '10020400-E260-11CF-AE68-00AA004A34D5',
        sku      => 'SKU1234',
        quantity => 1,
        price    => 1.25
    });

or pass an existing cart item:

    my $wishlist = Handel::Cart->load({
        shopper => '10020400-E260-11CF-AE68-00AA004A34D5',
        type    => CART_TYPE_SAVED
    });
    
    $cart->add(
        $wishlist->items({sku => 'ABC-123'})->first
    );

When passing an existing cart item to add, all columns in the source item will
be copied into the destination item if the column exists in both the
destination and source, and the column isn't the primary key or the foreign
key of the item relationship.

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if the first parameter isn't a hashref or an object that subclasses
Handel::Cart::Item.

=head2 clear

Deletes all items from the current cart.

    $cart->clear;

=head2 count

Returns the number of items in the cart object.

    my $numitems = $cart->count;

=head2 delete

=over

=item Arguments: \%filter

=back

Deletes the item matching the supplied filter from the current cart.

    $cart->delete({
        sku => 'ABC-123'
    });

=head2 destroy

=over

=item \%filter

=back

Deletes entire shopping carts (and their items) from the database. When called
as an object method, this will delete all items from the current cart object
and deletes the cart object itself. C<filter> will be ignored.

    $cart->destroy;

When called as a class method, this will delete all carts matching C<filter>.

    Handel::Cart->destroy({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception will be
thrown if C<filter> is not a HASH reference.

=head2 items

=over

=item Arguments: \%filter

=back

Loads the current carts items matching the specified filter and returns a
L<Handel::Iterator|Handel::Iterator> in scalar context, or a list of items in
list context.

    my $iterator = $cart->items;
    while (my $item = $iterator->next) {
        print $item->sku;
    };
    
    my @items = $cart->items;

By default, the items returned as Handel::Cart::Item objects. To return
something different, set C<item_class> in the local C<storage> object.

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if parameter one isn't a hashref or undef.

=head2 load

=over

=item Arguments: \%filter

=back

Loads existing carts matching the specified filter and returns a
L<Handel::Iterator|Handel::Iterator> in scalar context, or a list of carts in
list context.

    my $iterator = Handel::Cart->load({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E',
        type    => CART_TYPE_SAVED
    });
    
    while (my $cart = $iterator->next) {
        print $cart->id;
    };
    
    my @carts = Handel::Cart->load();

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if the first parameter is not a hashref.

=head2 save

Marks the current shopping cart type as C<CART_TYPE_SAVED>.

    $cart->save

=head2 restore

=over

=item Arguments: \%filter [, $mode]

=item Arguments: $cart [, $mode]

=back

Copies (restores) items from a cart, or a set of carts back into the current
shopping cart. You may either pass in a hash reference containing the search
criteria of the shopping cart(s) to restore:

    $cart->restore({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E',
        type    => CART_TYPE_SAVED
    });

or you can pass in an existing C<Handel::Cart> object or subclass.

    my $wishlist = Handel::Cart->load({
        id   => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E',
        type => CART_TYPE_SAVED
    });
    
    $cart->restore($wishlist);

For either method, you may also specify the mode in which the cart should be
restored. The following modes are available:

=over

=item C<CART_MODE_REPLACE>

All items in the current cart will be deleted before the saved cart is restored
into it. This is the default if no mode is specified.

=item C<CART_MODE_MERGE>

If an item with the same SKU exists in both the current cart and the saved cart,
the quantity of each will be added together and applied to the same sku in the
current cart. Any price differences are ignored and we assume that the price in
the current cart has the more up to date price.

=item C<CART_MODE_APPEND>

All items in the saved cart will be appended to the list of items in the current
cart. No effort will be made to merge items with the same SKU and duplicates
will be ignored.

A L<Handel::Exception::Argument|Handel::Exception::Argument> exception is
thrown if the first parameter isn't a hashref or a C<Handel::Cart::Item> object
or subclass.

=back

=head1 COLUMNS

The following methods are mapped to columns in the default cart schema. These
methods may or may not be available in any subclasses, or in situations where
a custom schema is being used that has different column names.

=head2 id

Returns the id of the current cart.

    print $cart->id;

See L<Handel::Schema::Cart/id> for more information about this column.

=head2 shopper

=over

=item Arguments: $shopper

=back

Gets/sets the id of the shopper the cart should be associated with.

    $cart->shopper('11111111-1111-1111-1111-111111111111');
    print $cart->shopper;

See L<Handel::Schema::Cart/shopper> for more information about this column.

=head2 type

=over

=item Arguments: $type

=back

Gets/sets the type of the current cart. Currently the two types allowed are:

=over

=item C<CART_TYPE_TEMP>

The cart is temporary and may be purged during any [external] cleanup process
after the designated amount of inactivity.

=item C<CART_TYPE_SAVED>

The cart should be left untouched by any cleanup process and is available to the
shopper at any time.

=back

    $cart->type(CART_TYPE_SAVED);
    print $cart->type;

See L<Handel::Schema::Cart/type> for more information about this column.

=head2 name

=over

=item Arguments: $name

=back

Gets/sets the name of the current cart.

    $cart->name('My Naw Cart');
    print $cart->name;

See L<Handel::Schema::Cart/name> for more information about this column.

=head2 description

=over

=item Arguments: $description

=back

Gets/sets the description of the current cart.

    $cart->description('New Cart');
    print $cart->description;

See L<Handel::Schema::Cart/description> for more information about this column.

=head2 subtotal

Returns the current total price of all the items in the cart object as a
stringified L<Handel::Currency|Handel::Currency> object. This is equivalent to:

    my $iterator = $cart->items;
    my $subtotal = 0;
    while (my $item = $iterator->next) {
        $subtotal += $item->quantity*$item->price;
    };

=head1 SEE ALSO

L<Handel::Cart::Item>, L<Handel::Schema::Cart>, L<Handel::Constants>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
