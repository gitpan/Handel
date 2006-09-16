# $Id: Results.pm 1416 2006-09-15 03:45:35Z claco $
## no critic (ProhibitAmbiguousNames)
package Handel::Iterator::Results;
use strict;
use warnings;
use overload
        '0+'     => \&count,
        'bool'   => sub { 1; },
        fallback => 1;

BEGIN {
    use base qw/Handel::Iterator/;
};

sub all {
    my $self = shift;

    return map {$self->create_result($_)} $self->data->all;
};

sub count {
    return shift->data->count;
};

sub first {
    my $self = shift;
    my $result = $self->data->first;

    return $result ? $self->create_result($result) : undef;
};

sub last {
    my $self = shift;
    my $result = $self->data->last;

    return $result ? $self->create_result($result) : undef;
};

sub next {
    my $self = shift;
    my $result = $self->data->next;

    return $result ? $self->create_result($result) : undef;
};

sub reset {
    return shift->data->reset;
};
sub create_result {
    my ($self, $result) = @_;

    return $self->result_class->create_instance($result);
};

1;
__END__

=head1 NAME

Handel::Iterator::Results - Iterator class used for collection looping storage iterators

=head1 SYNOPSIS

    my $iterator = $storage->search;
    
    my $results = Handel::Iterator::Results->new({
        data         => $iterator,
        result_class => 'MyCart'
    });
    
    while (my $cart = $results->next) {
        print $cart->id;
    };

=head1 DESCRIPTION

Handel::Iterator::Results is a used to iterate through result iterators returned
by storage search/search_items operations. The only different between this, and
Handel::Iterator::DBIC and Handel::Iterator::List is that it inflates results
into the interface classes rather than into storage results.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: \%options

=back

Creates a new iterator object. The following options are available:

    my $iterator = $storage->search;
    
    my $results = Handel::Iterator::Results->new({
        data         => $iterator,
        result_class => 'MyCart'
    });

    my $cart = $results->first;
    print ref $cart; # MyCart

=over

=item data

The data to be iterated through. This should be an iterator returns by storage.

=item result_class

The name of the class that each result should be inflated into.

=back

=head1 METHODS

=head2 all

Returns all results from current iterator.

    foreach my $result ($iterator->all) {
        print $result->method;
    };

=head2 count

Returns the number of results in the current iterator.

    my $count = $iterator->count;

=head2 create_result

=over

=item Arguments: $result

=back

Returns a new result class object based on the specified result objects.

This method is used by methods like C<first> and C<next> to to create result
class objects. There is probably no good reason to use this method directly.

=head2 first

Returns the first result or undef if there are no results.

    my $first = $iterator->first;

=head2 last

Returns the last result or undef if there are no results.

    my $last = $iterator->last;

=head2 next

Returns the next result or undef if there are no results.

    while (my $result = $iterator->next) {
        print $result->method;
    };

=head2 reset

Resets the current result position back to the first result.

    while (my $result = $iterator->next) {
        print $result->method;
    };
    
    $iterator->reset;
    
    while (my $result = $iterator->next) {
        print $result->method;
    };

=head1 SEE ALSO

L<Handel::Iterator::List>, L<Handel::Iterator::DBIC>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
