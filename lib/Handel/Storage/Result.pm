package Handel::Storage::Result;
use strict;
use warnings;

BEGIN {
    use base qw/Class::Accessor::Grouped/;
    __PACKAGE__->mk_group_accessors('simple', qw/storage_result storage/);
};

sub delete {
    return $_[0]->storage_result->delete;
};

sub update {
    return shift->storage_result->update(@_);
};

sub add_item {
    return $_[0]->storage->add_item(@_)
};

sub delete_items {
    return $_[0]->storage->delete_items(@_);
};

sub count_items {
    return $_[0]->storage->count_items(@_);
};

sub search_items {
    return $_[0]->storage->search_items(@_);
};

sub items {
    return shift->search_items(@_);
};

sub create_instance {
    my ($self, $result, $storage) = @_;
    my $class = blessed $self || $self;

    return bless {
        storage_result => $result,
        storage        => $storage
    }, $class;
};

sub AUTOLOAD {
    my $self = shift;
    return if (our $AUTOLOAD) =~ /::DESTROY$/;

    $AUTOLOAD =~ s/^.*:://;

    return $self->storage_result->$AUTOLOAD(@_);
};

1;
__END__

=head1 NAME

Handel::Storage::Result - Generic result object returned by storage operations

=head1 SYNOPSIS

    use Handel::Storage::Cart;
    
    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    print $result->id;
    print $result->name;

=head1 DESCRIPTION

Handel::Storage::Result is a generic wrapper around objects returned by various
Handel::Storage operations. Its main purpose is to abstract storage result
objects away from the Cart/Order/Item classes that use them. Each result is
assumed to exposed methods for each 'property' or 'column' it has, as well as
support the methods described below.

While Handel::Storage currently operates on DBIx::Class schemas and uses DBIC
resultset results, it should be possible to use a custom storage object to
return results based on other operations, like SOAP/XMLRPC calls.

=head1 METHODS

=head2 AUTOLOAD

Maps undefined method calls to the underlying result object.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    print $result->shopper;
    
    #is really this:
    print $result->storage_result->shopper;

=head2 add_item

=over

=item Arguments: \%data

=back

Adds a new item to the current result, returning a storage result object.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    my $item = $result->add_item({
        sku => 'ABC123'
    });
    
    print $item->sku;

This method is just a convenience method that forwards to the implementation in
the current storage object. See L<Handel::Storage/add_item> for more details.

=head2 count_items

Returns the number of items associated with the current result.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    $result->add_item({
        sku => 'ABC123'
    });
    
    print $result->count_items; # 1

This method is just a convenience method that forwards to the implementation in
the current storage object. See L<Handel::Storage/count_items> for more details.

=head2 create_instance

=over

=item Arguments: $result, $storage

=back

Creates a new instance of Handel::Storage::Result, storing the underlying result
for use by C<AUTOLOAD>.

    my $schema = $storage->schema_instance;
    my $row    = $schema->resultset($storage->schema_source)->create({
        col1 => 'foo',
        col2 => 'bar'
    });
    my $result = $storage->result_class->create_instance($dbresult, $storage);
    
    print $result->foo;

This method is used by the storage object to create storage results from
resultset results and assign the generic results with the given storage object.

=head2 delete

Deletes the current result and all of it's associated items from the current
storage.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    $result->add_item({
        sku => 'ABC123'
    });
    
    $result->delete;

=head2 delete_items

=over

=item Arguments: \%filter

=back

Deletes items matching the filter from the current result.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    $result->add_item({
        sku => 'ABC123'
    });
    
    $result->delete_items({
        sku => 'ABC%'
    });

This method is just a convenience method that forwards to the implementation in
the current storage object. See L<Handel::Storage/delete_items> for more details.

=head2 inflate_result

This method is called by the iterator class to create a new storage result
for first/next operations. This method is only used by DBIC resultset-based
iterators. For non DBIC iterators, and other result creation, use
C<create_instance> instead.

=head2 items

Same as L</search_items>.

=head2 search_items

=over

=item Arguments: \%filter

=back

Returns items matching the filter associated with the current result.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->search({
        id => '11111111-1111-1111-1111-111111111111'
    });
    
    my $iterator = $result->search_items;

This method is just a convenience method that forwards to the implementation in
the current storage object. See L<Handel::Storage/search_items> for more details.

=head2 storage_result

Returns the original result created by the underlying storage mechanism. This
will be the DBIx::Class::Row result returned from the current schema.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    my @columns = $result->storage_result->columns;

It is probably unwise to use the storage result directly anywhere outside of the
current result object.

=head2 storage

Returns a reference to the storage object used to create the current storage
result.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    print $result->storage; # Handel::Storage::Cart

=head2 update

=over

=item Arguments: \%data

=back

Updates the current result with the date specified.

    my $storage = Handel::Storage::Cart->new;
    my $result = $storage->create({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    $result->update({
        name => 'My Cart'
    });

=head1 SEE ALSO

L<Handel::Storage>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
