# $Id: Storage.pm 1209 2006-06-06 02:03:03Z claco $
package Handel::Storage;
use strict;
use warnings;
use Handel::Exception qw/:try/;
use Handel::L10N qw/translate/;
use DBIx::Class::UUIDColumns;
use Scalar::Util qw/blessed/;

BEGIN {
    use base qw/Class::Data::Accessor/;

    __PACKAGE__->mk_classaccessor('_connection_info');
    __PACKAGE__->mk_classaccessor('_cart_class');
    __PACKAGE__->mk_classaccessor('_item_class');
    __PACKAGE__->mk_classaccessor('_schema_class');

    __PACKAGE__->mk_classaccessor('autoupdate' => 1);
    __PACKAGE__->mk_classaccessor('item_relationship' => 'items');
    __PACKAGE__->mk_classaccessor('iterator_class' => 'Handel::Iterator');
    __PACKAGE__->mk_classaccessor('schema_source');
    __PACKAGE__->mk_classaccessor('storage');
    __PACKAGE__->mk_classaccessor('validation_profile');
    __PACKAGE__->mk_classaccessor('constraints');
    __PACKAGE__->mk_classaccessor('default_values');
};

sub add_columns {
    my ($self, @columns) = @_;

    $self->schema_class->class($self->schema_source)->add_columns(@columns);

    $self->_map_columns(@columns);
};

sub remove_columns {
    my ($self, @columns) = @_;

    $self->schema_class->class($self->schema_source)->remove_columns(@columns);
};

sub add_constraint {
    my ($self, $name, $field, $constraint) = @_;
    my $constraints = $self->constraints || {};

    if (!exists $constraints->{$field}) {
        $constraints->{$field} = [];
    };

    push @{$constraints->{$field}}, $constraint;

    $self->constraints($constraints);
};

sub connection_info {
    my ($self, @args) = @_;

    if (scalar @args) {
        $self->_connection_info(\@args);
    };

    return @{$self->_connection_info || []};
};

sub inflate_result {
    my $self = shift;
    return bless {
        storage => $_[0]->result_class->inflate_result(@_)
    }, $self;
};

sub cart_class {
    my ($self, $cart_class) = @_;

    if ($cart_class) {
        eval "require $cart_class";
        $self->_cart_class($cart_class);
    };

    return $self->_cart_class;
};

sub item_class {
    my ($self, $item_class) = @_;

    if ($item_class) {
        eval "require $item_class";

        $self->_item_class($item_class);
    };

    return $self->_item_class;
};

sub schema_class {
    my ($self, $schema_class) = @_;
    my $package = ref $self || $self;

    if ($schema_class) {
        eval "require $schema_class";

        $self->_schema_class($schema_class);

        no strict 'refs';
        ${$package.'::_schema_instance'} = undef;
    };


    return $self->_schema_class;
};

sub schema_instance {
    my ($self, $schema_instance) = @_;
    my $package = ref $self || $self;

    no strict 'refs';

    if (blessed $schema_instance) {
        my $namespace = "$package\:\:".uc($self->uuid);
        $namespace =~ s/-//g;

        my $clone_schema = $schema_instance->compose_namespace($namespace);
        if (blessed $self) {
            $self->{'schema_instance'} = $clone_schema;
        } else {
            ${$package.'::_schema_instance'} = $clone_schema;
        };
        $self->_configure_schema_instance;
        $self->_schema_class(blessed $clone_schema);
    };

    if (!$self->{'schema_instance'} && !${$package.'::_schema_instance'}) {
        my $namespace = "$package\:\:".uc($self->uuid);
        $namespace =~ s/-//g;

        my $clone_schema = $self->schema_class->compose_namespace($namespace);
        my $schema = $clone_schema->connect($self->connection_info);

        if (blessed $self) {
            $self->{'schema_instance'} = $schema;
        } else {
            ${$package.'::_schema_instance'} = $schema;
        };
        $self->_configure_schema_instance;
        $self->_schema_class(blessed $schema);
    };

    return $self->{'schema_instance'} || ${$package.'::_schema_instance'};
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

    if ($item_class) {
        eval "require $item_class";

        $item_source_class = $schema_instance->class($item_class->schema_source);
    };

    my $source = $schema_instance->source($schema_source);
    $source->resultset_class($iterator_class);

    if ($item_class) {
        if ($source->has_relationship($item_relationship)) {
            $source->related_source($item_relationship)->resultset_class($iterator_class);
        } else {
            throw Handel::Exception(-text =>
                translate('The source [_1] has no relationship named [_2].', $schema_source, $item_relationship)
            );
        };
    };

    $schema_instance->storage->dbh->{HandleError} = $self->can('process_error');

    # load class and item class validation
    if (my $profie = $self->validation_profile) {
        $source_class->load_components('+Handel::Components::Validation');
        $source_class->validation_profile($profie);
    };
    if ($item_class && $item_class->validation_profile) {
        $item_source_class->load_components('+Handel::Components::Validation');
        $item_source_class->validation_profile($item_class->validation_profile);
    };

    # load class and item class constraints
    if (my $constraints = $self->constraints) {
        $source_class->load_components('+Handel::Components::Constraints');
        $source_class->constraints($constraints);
    };
    if ($item_class && $item_class->constraints) {
        $item_source_class->load_components('+Handel::Components::Constraints');
        $item_source_class->constraints($item_class->constraints);
    };

    # load class and item class default values
    if (my $defaults = $self->default_values) {
        $source_class->load_components('+Handel::Components::DefaultValues');
        $source_class->default_values($defaults);
    };
    if ($item_class && $item_class->default_values) {
        $item_source_class->load_components('+Handel::Components::DefaultValues');
        $item_source_class->default_values($item_class->default_values);
    };
};

