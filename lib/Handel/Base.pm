# $Id: Base.pm 1335 2006-07-15 02:43:12Z claco $
package Handel::Base;
use strict;
use warnings;
use Handel::Exception qw/:try/;
use Handel::L10N qw/translate/;
use Scalar::Util qw/blessed/;
use Class::ISA;
use Class::Inspector;

BEGIN {
    use base qw/Class::Accessor::Grouped/;
    __PACKAGE__->mk_group_accessors('simple', qw/autoupdate result/);
    __PACKAGE__->mk_group_accessors('inherited', qw/accessor_map/);
    __PACKAGE__->mk_group_accessors('component_class', qw/storage_class/);
};

__PACKAGE__->storage_class('Handel::Storage');

sub import {
    my $self = shift;

    if (!$self->has_storage) {
        $self->init_storage;
    };
};

sub create_accessors {
    my ($self, $map) = @_;
    my $class = ref $self || $self;
    my $accessors;

    if ($accessors = $self->storage->column_accessors) {
        foreach my $column (keys %{$accessors}) {
            $self->mk_group_accessors('column', [$accessors->{$column}, $column]);
        };
    };

    $self->accessor_map($accessors);
};

sub get_column {
    my ($self, $column) = @_;
    my $accessor = $self->accessor_map->{$column} || $column;

    return $self->result->$accessor;
};

sub set_column {
    my ($self, $column, $value) = @_;
    my $accessor = $self->accessor_map->{$column} || $column;

    $self->result->$accessor($value);
    $self->update if $self->autoupdate;
};

sub inflate_result {
    my $self = shift;
    my $result = $_[0]->result_class->inflate_result(@_);

    return $self->create_result($result);
};

sub create_result {
    my ($self, $result) = @_;
    my $class = ref $self || $self;
    
    return bless {
        result => $result,
        autoupdate => $result->result_source->schema->{'__handel_storage'}->autoupdate
    }, $class;
};

sub storage {
    my $self = shift;
    my $class = blessed $self || $self;
    my $args = ref($_[0]) eq 'HASH' ? $_[0] : undef;
    my $storage = blessed($_[0]) && $_[0]->isa('Handel::Storage') ? $_[0] : undef;

    if ($storage) {
        $self->_set_storage($storage);
    } else {
        $storage = $self->_get_storage;
    };

    $storage->setup($args) if $args;

    return $storage;
};

sub has_storage {
    my $self = shift;
    my $class = ref $self || $self;

    no strict 'refs';

    if ($self->{'storage'} || ${"$class\:\:_storage"}) {
        return 1;
    } else {
        return;
    };
};

