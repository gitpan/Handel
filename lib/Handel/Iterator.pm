# $Id: Iterator.pm 1188 2006-05-31 21:58:27Z claco $
package Handel::Iterator;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class::ResultSet/;
};

sub all {
    return shift->next::method(@_);
};

sub first {
    return shift->next::method(@_);
};

sub count {
    return shift->next::method(@_);
};

sub next {
    return shift->next::method(@_);
};

sub reset {
    return shift->next::method(@_);
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

C<Handel::Iterator> is used internally by C<Handel::Cart> to iterate through
collections of carts and cart items. At this point, there should be no reason to
use it directly.

=head1 METHODS

=head2 all

Returns all results from the resultset as a list.

=head2 first

Returns the first result or undef if there are no results.

=head2 next

Returns the next result or undef if there are no results.

=head2 count

Returns the number of results.

=head2 reset

Resets the current result position back to the first result.

=head1 SEE ALSO

L<Handel::Cart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
