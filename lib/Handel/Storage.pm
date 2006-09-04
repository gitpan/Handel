# $Id: Storage.pm 1394 2006-09-04 17:54:57Z claco $
package Handel::Storage;
use strict;
use warnings;

BEGIN {
    use base qw/Class::Accessor::Grouped/;

    __PACKAGE__->mk_group_accessors('inherited', qw/
        _columns
        _primary_columns
        _currency_columns
        autoupdate
        uuid_maker
    /);
    __PACKAGE__->mk_group_accessors('component_class', qw/
        cart_class
        checkout_class
        currency_class
        item_class
        iterator_class
        result_class
        validation_module
    /);
    __PACKAGE__->mk_group_accessors('component_data', qw/
        constraints
        default_values
        validation_profile
    /);

    use Handel::Exception qw/:try/;
    use Handel::L10N qw/translate/;
    use DBIx::Class::UUIDColumns;
    use Scalar::Util qw/blessed weaken/;
    use Clone ();
    use Class::Inspector ();
};

__PACKAGE__->autoupdate(1);
__PACKAGE__->currency_class('Handel::Currency');
__PACKAGE__->iterator_class('Handel::Iterator::List');
__PACKAGE__->result_class('Handel::Storage::Result');
__PACKAGE__->validation_module('FormValidator::Simple');
__PACKAGE__->uuid_maker(DBIx::Class::UUIDColumns->uuid_maker);

sub new {
    my $class = shift;
    my $self = bless {}, ref $class || $class;

    $self->setup(@_) if scalar @_;

    return $self;
};

sub add_columns {
    my ($self, @columns) = @_;

    $self->_columns([]) unless $self->_columns;

    push @{$self->_columns}, @columns;
};

sub add_constraint {
    my ($self, $column, $name, $constraint) = @_;
    my $constraints = $self->constraints || {};

    throw Handel::Exception::Argument(
        -details => translate('No column was specified') . '.')
            unless $column;

    throw Handel::Exception::Argument(
        -details => translate('No constraint name was specified') . '.')
            unless $name;

    throw Handel::Exception::Argument(
        -details => translate('No constraint was specified') . '.')
            unless ref $constraint eq 'CODE';

    if (!exists $constraints->{$column}) {
        $constraints->{$column} = {};
    };

    $constraints->{$column}->{$name} = $constraint;

    $self->constraints($constraints);
};

sub add_item {
    throw Handel::Exception::Storage(-text => translate('Virtual method not implemented'));
};

sub clone {
    my $self = shift;

    throw Handel::Exception::Storage(
        -details => translate('Not a class method') . '.')
            unless blessed($self);

    return Clone::clone($self);
};

sub column_accessors {
    my $self = shift;
    my %accessors = map {$_ => $_} $self->columns;

    return \%accessors;
};

sub columns {
    my $self = shift;

    return @{$self->_columns || []};
};

sub copyable_item_columns {
    my $self = shift;
    my $item_class = $self->item_class;
    my @columns = $item_class->storage->columns;
    my %primaries = map {$_ => $_} $item_class->storage->primary_columns;

    my @remaining;
    foreach my $column (@columns) {
        if (!exists $primaries{$column}) {
            push @remaining, $column;
        };
    };

    return @remaining;
};

sub count_items {
    throw Handel::Exception::Storage(-text => translate('Virtual method not implemented'));
};

sub create {
    throw Handel::Exception::Storage(-text => translate('Virtual method not implemented'));
};

sub currency_columns {
    my ($self, @columns) = @_;
    my %columns = map {$_ => $_} $self->columns;

    if (@columns) {
        foreach my $column (@columns) {
            throw Handel::Exception::Storage(
                -details => translate('Column [_1] does not exist', $column) . '.')
                    unless exists $columns{$column};
        };

        $self->_currency_columns(\@columns);
    };

    return @{$self->_currency_columns || []};
};

sub delete {
    throw Handel::Exception::Storage(-text => translate('Virtual method not implemented'));
};

sub delete_items {
    throw Handel::Exception::Storage(-text => translate('Virtual method not implemented'));
};

