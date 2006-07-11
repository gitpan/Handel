# $Id: Storage.pm 1318 2006-07-10 23:42:32Z claco $
package Handel::Storage;
use strict;
use warnings;
use Handel::Exception qw/:try/;
use Handel::L10N qw/translate/;
use DBIx::Class::UUIDColumns;
use Scalar::Util qw/blessed/;
use Clone;
use Class::Inspector;

BEGIN {
    use base qw/Class::Accessor::Grouped/;

    __PACKAGE__->mk_group_accessors('inherited', qw/
        autoupdate table_name connection_info item_relationship schema_source
        _schema_instance _columns_to_add _columns_to_remove currency_columns
    /);
    __PACKAGE__->mk_group_accessors('component_class', qw/
        cart_class item_class schema_class iterator_class constraints_class
        validation_class default_values_class currency_class validation_module
    /);
    __PACKAGE__->mk_group_accessors('component_data', qw/
        constraints default_values validation_profile
    /);
};

__PACKAGE__->autoupdate(1);
__PACKAGE__->item_relationship('items');
__PACKAGE__->iterator_class('Handel::Iterator');
__PACKAGE__->currency_class('Handel::Currency');
__PACKAGE__->constraints_class('Handel::Components::Constraints');
__PACKAGE__->validation_class('Handel::Components::Validation');
__PACKAGE__->validation_module('FormValidator::Simple');
__PACKAGE__->default_values_class('Handel::Components::DefaultValues');

sub new {
    my $class = shift;
    my $self = bless {}, ref $class || $class;

    $self->setup(@_) if scalar @_;

    return $self;
};

sub setup {
    my ($self, $options) = @_;

    throw Handel::Exception::Storage(
        -details => translate('Param 1 is not a HASH reference') . '.') unless
            ref($options) eq 'HASH';

    throw Handel::Exception::Storage(
        -details => translate('A schema instance has already been initialized') . '.')
            if $self->_schema_instance;

    $self->_clear_options;

    # do the oddball copys first
    $self->add_columns(@{delete $options->{'add_columns'}}) if exists $options->{'add_columns'};
    $self->remove_columns(@{delete $options->{'remove_columns'}}) if exists $options->{'remove_columns'};

    foreach (qw/
        autoupdate
        cart_class
        connection_info
        constraints
        constraints_class
        currency_class
        currency_columns
        default_values_class
        default_values
        item_class
        item_relationship
        iterator_class
        schema_class
        schema_source
        table_name
        validation_class
        validation_module
        validation_profile
    /) {
        $self->$_(delete $options->{$_}) if exists $options->{$_};
    };

    # save the setup for last
    $self->schema_instance(delete $options->{'schema_instance'}) if exists $options->{'schema_instance'};
};

sub _clear_options {
    my $self = shift;
    
    if (blessed $self) {
        %{$self} = ();
    } else {
        foreach (qw/
            _columns_to_add
            _columns_to_remove
            autoupdate
            cart_class
            connection_info
            constraints
            constraints_class
            currency_class
            currency_columns
            default_values_class
            default_values
            item_class
            item_relationship
            iterator_class
            schema_class
            schema_source
            table_name
            validation_class
            validation_module
            validation_profile
        /) {
            $self->$_(undef);
        };
    };
};

sub clone {
    my $self = shift;

    throw Handel::Exception::Storage(
        -details => translate('Not a class method') . '.')
            unless blessed($self);

    throw Handel::Exception::Storage(
        -details => translate('Can not clone storage object with an existing schema instance') . '.')
            if $self->_schema_instance;

    return Clone::clone($self);
};

sub add_columns {
    my ($self, @columns) = @_;

    if ($self->_schema_instance) {
        # I'm still not sure why you have to do both after the result_source_instance
        # fix in compose_namespace.
        $self->_schema_instance->source($self->schema_source)->add_columns(@columns);
        $self->_schema_instance->class($self->schema_source)->add_columns(@columns);
    };

    $self->_columns_to_add
        ? push @{$self->_columns_to_add}, @columns
        : $self->_columns_to_add(\@columns);
};