sub init_storage {
    shift->_get_storage;
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

sub _get_storage {
    my $self = shift;
    my $class = blessed $self || $self;

    no strict 'refs';
    no warnings;

    my $storage = $self->{'storage'} || ${"$class\:\:_storage"};
    if (!$storage) {
        my ($super) = (Class::ISA::super_path($class));

        if ($super &&  ${"$super\:\:_storage"}) {
            $storage = ${"$super\:\:_storage"};

            if ($storage && blessed($storage) eq $self->storage_class) {
                if ($storage->_schema_instance) {
                    $storage = $self->storage_class->new;
                } else {
                    $storage = $storage->clone;
                };
            } else {
                $storage = $self->storage_class->new;
            };
        } else {
            $storage = $self->storage_class->new;
        };

        $self->_set_storage($storage);
    };

    return $storage;
};

sub _set_storage {
    my ($self, $storage) = @_;
    my $class = blessed $self || $self;

    if (blessed $self) {
        $self->{'storage'} = $storage;
    } else {
        no strict 'refs';
        no warnings;

        ${"$class\:\:_storage"} = $storage;
    };
};

sub update {
    my $self = shift;

    return $self->result->update(@_);
};

1;
__END__

=head1 NAME

Handel::Base - Base class for Cart/Order/Item classes

=head1 SYNOPSIS

    use MyCustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Base/;
    
    __PACKAGE__->storage({
        schema_source  => 'Carts',
        item_class     => 'MyCustomItem',
        constraints    => {
            id         => {'Check Id'      => \&constraint_uuid},
            shopper    => {'Check Shopper' => \&constraint_uuid},
            type       => {'Check Type'    => \&constraint_cart_type},
            name       => {'Check Name'    => \&constraint_cart_name}
        },
        default_values => {
            id         => __PACKAGE__->storage_class->can('new_uuid'),
            type       => CART_TYPE_TEMP
        }
    });
    __PACKAGE__->create_accessors;
    
    1;

=head1 DESCRIPTION

Handel::Base is a base class for the Cart/Order/Item classes that glues those
classes to a L<Handel::Storage|Handel::Storage> object.

=head1 METHODS

=head2 accessor_map

Returns a hashref containing the column/accessor mapping used when
C<create_accessors> was last called. This is used by C<get_column>/C<set_column>
to get the accessor name for any given column.

    $schema->add_column('foo' => {accessor => 'bar');
    ...
    $base->create_accessors;
    $base->bar('newval');  # calls $base->set_column('foo', 'newval');
    ...
    sub set_column {
        my ($self, $column, $value) = @_;
        my $accessor = $self->accessor_map->{$column} || $column;
        
        $self->result->$accessor($value);
    };

=head2 create_accessors

Creates a column accessor for each accessor returned from
L<Handel::Storage/column_accessors>. If you have defined columns in your
schema to have an accessor that is different than the column name, that will
be used instead of the column name.

    package CustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Cart/;
    __PACKAGE__->storage->add_columns('foo');
    __PACKAGE__->create_accessors;

Each accessor will call C<get_column>/C<set_column>, passing the real database
column name.

=head2 create_result

=over

=item Arguments: $result

=back

Creates a new instance of the current class, stores the resultset result object
inside, and does any configuration on the new object before returning it.

    my $result = $schema->resultset('Carts')->create({name => 'My Cart'});
    my $cart = Handel::Cart->create_result($result);

This is used internally by C<inflate_result> and C<storage>. There's probably
no good reason to use this yourself.

=head2 get_column

=over

=item Arguments: $column

=back

Returns the value for the specified column from the current C<result>. If an
accessor has been defined for the column in C<accessor_map>, that will be used
against the result instead.

    my $cart = Handel::Cart->new({name => 'My Cart'});
    print $cart->get_column('name');

=head2 has_storage

Returns true if the current class has an instance of
L<Handel::Storage|Handel::Storage>. Returns undef if it does not.

    package CustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Cart/;
    if (!__PACKAGE__->has_storage) {
        __PACKAGE->init_storage;
    };

=head2 inflate_result

=over

=item Arguments: $result

=back

This method is called by L<Handel::Iterator|Handel::Iterator> to inflate
objects returned by various iterator operations into the current class. There is
probably no good reason to use this method yourself.

=head2 init_storage

Initializes the storage object in the current class, cloning it from the
superclass if necessary.

    package CustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Cart/;
    if (!__PACKAGE__->has_storage) {
        __PACKAGE->init_storage;
    };

=head2 set_column

=over

=item Arguments: $column, $value

=back

Sets the value for the specified column on the current C<result>. If an
accessor has been defined for the column in C<accessor_map>, that will be used
against the result instead.

    my $cart = Handel::Cart->new({name => 'My Cart'});
    $cart->set_column('name', 'New Cart');

If C<autoupdate> is enable for the current object, C<set_column> will call
C<update> automatically. If C<autoupdate> is disabled, be sure to call C<update>
to save change to the database.

    my $cart = Handel::Cart->new({name => 'My Cart'});
    $cart->set_column('name', 'New Cart');
    if (!$cart->autoupdate) {
        $cart->update;
    };

=head2 storage

=over

=item Arguments: \%options

=back

Returns the local instance of C<storage_class>. If a local object doesn't
exist, it will create and return a new one*. If specified, C<options> will be
passed to C<setup> on the storage object.

B<*> When creating subclasses of Cart/Order/Item classes and no storage object
exists in the current class, storage will attempt to clone one from the
immediate superclass using C<init_storage> and C<clone> first before creating
a new instance. However, a clone will only be created if it is of the same type
specified in C<storage_class>.

    package CustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Cart/;
    
    my $storage = __PACKAGE__->storage;
    ## clones a new storage object from Handel::Cart

=head2 storage_class

=over

=item Arguments: $storage_class

=back

Gets/sets the default storage class to be created by C<init_storage>.

    __PACKAGE__->storage_class('MyStorage');
    
    print ref __PACKAGE__->storage; # MyStorage

If you are using a custom storage class, you must set C<storage_class> before
you call C<storage> for the first time in this class.

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 result

Returns the schema resultset result object for the current class object.
There should be no need currently to access this directly unless you are
writing custom subclasses.

    my @columns = $cart->result->columns;

See L<DBIx::Class::ResultSet|DBIx::Class::ResultSet> and
L<DBIx::Class::Row|DBIx::Class::Row> for more information on using the result
object.

=head2 update

=over

=item Arguments: \%data

=back

Sends all of the column updates to the database. If C<autoupdate> is off in the
current object, you must call this to save your changes or they will
be lost when the object goes out of scope.

    $cart->name('My Cart');
    $cart->description('My Favorite Cart');
    $cart->update;

You may also pass a hash reference containing name/value pairs to be applied:

    $cart->update({
        name        => 'My Cart',
        description => 'My Favorite Cart'
    });

Be careful to always use the column name, not its accessor alias if it has one.

=head1 SEE ALSO

L<Handel::Storage>, L<DBIx::Class::ResultSet>, L<DBIx::Class::Row>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
