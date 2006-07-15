# $Id: Iterator.pm 1335 2006-07-15 02:43:12Z claco $
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