sub column_accessors {
    my $self = shift;
    my $accessors = {};

    if ($self->_schema_instance) {
        my $source = $self->_schema_instance->source($self->schema_source);
    
        my @columns = $source->columns;
        foreach my $column (@columns) {
            my $accessor = $source->column_info($column)->{'accessor'} || $column;
            $accessors->{$column} = $accessor;
        };
    } else {
        my $source = $self->schema_class->source($self->schema_source);

        my @columns = $source->columns;
        foreach my $column (@columns) {
            my $accessor = $source->column_info($column)->{'accessor'} || $column;
            $accessors->{$column} = $accessor;
        };

        if ($self->_columns_to_add) {
            # do the DBIC add_column dance step
            my $adding = Clone::clone($self->_columns_to_add);

            while (my $column = shift @{$adding}) {
                my $column_info = ref $adding->[0] ? shift(@{$adding}) : {};
                my $accessor = $column_info->{'accessor'} || $column;

                $accessors->{$column} = $accessor;
            };
        };

        if ($self->_columns_to_remove) {
            foreach my $column (@{$self->_columns_to_remove}) {
                delete $accessors->{$column};
            };
        };
    };

    return $accessors;
};

sub remove_columns {
    my ($self, @columns) = @_;

    if ($self->_schema_instance) {
        # I'm still not sure why you have to do both after the result_source_instance
        # fix in compose_namespace.
        $self->_schema_instance->source($self->schema_source)->remove_columns(@columns);
        $self->_schema_instance->class($self->schema_source)->remove_columns(@columns);
    };

    $self->_columns_to_remove
        ? push @{$self->_columns_to_remove}, @columns
        : $self->_columns_to_remove(\@columns);
};

sub add_constraint {
    my ($self, $column, $name, $constraint) = @_;

    throw Handel::Exception::Storage(
        -details => translate('Can not add constraints to an existing schema instance') . '.')
            if $self->_schema_instance;

    my $constraints = $self->constraints || {};

    if (!exists $constraints->{$column}) {
        $constraints->{$column} = {};
    };

    $constraints->{$column}->{$name} = $constraint;

    $self->constraints($constraints);
};

sub remove_constraint {
    my ($self, $column, $name) = @_;

    throw Handel::Exception::Storage(
        -details => translate('Can not remove constraints to an existing schema instance') . '.')
            if $self->_schema_instance;

    my $constraints = $self->constraints;

    return unless $constraints;

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

    throw Handel::Exception::Storage(
        -details => translate('Can not remove constraints to an existing schema instance') . '.')
            if $self->_schema_instance;

    my $constraints = $self->constraints;

    return unless $constraints;

    if (exists $constraints->{$column}) {
        delete $constraints->{$column};
    };

    $self->constraints($constraints);
};

sub schema_instance {
    my $self = shift;
    my $schema_instance = $_[0];
    my $package = ref $self || $self;

    no strict 'refs';

    throw Handel::Exception::Storage(
        -details => translate('No schema_source is specified') . '.') unless
            $self->schema_source;

    # allow unsetting
    if (scalar @_ && !$schema_instance) {
        return $self->_schema_instance(@_);
    };

    if (blessed $schema_instance) {
        my $namespace = "$package\:\:".uc($self->new_uuid);
        $namespace =~ s/-//g;

        my $clone_schema = $schema_instance->compose_namespace($namespace);

        $self->_schema_instance($clone_schema);
        $self->_configure_schema_instance;
        $self->set_inherited('schema_class', blessed $clone_schema);
    };

    if (!$self->_schema_instance) {
        throw Handel::Exception::Storage(
            -details => translate('No schema_class is specified') . '.') unless
                $self->schema_class;

        my $namespace = "$package\:\:".uc($self->new_uuid);
        $namespace =~ s/-//g;

        my $clone_schema = $self->schema_class->compose_namespace($namespace);
        my $schema = $clone_schema->connect(@{$self->connection_info || []});

        $self->_schema_instance($schema);
        $self->_configure_schema_instance;
        $self->set_inherited('schema_class', blessed $schema);
    };

    return $self->_schema_instance;
};