sub setup_column_accessors {
    my $self = shift;
    my @columns = $self->schema_class->source($self->schema_source)->columns;

    $self->_map_columns(@columns);
};

sub update {
    my $self = shift;

    return $self->storage->update;
};

sub uuid {
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

sub _map_columns {
    my ($self, @columns) = @_;
    my $source = $self->schema_class->source($self->schema_source);

    no strict 'refs';
    foreach my $column (@columns) {
        my $accessor = $source->column_info($column)->{'accessor'} || $column;
        *{"$self\::$accessor"} = sub {
            my ($self, $value) = @_;

            if (scalar @_ == 2) {
                $self->storage->$column($value);
                $self->storage->update if $self->autoupdate;
            };

            return $self->storage->$column;
        };
    };
};

sub _unmap_columns {
    my ($self, @columns) = @_;
    my $source = $self->schema_class->source($self->schema_source);

    no strict 'refs';
    foreach my $column (@columns) {
        my $accessor = $source->column_info($column)->{'accessor'} || $column;
        *{"$self\::$accessor"} = undef;
    };
};

1;
__END__

=head1 NAME

Handel::Storage - Generic storage layer for cart/order reads/writes

=head1 SYNOPSIS

    use MyCustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Storage/;

    __PACKAGE__->schema_class('MyCartSchema');
    __PACKAGE__->schema_source('Carts');
    __PACKAGE__->item_class('MyCustomCart::Items');
    __PACKAGE__->setup_column_accessors;

    1;

=head1 DESCRIPTION

Handel::Storage is used as an intermediary between Handel::Cart/Handel::Order
and the schema classes used for reading/writing to the database.

=head1 METHODS

=head2 add_columns(@columns)

Adds a list of columns to the current schema_source in the current schema_class
and maps the new columns to accessors in the current class.

Be careful to always use the column names, not their accessor aliases.

=head2 add_constraint($name, $column, \&sub)

Adds a constraint for the given column to the current schema_source in the
current schema_class. During intert/update operations, the constraint subs will
be called upon to validation the specified columns data.

=head2 autoupdate([0|1])

Gets/sets the autoupdate flag for the current schema_source. When set to 1, an
update request will be made to the database for every field change. When set to
0, no updated data will be sent to the database until C<update> is called.

The default is 1.

=head2 connection_info([$dsn, $username, $password, \%attr])

Gets/sets the connection information used when connecting to the database.

=head2 item_class([$class])

Gets/sets the item class to be used when returning cart/order items.

=head2 cart_class([$class])

Gets/sets the cart class to be used when creating orders from carts.

=head2 item_relationship([$relationship])

Gets/sets the name of the schema relationship between carts and items.
The default item relationship is 'items'.

=head2 inflate_result

This method is called by L<Handel::Iterator> to inflate objects returned by
first/next into the current class.

=head2 iterator_class([$class])

Gets/sets the class used for iterative resultset operations. The default
iterator is L<Handel::Iterator>.

=head2 process_error

This method accepts errors from DBI using $dbh->{HandelError} and converts them
into Handel::Exception objects before throwing the error.

=head2 remove_columns(@columns)

Removes a list of columns from the current schema_source in the current
schema_class and removes the autogenerated accessors from the current class.
This is useful if you want to just subclass an existing schema and only need to
remove and/or add a few fields, rather than create the entire news schema from
scratch.

Be careful to always use the column names, not their accessor aliases.

=head2 schema_class([$class])

Gets/sets the schema class to be used for database reading/writing.

=head2 schema_instance([$instance])

Gets/sets the schema instance to be used for database reading/writing. If no
instance exists, a new one will be created from the specified schema class.

=head2 schema_source([$source])

Gets/sets the result source name in the current schema class to use for the
current class.

    __PACKAGE__->schema_source('Foo');

See L<DBIx::Class::ResultSource/"source_name"> for more information about
setting the source name of schema classes. By default, this will be the short
name of the schema class.

By default, Handel::Storage looks for the "Carts" source when working with
Handel::Cart, and the "Orders" source when working with Handel::Order.

=head2 setup_column_accessors

This method loops through the existing columns in the schema source for the
current schema class and maps them to accessors in the current class.

If you have defined columns in your schema to have an accessor that is different
than the column name, that will be used instead.

See L<DBIx::Class::ResultSource/"add_columns"> for more information on aliasing
column accessors.

=head2 storage

Returns the storage object for the current class instance. There should be no
need currently to access this directly.

=head2 update

Sends all of the column updates to the database. If C<autoupdate> is off, you
mist call this to save your changes or they will be lost when the object goes
out of scope.

=head2 uuid

Returns a new uuid/guid string in the form of
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.

See <DBIx::Class::UUIDColumns> for more information on how uuids are generated.

=head2 validation_profile([\%profile])

Gets/sets the profile to be used for validating the column data before
inserts/updates. This is an alternative approach to constraints that uses
L<DBIx::Class::Validation> and L<FormValidator::Simple>.

=head1 SEE ALSO

L<Handel::Cart::Schema>, L<Handel::Order::Schema>, L<Handel::Schema>,
L<DBIx::Class::UUIDColumns>, L<DBIx::Class::ResultSource>,
L<DBIx::Class::Validation>, L<FormValidator::Simple>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