sub new_uuid {
    my $uuid = shift->uuid_maker->as_string;

    $uuid =~ s/^{//;
    $uuid =~ s/}$//;

    return $uuid;
};

sub primary_columns {
    my ($self, @columns) = @_;
    my %columns = map {$_ => $_} $self->columns;

    if (@columns) {
        foreach my $column (@columns) {
            throw Handel::Exception::Storage(
                -details => translate('Column [_1] does not exist', $column) . '.')
                    unless exists $columns{$column};
        };

        $self->_primary_columns(\@columns);
    };

    return @{$self->_primary_columns || []};
};

sub remove_columns {
    my ($self, @columns) = @_;
    my %remove = map {$_ => $_} @columns;

    if (@columns) {
        if ($self->primary_columns) {
            # remove primary
            my @remaining_primary;
            foreach my $column ($self->primary_columns) {
                if (!exists $remove{$column}) {
                    push @remaining_primary, $column;
                };
            };

            # clear/push to keep same array ref
            @{$self->_primary_columns} = ();
            push @{$self->_primary_columns}, @remaining_primary;
        };
        if ($self->currency_columns) {
            # remove currency
            my @remaining_currency;
            foreach my $column ($self->currency_columns) {
                if (!exists $remove{$column}) {
                    push @remaining_currency, $column;
                };
            };

            # clear/push to keep same array ref
            @{$self->_currency_columns} = ();
            push @{$self->_currency_columns}, @remaining_currency;
        };
        if ($self->columns) {
            # remove columns
            my @remaining;
            foreach my $column ($self->columns) {
                if (!exists $remove{$column}) {
                    push @remaining, $column;
                };
            };

            # clear/push to keep same array ref
            @{$self->_columns} = ();
            push @{$self->_columns}, @remaining;
        };
    };
};

sub remove_constraint {
    my ($self, $column, $name) = @_;
    my $constraints = $self->constraints;

    return unless $constraints;

    throw Handel::Exception::Argument(
        -details => translate('No column was specified') . '.')
            unless defined $column;

    throw Handel::Exception::Argument(
        -details => translate('No constraint name was specified') . '.')
            unless defined $name;

    if (exists $constraints->{$column} && exists $constraints->{$column}->{$name}) {
        delete $constraints->{$column}->{$name};
        if (! keys %{$constraints->{$column}}) {
            delete $constraints->{$column};
        };
    };

    $self->constraints($constraints);
};

sub remove_constraints {
    my ($self, $column) = @_;
    my $constraints = $self->constraints;

    throw Handel::Exception::Argument(
        -details => translate('No column was specified') . '.')
            unless defined $column;

    return unless $constraints;

    if (exists $constraints->{$column}) {
        delete $constraints->{$column};
    };

    $self->constraints($constraints);
};

sub search {
    throw Handel::Exception::Storage(-text => translate('Virtual method not implemented'));
};

sub search_items {
    throw Handel::Exception::Storage(-text => translate('Virtual method not implemented'));
};

sub setup {
    my ($self, $options) = @_;

    throw Handel::Exception::Argument(
        -details => translate('Param 1 is not a HASH reference') . '.') unless
            ref($options) eq 'HASH';

    ## do these in order
    foreach my $setting (qw/add_columns remove_columns primary_columns currency_columns/) {
        if (exists $options->{$setting}) {
            $self->$setting( @{delete $options->{$setting}} );
        };
    };

    foreach my $key (keys %{$options}) {
        $self->$key($options->{$key});
    };
};

sub txn_begin {
    throw Handel::Exception::Storage(-text => translate('Virtual method not implemented'));
};

sub txn_commit {
    throw Handel::Exception::Storage(-text => translate('Virtual method not implemented'));
};

sub txn_rollback {
    throw Handel::Exception::Storage(-text => translate('Virtual method not implemented'));
};

sub get_component_class {
    my ($self, $field) = @_;

    return $self->get_inherited($field);
};