sub _configure_schema_instance {
    my ($self) = @_;
    my $schema_instance = $self->schema_instance;
    my $schema_source = $self->schema_source;
    my $iterator_class = $self->iterator_class;
    my $item_class = $self->item_class;
    my $item_relationship = $self->item_relationship;
    my $source_class = $schema_instance->class($schema_source);
    my $item_source_class;
    my $source = $schema_instance->source($schema_source);

    $source->name($self->table_name) if $self->table_name;
    $source->resultset_class($iterator_class);

    # twiddle source columns
    if ($self->_columns_to_add) {
        # I'm still not sure why you have to do both after the result_source_instance
        # fix in compose_namespace.
        $source->add_columns(@{$self->_columns_to_add});
        $source_class->add_columns(@{$self->_columns_to_add});
    };
    if ($self->_columns_to_remove) {
        # I'm still not sure why you have to do both after the result_source_instance
        # fix in compose_namespace.
        $source->remove_columns(@{$self->_columns_to_remove});
        $source_class->remove_columns(@{$self->_columns_to_remove});
    };

    # add currency inflate/deflators
    if ($self->currency_columns) {
        my $currency_class = $self->currency_class;
        foreach my $column (@{$self->currency_columns}) {
            $source_class->inflate_column($column, {
                inflate => sub {$currency_class->new(shift);},
                deflate => sub {shift->value;}
            });
        };
    };

    if ($item_class) {
        $item_source_class = $schema_instance->class($item_class->storage->schema_source);

        if ($source->has_relationship($item_relationship)) {
            $source->related_source($item_relationship)->resultset_class($iterator_class);
        } else {
            throw Handel::Exception(-text =>
                translate('The source [_1] has no relationship named [_2].', $schema_source, $item_relationship)
            );
        };

        # twiddle item source columns
        my $item_source = $self->schema_instance->source($item_class->storage->schema_source);
        $item_source->name($item_class->storage->table_name) if $item_class->storage->table_name;
        
        if ($self->item_class->storage->_columns_to_add) {
            # I'm still not sure why you have to do both after the result_source_instance
            # fix in compose_namespace.
            $item_source->add_columns(@{$item_class->storage->_columns_to_add});
            $item_source_class->add_columns(@{$item_class->storage->_columns_to_add});
        };
        if ($self->item_class->storage->_columns_to_remove) {
            # I'm still not sure why you have to do both after the result_source_instance
            # fix in compose_namespace.
            $item_source->remove_columns(@{$item_class->storage->_columns_to_remove});
            $item_source_class->remove_columns(@{$item_class->storage->_columns_to_remove});
        };

        # add currency inflate/deflators
        if ($self->item_class->storage->currency_columns) {
            my $currency_class = $self->item_class->storage->currency_class;
            foreach my $column (@{$self->item_class->storage->currency_columns}) {
                $item_source_class->inflate_column($column, {
                    inflate => sub {$currency_class->new(shift);},
                    deflate => sub {shift->value;}
                });
            };
        };
    };

    $schema_instance->storage->dbh->{HandleError} = $self->can('process_error');


    # warning: there be dragons in here
    # load_components/C3 recalc is slow, esp after 6 calls to it
    # this works, evil or not, it works.
    # and it's only evil for schemas who don't load what we need

    # load class and item class validation
    if (my $profile = $self->validation_profile) {
        $self->_inject_schema_validation($source_class, $self->validation_class);
        $source_class->validation_profile($profile);
        $source_class->validation_module($self->validation_module);
    };
    if ($item_class && $item_class->storage->validation_profile) {
        $self->_inject_schema_validation(
            $item_source_class,
            $item_class->storage->validation_class
        );
        $item_source_class->validation_profile(
            $item_class->storage->validation_profile
        );
        $item_source_class->validation_module(
            $item_class->storage->validation_module
        );
    };

    # load class and item class constraints
    if (my $constraints = $self->constraints) {
        $self->_inject_schema_constraints($source_class, $self->constraints_class);
        $source_class->constraints($constraints);
    };
    if ($item_class && $item_class->storage->constraints) {
        $self->_inject_schema_constraints(
            $item_source_class,
            $item_class->storage->constraints_class
        );
        $item_source_class->constraints(
            $item_class->storage->constraints
        );
    };

    # load class and item class default values
    if (my $defaults = $self->default_values) {
        $self->_inject_schema_default_values($source_class, $self->default_values_class);
        $source_class->default_values($defaults);
    };
    if ($item_class && $item_class->storage->default_values) {
        $self->_inject_schema_default_values(
            $item_source_class,
            $item_class->storage->default_values_class
        );
        $item_source_class->default_values(
            $item_class->storage->default_values
        );
    };
};

