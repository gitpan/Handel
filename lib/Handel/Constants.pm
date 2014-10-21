# $Id: Constants.pm 536 2005-06-22 23:41:59Z claco $
package Handel::Constants;
use strict;
use warnings;
use vars qw(@EXPORT_OK %EXPORT_TAGS);

BEGIN {
    use base 'Exporter';
};

use constant CART_MODE_APPEND  => 3;
use constant CART_MODE_MERGE   => 2;
use constant CART_MODE_REPLACE => 1;

use constant CART_TYPE_TEMP    => 0;
use constant CART_TYPE_SAVED   => 1;

use constant ORDER_TYPE_TEMP   => 0;
use constant ORDER_TYPE_SAVED  => 1;

use constant RETURNAS_AUTO     => 0;
use constant RETURNAS_ITERATOR => 1;
use constant RETURNAS_LIST     => 2;
use constant RETURNAS_ARRAY    => 2;

use constant CHECKOUT_PHASE_INITIALIZE => 1;
use constant CHECKOUT_PHASE_VALIDATE   => 2;
use constant CHECKOUT_PHASE_AUTHORIZE  => 4;
use constant CHECKOUT_PHASE_DELIVER    => 8;
use constant CHECKOUT_DEFAULT_PHASES   => [CHECKOUT_PHASE_VALIDATE,
                                           CHECKOUT_PHASE_AUTHORIZE,
                                           CHECKOUT_PHASE_DELIVER];

use constant CHECKOUT_STATUS_OK        => 1;
use constant CHECKOUT_STATUS_ERROR     => 2;

use constant CHECKOUT_HANDLER_OK       => 1;
use constant CHECKOUT_HANDLER_DECLINE  => 2;
use constant CHECKOUT_HANDLER_ERROR    => 4;

@EXPORT_OK = qw(CART_MODE_APPEND
                CART_MODE_MERGE
                CART_MODE_REPLACE
                CART_TYPE_SAVED
                CART_TYPE_TEMP
                ORDER_TYPE_TEMP
                ORDER_TYPE_SAVED
                RETURNAS_AUTO
                RETURNAS_ITERATOR
                RETURNAS_LIST
                RETURNAS_ARRAY
                CHECKOUT_PHASE_INITIALIZE
                CHECKOUT_PHASE_VALIDATE
                CHECKOUT_PHASE_AUTHORIZE
                CHECKOUT_PHASE_DELIVER
                CHECKOUT_DEFAULT_PHASES
                CHECKOUT_STATUS_OK
                CHECKOUT_STATUS_ERROR
                CHECKOUT_HANDLER_OK
                CHECKOUT_HANDLER_DECLINE
                CHECKOUT_HANDLER_ERROR
                str_to_const
);

%EXPORT_TAGS =
    (   all  => \@EXPORT_OK,
        cart => [ qw(CART_MODE_APPEND
                     CART_MODE_MERGE
                     CART_MODE_REPLACE
                     CART_TYPE_SAVED
                     CART_TYPE_TEMP
        )],
        order => [ qw(ORDER_TYPE_TEMP
                      ORDER_TYPE_SAVED
        )],
        returnas => [ qw(RETURNAS_AUTO
                         RETURNAS_ITERATOR
                         RETURNAS_LIST
                         RETURNAS_ARRAY
        )],
        checkout => [ qw(CHECKOUT_PHASE_INITIALIZE
                         CHECKOUT_PHASE_VALIDATE
                         CHECKOUT_PHASE_AUTHORIZE
                         CHECKOUT_PHASE_DELIVER
                         CHECKOUT_DEFAULT_PHASES
                         CHECKOUT_STATUS_OK
                         CHECKOUT_STATUS_ERROR
                         CHECKOUT_HANDLER_OK
                         CHECKOUT_HANDLER_DECLINE
                         CHECKOUT_HANDLER_ERROR
        )]
    );

sub str_to_const {
    my $str = shift;

    return __PACKAGE__->can($str) ? __PACKAGE__->$str : undef ;
};

1;
__END__

=head1 NAME

Handel::Constants - Common constants used in Handel

=head1 SYNOPSIS

    use Handel::Constants qw(:cart);

    my $cart = Handel::Cart->new({
        shopper => 'D597DEED-5B9F-11D1-8DD2-00AA004ABD5E'
    });

    if ($cart->type == CART_TYPE_SAVED) {
        print 'This cart is saved!';
    };

=head1 DESCRIPTION

C<Handel::Constants> contains a set of constants used throughout C<Handel>. It
may be useful (or even a good idea) to use these in your code. :-)

By default, C<Handel::Constants> export C<nothing>. Use can use the export tags
below to export all or only certain groups of constants.

=head1 METHODS

=head2 str_to_const($)

Converts a string version of a constant into that constants value.

    print str_to_const('CART_TYPE_SAVED');  ## prints 1

=head1 CONSTANTS

=head2 CART_MODE_APPEND

All items in the saved cart will be appended to the list of items in the current
cart. No effort will be made to merge items with the same SKU and duplicates
will be left as seperate items.

=head2 CART_MODE_MERGE

If an item with the same SKU exists in both the current cart and the saved cart,
the quantity of each will be added together and applied to the same sku in the
current cart. Any price differences are ignored and we assume that the price in
the current cart is more up to date.

=head2 CART_MODE_REPLACE

All items in the current cart will be deleted before the saved cart is restored
into it. This is the default if no mode is specified.

=head2 CART_TYPE_SAVED

Marks the cart as permanent. Carts with this value set should never be
automatically reaped from the database during cleanup.

=head2 CART_TYPE_TEMP

Any cart with this type could be purged form the database during cleanup at any
time.

=head2 RETURNAS_AUTO

When calling C<load> or C<items> on C<Handel::Cart>, it will attempt to return
the most appropriate object. In list context, it will return a list. In
scalar context, it will return a C<Handel::Iterator> object. If the iterator
only contains one item, that item will be returns instead.

=head2 RETURNAS_ITERATOR

Always return a C<Handel::Iterator> object regardless of context or the amount
of retults.

=head2 RETURNAS_LIST

Always return a list regardless of context or the amount of results.

=head2 RETURNAS_ARRAY

Same as C<RETURNAS_LIST>

=head1 EXPORT_TAGS

The following C<%EXPORT_TAGS> are defined for C<Handel::Constants>. See
L<Exporter> for further details on using export tags.

=head2 :all

This exports all constants found in this module.

=head2 :cart

This exports all C<CART_*> constants in this module.

=head2 :returnas

This exports all C<RETURNAS_*> constants in this module.

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
