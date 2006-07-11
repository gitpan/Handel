# $Id: Compat.pm 1318 2006-07-10 23:42:32Z claco $
package Handel::Compat;
use strict;
use warnings;
use Carp qw/cluck/;

BEGIN {
    cluck 'Handel::Compat is deprecated and will go away one a future release.';
};

sub add_columns {
    my $self = shift;
    
    $self->storage->add_columns(@_);
};

sub add_constraint {
    my ($self, $name, $column, $sub) = @_;
    
    $self->storage->add_constraint($column, $name, $sub);
};

sub cart_class {
    my ($self, $cart_class) = @_;

    if ($cart_class) {
        $self->storage->cart_class($cart_class);
    };

    return $self->storage->cart_class;
};

sub has_wildcard {
    my $filter = shift;

    for (values %{$filter}) {
        return 1 if $_ =~ /\%/;
    };

    return undef;
};

sub item_class {
    my ($self, $item_class) = @_;

    if ($item_class) {
        $self->storage->item_class($item_class);
    };

    return $self->storage->item_class;
};

sub iterator_class {
    my ($self, $iterator_class) = @_;

    if ($iterator_class) {
        $self->storage->iterator_class($iterator_class);
    };

    return $self->storage->iterator_class;
};

sub table {
    my ($self, $table) = @_;

    if ($table) {
        $self->storage->table_name($table);
    };

    return $self->storage->table_name;
};

sub uuid {
    my $class = shift || __PACKAGE__;

    $class->storage->new_uuid;
};

1;
__END__

=head1 NAME

Handel::Compat - Compatibility layer for old subclasses

=head1 SYNOPSIS

    package MyCustomCart;
    use strict;
    use warnings;
    use base qw/Handel::Compat Handel::Cart/;
    
    __PACKAGE__->add_columns(qw/foo bar/);
    
    1;

=head1 DESCRIPTION

Handel::Compat is a thin compatibility layer to ease the process of migrating
existing Cart/Order/Item subclasses. Simply load it before you load the
base class and it will remap your calls to things like
add_columns/add_constraints to the new storage layer.

B<This class is deprecated and will cease to be in some future version. Please
upgrade your code to use Handel::Base and Handel::Storage as soon as possible.>

=head1 METHODS

=head2 add_columns

=over

=item Arguments: @columns

=back

Adds the specified columns to the current storage instance. When upgrading,
convert this like so:

    #__PACKAGE__->add_columns(qw/foo bar baz/);
    __PACKAGE__->storage->add_columns(qw/foo bar baz/);

=head2 add_constraint

=over

=item Arguments: $name, $column, \&constraint

=back

Adds a new constraint to the current storage instance. When upgrading, convert
this like so:

    #__PACKAGE__->add_constraint('Check Id', id => \&constraint);
    __PACKAGE__->storage->add_constraint('id', 'Check Name', \&constraint);

=head2 cart_class

=over

=item Arguments: $cart_class

=back

Sets the name of the class to be used when returning or creating carts. When
upgrading, convert this like so:

    #__PACKAGE__->cart_class('MyCustomCart');
    __PACKAGE__->storage->cart_class('MyCustomCart');

=head2 item_class

=over

=item Arguments: $item_class

=back

Sets the name of the class to be used when returning or creating cart items.
When upgrading, convert this like so:

    #__PACKAGE__->item_class('MyCustomCart');
    __PACKAGE__->storage->item_class('MyCustomCart');

=head2 iterator_class

=over

=item Arguments: $iterator_class

=back

Gets/sets the name of the class to be used when iterating through results using
first/next. When upgrading, convert this like so:

    #__PACKAGE__->iterator_class('MyIterator');
    __PACKAGE__->storage->iterator_class('MyIterator');

=head2 table

=over

=item Arguments: $table

=back

Gets/sets the name of the table to be used. When upgrading, convert this like
so:

    #__PACKAGE__->table('foo');
    __PACKAGE__->storage->table_name('foo');

=head1 FUNCTIONS

=head2 has_wildcard

=over

=item Arguments: \%filter

=back

Inspects the supplied search filter to determine whether it contains wildcard
searching. Returns 1 if the filter contains SQL wildcards, otherwise it returns
C<undef>.

    has_wildcard({sku => '12%'});  # 1
    has_wildcard((sku => '123'));  # undef

=head2 uuid

Returns a new uuid string. When upgrading, convert this like so:

    #__PACKAGE__->uuid;
    __PACKAGE__->storage->new_uuid;

=head1 SEE ALSO

L<Handel::Base>, L<Handel::Storage>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