sub _inject_schema_validation {
    my ($self, $source_class, $validation_class) = @_;

    if (!$source_class->isa($validation_class)) {
        no strict 'refs';
        no warnings 'redefine';

        push @{"$source_class\:\:ISA"}, $validation_class;
        foreach (qw/insert update/) {
            my $original = $source_class->can($_);
            *{"$source_class\:\:$_"} = sub {
                $_[0]->validate;
                return $original->(@_);
            };
        };
    };
};

sub _inject_schema_constraints {
    my ($self, $source_class, $constraints_class) = @_;

    if (!$source_class->isa($constraints_class)) {
        no strict 'refs';
        no warnings 'redefine';

        push @{"$source_class\:\:ISA"}, $constraints_class;
        foreach (qw/insert update/) {
            my $original = $source_class->can($_);
            *{"$source_class\:\:$_"} = sub {
                $_[0]->check_constraints;
                return $original->(@_);
            };
        };
    };
};

sub _inject_schema_default_values {
    my ($self, $source_class, $defaults_class) = @_;

    if (!$source_class->isa($defaults_class)) {
        no strict 'refs';
        no warnings 'redefine';

        push @{"$source_class\:\:ISA"}, $defaults_class;
        foreach (qw/insert update/) {
            my $original = $source_class->can($_);
            *{"$source_class\:\:$_"} = sub {
                $_[0]->set_default_values;
                return $original->(@_);
            };
        };
    };
};

sub new_uuid {
    my $uuid = DBIx::Class::UUIDColumns->uuid_maker->as_string;

    $uuid =~ s/^{//;
    $uuid =~ s/}$//;

    return $uuid;
};

sub process_error {
    my ($message) = @_;

    if ($message =~ /column\s+(.*)\s+is not unique/) {
        my $details = translate("[_1] value already exists", $1);

        throw Handel::Exception::Constraint(-text => $details);
    } else {
        throw Handel::Exception::Constraint(-text => $message);
    };
};

sub _migrate_wildcards {
    my ($self, $filter) = @_;

    return undef unless $filter;

    if (ref $filter eq 'HASH') {
        foreach my $key (keys %{$filter}) {
            my $value = $filter->{$key};
            if (!ref $filter->{$key} && $value =~ /\%/) {
                $filter->{$key} = {like => $value}
            };
        };
    };

    return $filter;
};

#sub copyable_columns {
#    my ($self) = @_;
#    my @copyable;
#    my %primaries = map {$_ => 1} $self->storage->primary_columns;
#    my %foreigns;
#
#    if ($self->storage->has_relationship($self->item_relationship)) {
#        my @cond = %{$self->storage->relationship_info($self->item_relationship)->{attr}};
#
#        foreach (@cond) {
#            if ($_ =~ /^foreign\.(.*)/) {
#                $foreigns{$1}++;
#            };
#        };
#    };
#
#    foreach ($self->storage->columns) {
#        if (!exists $primaries{$_} && !exists $foreigns{$_}) {
#            push @copyable, $_;
#        };
#    };
#
#    return @copyable;
#};

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

    if ($field eq 'schema_class' && scalar @_ > 2) {
        $self->_schema_instance(undef);
    };

    $self->set_inherited($field, $value);
};