sub set_component_class {
    my ($self, $field, $value) = @_;

    if ($value) {
        if (!Class::Inspector->loaded($value)) {
            eval "use $value";

            throw Handel::Exception::Storage(
                -details => translate('The [_1] [_2] could not be loaded', $field, $value) . '.')
                    if $@;
        };
    };

    $self->set_inherited($field, $value);
};

sub get_component_data {
    my ($self, $field) = @_;

    return $self->get_inherited($field);
};

sub set_component_data {
    my ($self, $field, $value) = @_;

    $self->set_inherited($field, $value);
};

1;
__END__

=head1 NAME

Handel::Storage - Abstract storage layer for cart/order/item reads/writes

=head1 SYNOPSIS

    package MyStorage;
    use strict;
    use warnings;
    use base qw/Handel::Storage/;

    sub create {
        my ($self, $data) = @_;

        return $self->result_class->create_instance(
            $ldap->magic($data), $self
        );
    };
    
    package MyCart;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->storage_class('MyStorage');
    __PACKAGE__->storage({
        columns         => [qw/id foo bar baz/],
        primary_columns => [qw/id/]
    });
    
    1;

=head1 DESCRIPTION

Handel::Storage is a base class used to create custom storage classes used by
cart/order/item classes. It provides some generic functionality as well as
methods that must be implemented by custom storage subclasses like
Handel::Storage::DBIC.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: \%options

=back

Creates a new instance of Handel::Storage, and passes the options to L</setup>
on the new instance. The three examples below are the same:

    my $storage = Handel::Storage-new({
        item_class => 'Handel::Item'
    });
    
    my $storage = Handel::Storage-new;
    $storage->setup({
        item_class => 'Handel::Item'
    });
    
    my $storage = Handel::Storage->new;
    $storage->item_class('Handel::Item')

The following options are available to new/setup, and take the same data as
their method counterparts:

    add_columns
    autoupdate
    cart_class
    checkout_class
    constraints
    currency_class
    currency_columns
    default_values
    item_class
    iterator_class
    primary_columns
    remove_columns
    result_class
    validation_module
    validation_profile

=head1 METHODS

=head2 add_columns

=over

=item Arguments: @columns

=back

Adds a list of columns to the current storage object.

    $storage->add_columns('quix');

=head2 add_constraint

=over

=item Arguments: $column, $name, \&sub

=back

Adds a named constraint for the given column to the current storage object.
You can have any number of constraints for each column as long as they all have
different names. The constraints may or may not be called in the order in which
they are added.

    $storage->add_constraint('id', 'Check Id Format' => \&constraint_uuid);

B<It is up to each custom storage class to decide if and how to implement column
constraints.>

=head2 add_item

=over

=item Arguments: $result, \%data

=back

Adds a new item to the specified result, returning a storage result object.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    my $item = $storage->add_item($result, {
        sku => 'ABC123'
    });
    
    print $item->sku;

B<This method must be implemented in custom subclasses.>

=head2 autoupdate

=over

=item Arguments: 0|1

=back

Gets/sets the autoupdate flag for the current storage object. When set to 1, an
update request will be made to storage for every column change. When set to
0, no updated data will be sent to storage until C<update> is called.

    $storage->autoupdate(1);

The default is 1.

B<It is up to each custom storage class to decide if and how to implement
autoupdates.>

=head2 cart_class

=over

=item Arguments: $cart_class

=back

Gets/sets the cart class to be used when creating orders from carts.

    $storage->cart_class('CustomCart');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 checkout_class

=over

=item Arguments: $checkout_class

=back

Gets/sets the checkout class to be used to process the order through the
C<CHECKOUT_PHASE_INITIALIZE> phase when creating a new order and the process
options is set. The default checkout class is
L<Handel::Checkout|Handel::Checkout>.

    $storage->checkout_class('CustomCheckout');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 clone

Returns a clone of the current storage instance.

    $storage->item_class('Item');
    $storage->cart_class('Cart');
    
    my $clone = $storage->clone;
    $clone->item_class('Bar');
    
    print $storage->item_class; # Item
    print $clone->item_class;   # Item
    print $clone->cart_class;   $ Cart

This is used mostly between sub/super classes to inherit a copy of the storage
settings without having to specify options from scratch.

