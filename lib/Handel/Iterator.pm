# $Id: Iterator.pm 1354 2006-08-06 00:11:31Z claco $
package Handel::Iterator;
use strict;
use warnings;
use overload
        '0+'     => \&count,
        'bool'   => sub { 1; },
        fallback => 1;

BEGIN {
    use base qw/DBIx::Class::ResultSet Class::Accessor::Grouped/;
    __PACKAGE__->mk_group_accessors('simple', qw/iterator/);
};

sub all {
    my $self = shift;

    if ($self->iterator) {
        my @all = map {
            $self->result_class->create_instance($_)
        } $self->iterator->all;

        return @all;
    } else {
        return $self->next::method(@_);
    };
};

sub first {
    my $self = shift;

    if ($self->iterator) {
        my $result = $self->iterator->first;

        return $self->result_class->create_instance($result);
    } else {
        return $self->next::method(@_);    
    };
};

sub count {
    my $self = shift;

    if ($self->iterator) {
        return $self->iterator->count;
    } else {
        return $self->next::method(@_);
    };
};

sub next {
    my $self = shift;

    if ($self->iterator) {
        my $result = $self->iterator->next;

        return $self->result_class->create_instance($result);
    } else {
        return $self->next::method(@_);    
    };
};

sub reset {
    my $self = shift;

    if ($self->iterator) {
        return $self->iterator->reset;
    } else {
        return $self->next::method(@_);
    };
};

sub create_iterator {
    my ($self, $iterator, $result_class) = @_;

    return bless {
        iterator     => $iterator,
        result_class => $result_class
    }, ref $self || $self;
};

1;
__END__

=head1 NAME

Handel::Iterator - Iterator class used for collection looping

=head1 SYNOPSIS

    use Handel::Cart;
    
    my $cart = Handel::Cart->new({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });
    
    my $iterator = $cart->items;
    while (my $item = $iterator->next) {
        print $item->sku;
        print $item->price;
        print $item->total;
    };

=head1 DESCRIPTION

Handel::Iterator is used internally by Handel::Cart/Order/Item to iterate
through collections of objects and items. At this point, there should be no
reason to use it directly.

=head1 METHODS

=head2 all

Returns all results from the resultset as a list.

    my $it = Handel::Cart->load({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    my @carts = $it->all;

=head2 create_iterator

=over

=item Arguments: $iterator, $result_class

=back

Returns a new iterator object that iterates through the supplied iterator and
calls C<create_instance> on each C<result_class> for each result.

    my $results_it = $storage->search;
    my $carts_it = $storage->iterator_class->create_iterator($results_it, 'Handel::Cart');

This is used by the interface classes to wrap results returned by the storage
layer.

=head2 first

Returns the first result or undef if there are no results.

    my $it = Handel::Cart->load({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    my $carts = $it->first;

=head2 next

Returns the next result or undef if there are no results.

    my $it = Handel::Cart->load({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    while ($cart = $it->next) {
        print $cart->name;
    };

=head2 count

Returns the number of results.

    my $it = Handel::Cart->load({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    my $cart_count = $it->count;

=head2 reset

Resets the current result position back to the first result.

    my $it = Handel::Cart->load({
        shopper => '11111111-1111-1111-1111-111111111111'
    });
    
    while (my $cart = $it->next) {
        print $cart->name;
    };
    
    $it->reset;
    
    while (my $cart = $it->next) {
        print $cart->name;
    };

=head1 SEE ALSO

L<Handel::Cart>, L<Handel::Order>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