sub get_component_data {
    my ($self, $field) = @_;

    return $self->get_inherited($field);
};

sub set_component_data {
    my ($self, $field, $value) = @_;

    if ($self->_schema_instance) {
        throw Handel::Exception::Storage(
            -details => translate('Can not assign [_1] to an existing schema instance', $field) . '.')
                if $self->_schema_instance;
    } else {
        $self->set_inherited($field, $value);
    };
};

1;
__END__

=head1 NAME

Handel::Storage - Abstract storage layer for cart/order/item reads/writes

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
    
    1;

=head1 DESCRIPTION

Handel::Storage is used as an intermediary between Handel::Cart/Handel::Order
and the schema classes used for reading/writing to the database.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: \%options

=back

Creates a new instance of Handel::Storage, and passes the options to L</setup>
on the new instance. The three examples below are the same:

    my $storage = Handel::Storage-new({
        schema_source  => 'Carts',
        cart_class     => 'CustomerCart'
    });
    
    my $storage = Handel::Storage-new;
    $storage->setup({
        schema_source  => 'Carts',
        cart_class     => 'CustomerCart'
    });
    
    my $storage = Handel::Storage->new;
    $storage->schema_source('Carts');
    $storage->cart_class('CustomCart');

The following options are available to new/setup, and take the same data as
their method counterparts:

    add_columns
    autoupdate
    cart_class
    connection_info
    constraints
    constraints_class
    currency_class
    currency_columns
    default_values_class
    default_values
    item_class
    item_relationship
    iterator_class
    remove_columns
    schema_class
    schema_instance
    schema_source
    table_name
    validation_class
    validation_module
    validation_profile

=head1 METHODS

=head2 add_columns

=over

=item Arguments: @columns

=back

Adds a list of columns to the current schema_source in the current schema_class
and maps the new columns to accessors in the current class. Be careful to always
use the column names, not their accessor aliases.

    $storage->add_columns(qw/foo bar baz/);

You can also add columns using the DBIx::Class \%column_info syntax:

    $storage->add_columns(
        foo => {data_type => 'varchar', size => 36},
        bar => {data_type => int, accessor => 'get_bar'}
    );

Yes, you can even mix/match the two:

    $storage->add_columns(
        'foo',
        bar => {accessor => 'get_bar', data_type => 'int'},
        'baz'
    );

Before schema_instance is initialized, the columns to be added are stored
internally, then added to the schema_instance when it is initialized. If a
schema_instance already exists, the columns are added directly to the
schema_source in the schema_instance itself.

=head2 add_constraint

=over

=item Arguments: $column, $name, \&sub

=back

Adds a named constraint for the given column to the current schema_source in the
current schema_class. During insert/update operations, the constraint subs will
be called upon to validation the specified columns data I<after> and default
values are set on empty columns. You can any number of constraints for each
column as long as they all have different names. The constraints may or may not
be called in the order in which they are added.

    $storage->add_constraint('id', 'Check Id Format' => \&constraint_uuid);

Constraints can only be added before schema_instance is initialized.
A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if you try to add a constraint and schema_instance is already
initialized.

Be careful to always use the column name, not its accessor alias if it has one.

=head2 autoupdate

=over

=item Arguments: 0|1

=back

Gets/sets the autoupdate flag for the current schema_source. When set to 1, an
update request will be made to the database for every field change. When set to
0, no updated data will be sent to the database until C<update> is called.

    $storage->autoupdate(1);

The default is 1.

=head2 cart_class

=over

=item Arguments: $cart_class

=back

Gets/sets the cart class to be used when creating orders from carts.

    $storage->cart_class('CustomCart');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 clone

Returns a clone of the current storage instance.

    $storage->schema_source('Foo');
    my $clone = $storage->clone;
    $clone->schema_source('Bar');
    
    print $storage->schema_source; # Foo
    print $clone->schema_source;   # Bar

This is used mostly between sub/super classes to inherit a copy of the storage
settings without having to specify options from scratch.

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown call as a class method, or if a schema_instance has already been
initialized.