=head2 column_accessors

Returns a hashref containing all of the columns and their accessor names for the
current storage object.

    $storage->add_columns(qw/foo bar/);
    print %{$self->column_accessors});
    # foo foo bar bar

The column accessors are used by cart/order/item classes to map public accessors
to their columns.

=head2 columns

Returns a list of columns from the current storage object;

    $storage->add_columns(qw/foo bar baz/);
    print $storage->columns;  # foo bar baz

=head2 constraints

=over

=item Arguments: \%constraints

=back

Gets/sets the constraints configuration for the current storage instance.

    $storage->constraints({
        id   => {'Check Id Format' => \&constraint_uuid},
        name => {'Check Name/Type' => \%constraint_cart_type}
    });

The constraints are stored in a hash where each key is the name of the column
and each value is another hash reference containing the constraint name and the
constraint subroutine reference.

B<It is up to each custom storage class to decide if and how to implement column
constraints.>

=head2 copyable_item_columns

Returns a list of columns in the current item class that can be copied freely.
This list is usually all columns in the item class except for the primary
key columns and the foreign key columns that participate in the specified item
relationship.

=head2 count_items

=over

=item Arguments: $result

=back

Returns the number of items associated with the specified result.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    $result->add_item({
        sku => 'ABC123'
    });
    
    print $storage->count_items($result);

B<This method must be implemented in custom subclasses.>

=head2 create

=over

=item Arguments: \%data

=back

Creates a new result in the current storage medium.

    my $result = $storage->create({
        col1 => 'foo',
        col2 => 'bar'
    });

B<This method must be implemented in custom subclasses.>

=head2 currency_class

=over

=item Arguments: $currency_class

=back

Gets/sets the currency class to be used when inflating currency columns. The
default currency class is L<Handel::Currency|Handel::Currency>. The currency
class used should be subclass of Handel::Currency.

    $storage->currency_class('CustomCurrency');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

B<It is up to each custom storage class to decide if and how to implement
currency columns.>

=head2 currency_columns

=over

=item Arguments: @columns

=back

Gets/sets the columns that should be inflated into currency objects.

    $storage->currency_columns(qw/total price tax/);

B<It is up to each custom storage class to decide if and how to implement
currency columns.>

=head2 default_values

=over

=item Arguments: \%values

=back

Gets/sets the hash containing the default values to be applied to empty columns
during create/update actions.

    $storage->default_values({
        id   => \&newid,
        name => 'My New Cart'
    });

The default values are stored in a hash where the key is the name of the column
and the value is either a reference to a subroutine to get the value from, or
an actual default value itself.

B<It is up to each custom storage class to decide if and how to implement
default values.>

=head2 delete

=over

=item Arguments: \%filter

=back

Deletes results matching the filter in the current storage medium.

    $storage->delete({
        id => '11111111-1111-1111-1111-111111111111'
    });

B<This method must be implemented in custom subclasses.>

=head2 delete_items

=over

=item Arguments: $result, \%filter

=back

Deletes items matching the filter from the specified result.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    $result->add_item({
        sku => 'ABC123'
    });
    
    $storage->delete_items($result, {
        sku => 'ABC%'
    });

B<This method must be implemented in custom subclasses.>

=head2 item_class

=over

=item Arguments: $item_class

=back

Gets/sets the item class to be used when returning cart/order items.

    $storage->item_class('CustomCartItem');

The class specified should be a subclass of Handel::Base, or at least provide
its C<create_instance> and C<result> methods.

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 iterator_class

=over

=item $iterator_class

=back

Gets/sets the class used for iterative result operations. The default
iterator is L<Handel::Iterator::List|Handel::Iterator::List>.

    $storage->iterator_class('MyIterator');
    my $results = $storage->search;
    
    print ref $results # Handel::Iterator::List

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 new_uuid

Returns a new uuid/guid string in the form of

    xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

See L<DBIx::Class::UUIDColumns|DBIx::Class::UUIDColumns> for more information on
how uuids are generated.

=head2 primary_columns