=head2 column_accessors

Returns a hashref containing all of the columns and their accessor names for the
current storage object.

If a schema_instance already exists, the columns from schema_source in that
schema_instance will be returned. If no schema_instance exists, the columns from
schema_source in the current schema_class will be returned plus any columns to
be added from add_columns minus and columns to be removed from remove_columns.

=head2 connection_info

=over

=item Arguments: \@info

=back

Gets/sets the connection information used when connecting to the database.

    $storage->connection_info(['dbi:mysql:foo', 'user', 'pass', {PrintError=>1}]);

The info argument is an array ref that holds the following values:

=over

=item $dsn

The DBI dsn to use to connect to.

=item $username

The username for the database you are connecting to.

=item $password

The password for the database you are connecting to.

=item \%attr

The attributes to be pass to DBI for this connection.

=back

See L<DBI> for more information about dsns and connection attributes.

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

Be careful to always use the column name, not its accessor alias if it has one.

=head2 constraints_class

=over

=item Arguments: $constraint_class

=back

Gets/sets the constraint class to be used when check column constraints. The
default constraint class is 
L<Handel::Components::Constraints|Handel::Components::Constraints>. The
constraint class used should be subclass of Handel::Components::Constraints.

    $storage->constraint_class('CustomCurrency');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

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

=head2 currency_columns

=over

=item Arguments: @columns

=back

Gets/sets the columns that should be inflated into currency objects.

    $storage->currency_columns(qw/total price tax/);

=head2 default_values_class

=over

=item Arguments: $default_values_class

=back

Gets/sets the default values class to be used when setting default column
values. The default class is 
L<Handel::Components::DefaultValues|Handel::Components::DefaultValues>. The
default values class used should be subclass of
Handel::Components::DefaultValues.

    $storage->default_value_class('SetDefaults');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 default_values

=over

=item Arguments: \%values

=back

Gets/sets the hash containing the default values to be applied to empty columns
during insert/update statements. Default values are applied to empty columns
before and constraints or validation occurs.

    $storage->default_values({
        id   => \&newid,
        name => 'My New Cart'
    });

The default values are stored in a hash where the key is the name of the column
and the value is either a reference to a subroutine to get the value from, or
an actual default value itself.

Be careful to always use the column name, not its accessor alias if it has one.

=head2 item_class

=over

=item Arguments: $item_class

=back

Gets/sets the item class to be used when returning cart/order items.

    $storage->item_class('CustomCartItem');

The class specified should be a subclass of Handel::Base, or at least provide
its C<inflate_result> and C<result> methods.

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 item_relationship

=over

=item Arguments: $relationship_name

=back

Gets/sets the name of the schema relationship between carts and items.
The default item relationship is 'items'.

    # in your schema classes
    MySchema::CustomCart->has_many(rel_items => 'MySchema::CustomItem', {'foreign.cart' => 'self.id'});
    
    # in your storage
    $storage->item_relationship('rel_items');

=head2 iterator_class

=over

=item $iterator_class

=back

Gets/sets the class used for iterative resultset operations. The default
iterator is L<Handel::Iterator|Handel::Iterator>.

    # in your storage
    $storage->iterator_class('MyIterator');
    
    # in your code
    my $carts = Handel::Carts->load;
    print ref $carts; # MyIterator

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 new_uuid

Returns a new uuid/guid string in the form of

    xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

See L<DBIx::Class::UUIDColumns|DBIx::Class::UUIDColumns> for more information on
how uuids are generated.

=head2 process_error

This method accepts errors from DBI using $dbh->{HandelError} and converts them
into Handel::Exception objects before throwing the error.

=head2 remove_columns

=over

=item Arguments: @columns

=back

Removes a list of columns from the current schema_source in the current
schema_class and removes the autogenerated accessors from the current class.
Be careful to always use the column names, not their accessor aliases.

    $storage->remove_columns(qw/description/);

Before schema_instance is initialized, the columns to be removed are stored
internally, then removed from the schema_instance when it is initialized. If a
schema_instance already exists, the columns are removed directly from the
schema_source in the schema_instance itself.

=head2 remove_constraint

=over

=item Arguments: $column, $name

=back

Removes a named constraint for the given column from the current schema_source
in the current schema_class' constraints data structure.

    $storage->remove_constraint('id', 'Check Id Format' => \&constraint_uuid);

Constraints can only be removed before schema_instance is initialized.
A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if you try to remove a constraint and schema_instance is already
initialized.

Be careful to always use the column name, not its accessor alias if it has one.

=head2 remove_constraints

=over

=item Arguments: $column

=back

Removes all constraints for the given column from the current schema_source
in the current schema_class' constraints data structure.

    $storage->remove_constraints('id');

Constraints can only be removed before schema_instance is initialized.
A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if you try to remove a constraint and schema_instance is already
initialized.

Be careful to always use the column name, not its accessor alias if it has one.

=head2 schema_class

=over

=item Arguments: $schema_class

=back

Gets/sets the schema class to be used for database reading/writing.

    $storage->schema_class('MySchema');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

=head2 schema_instance

=over

=item Arguments: $schema_instance

=back

Gets/sets the schema instance to be used for database reading/writing. If no
instance exists, a new one will be created from the specified schema class.

    my $schema = MySchema->connect;
    
    $storage->schema_instance($schema);
    
When a new schema instance is created or assigned, it is cloned and the clone
is altered and used, leaving the original schema untouched.

See L<Handel::Manual::Schema|Handel::Manual::Schema> for more detailed
information about how the schema instance is configured.

=head2 schema_source

=over

=item Arguments: $source_name

=back

Gets/sets the result source name in the current schema class that will be used
to read/write data in the schema.

    $storage->schema_source('Foo');

See L<DBIx::Class::ResultSource/source_name>
for more information about setting the source name of schema classes.
By default, this will be the short name of the schema class in DBIx::Class
schemas.

By default, Handel::Storage looks for the "Carts" source when working with
Handel::Cart, the "Orders" source when working with Handel::Order and the 
"Items" source when working with Cart/Order items.

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
        schema_source => 'Foo'
    });
    
    # or
    
    my $storage = Handel::Storage-new;
    $storage->setup({
        schema_source  => 'Carts',
        cart_class     => 'CustomerCart'
    });

This is the same as doing:

    my $storage = Handel::Storage-new({
        schema_source  => 'Carts',
        cart_class     => 'CustomerCart'
    });

If you call setup on a storage instance or class that has already been
configured, its configuration will be reset, and it will be configured with the
new options. No attempt will be made to merged the options between the two.

If you pass in a schema_instance, it will be assigned last after all of the
other options have been applied.

=head2 table_name

=over

=item Arguments: $table_name

=back

Gets/sets the name of the table in the database to be used for this schema
source.

=head2 validation_class

=over

=item Arguments: $validation_class

=back

Gets/sets the validation class to be used when validating column values.
The default class is 
L<Handel::Components::Validation|Handel::Components::Validation>.
The validation class used should be subclass of
Handel::Components::Validation.

    $storage->validation_class('ValidateData');

A L<Handel::Exception::Storage|Handel::Exception::Storage> exception will be
thrown if the specified class can not be loaded.

See L<Handel::Components::Validation|Handel::Components::Validation> and
L<DBIx::Class::Validation|DBIx::Class::Validation> for more information on to
use data validation.

=head2 validation_module

=over

=item Arguments: $validation_module

=back

Gets/sets the module validation class should use to do its column data
validation. The default module is FormValidator::Simple. You can use any module
that is compatible with L<DBIx::Class::Validation|DBIx::Class::Validation>.

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

See L<Handel::Components::Validation|Handel::Components::Validation> and
L<DBIx::Class::Validation|DBIx::Class::Validation> for more information on
using data validation in Handel.

=head1 SEE ALSO

L<Handel::Manual::Storage>, L<Handel::Storage::Cart>, L<Handel::Storage::Order>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