Returns a list of primary columns from the current storage object;

    $storage->add_columns(qw/foo bar baz/);
    $storage->primary_columns('foo');
    print $storage->primary_columns;  # foo

=head2 remove_columns

=over

=item Arguments: @columns

=back

Removes a list of columns from the current storage object.

    $storage->remove_columns(qw/description/);

=head2 remove_constraint

=over

=item Arguments: $column, $name

=back

Removes a named constraint for the given column from the current storage object.

    $storage->remove_constraint('id', 'Check Id Format' => \&constraint_uuid);

=head2 remove_constraints

=over

=item Arguments: $column

=back

Removes all constraints for the given column from the current storage object.

    $storage->remove_constraints('id');

=head2 result_class

=over

=item Arguments: $result_class

=back

Gets/sets the result class to be used when returning results from create/search
storage operations. The default result class is
L<Handel::Storage::Result|Handel::Storage::Result>.

    $storage->result_class('CustomStorageResult');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 search

=over

=item Arguments: \%filter

=back

Returns results in list context, or an iterator in scalar context from the
current source in the current schema matching the search filter.

    my $iterator = $storage->search({
        col1 => 'foo'
    });

    my @results = $storage->search({
        col1 => 'foo'
    });

B<This method must be implemented in custom subclasses.>

=head2 search_items

=over

=item Arguments: $result, \%filter

=back

Returns items matching the filter associated with the specified result.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->search({
        id => '11111111-1111-1111-1111-111111111111'
    });
    
    my $iterator = $storage->search_items($result);

Returns results in list context, or an iterator in scalar context from the
current source in the current schema matching the search filter.

B<This method must be implemented in custom subclasses.>

=head2 setup

=over

=item Arguments: \%options

=back

Configures a storage instance with the options specified. Setup accepts the
exact same options that L</new> does.

    package MyStorageClass;
    use strict;
    use warnings;
    use base qw/Handel::Storage/;
    
    __PACKAGE__->setup({
        item_class => 'Foo'
    });
    
    # or
    
    my $storage = Handel::Storage-new;
    $storage->setup({
        item_class => 'Items',
        cart_class => 'CustomerCart'
    });

This is the same as doing:

    my $storage = Handel::Storage-new({
        item_class => 'Items',
        cart_class => 'CustomerCart'
    });

If you call setup on a storage instance or class that has already been
configured, its configuration will be updated with the new options. No attempt
will be made to clear or reset the unspecified settings back to their defaults.

=head2 txn_begin

Starts a transaction on the current storage object.

B<This method must be implemented in custom subclasses.>

=head2 txn_commit

Commits the current transaction on the current storage object.

B<This method must be implemented in custom subclasses.>

=head2 txn_rollback

Rolls back the current transaction on the current storage object.

B<This method must be implemented in custom subclasses.>

=head2 validation_module

=over

=item Arguments: $validation_module

=back

Gets/sets the module validation class should use to do its column data
validation. The default module is FormValidator::Simple. 

B<It is up to each custom storage class to decide if and how to implement data
validation.>

=head2 validation_profile

=over

=item Arguments: \@profile*

=back

Gets/sets the validation profile to be used when validating column values.

    $storage->validation_profile([
        param1 => ['NOT_BLANK', 'ASCII', ['LENGTH', 2, 5]],
        param2 => ['NOT_BLANK', 'INT'  ],
        mail1  => ['NOT_BLANK', 'EMAIL_LOOSE']
    ]);

B<*> The default validation module is
L<FormValidator::Simple|FormValidator::Simple>, which expects a profile in an
array reference. If you use L<Data::FormValidator|Data::FormValidator>, make
sure you pass in the profile as a hash reference instead:

    $storage->validation_profile({
        optional => [qw( company
                         fax 
                         country )],
        required => [qw( fullname 
                         phone 
                         email 
                         address )]
    });

B<It is up to each custom storage class to decide if and how to implement data
validation.>

=head1 SEE ALSO

L<Handel::Storage::DBIC>, L<Handel::Storage::Result>,
L<Handel::Manual::Storage>, L<Handel::Storage::Cart>, L<Handel::Storage::Order>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
