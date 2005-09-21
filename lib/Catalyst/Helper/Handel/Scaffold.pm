# $Id: Scaffold.pm 844 2005-09-21 00:17:51Z claco $
package Catalyst::Helper::Handel::Scaffold;
use strict;
use warnings;
use Path::Class;

sub mk_stuff {
    my ($self, $helper, $dsn, $user, $pass, $cart, $order, $checkout) = @_;

    $cart     ||= 'Cart';
    $order    ||= 'Orders';
    $checkout ||= 'Checkout';

    $cart = $cart =~ /^(.*::(Model|M|C|Controller)?::)?(.*)$/i ? $3 : 'Cart';
    $order = $order =~ /^(.*::(Model|M|C|Controller)?::)?(.*)$/i ? $3 : 'Orders';
    $checkout = $checkout =~ /^(.*::(Model|M|C|Controller)?::)?(.*)$/i ? $3 : 'Checkout';

    my $app = $helper->{'app'};

    $helper->mk_component($app, 'view', 'TT', 'TT');
    $helper->mk_component($app, 'model', $cart, 'Handel::Cart', $dsn, $user, $pass);
    $helper->mk_component($app, 'model', $order, 'Handel::Order', $dsn, $user, $pass);
    $helper->mk_component($app, 'controller', $cart, 'Handel::Cart', $cart, $checkout);
    $helper->mk_component($app, 'controller', $order, 'Handel::Order', $order);
    $helper->mk_component($app, 'controller', $checkout, 'Handel::Checkout', $cart, $order, $cart, $order);
};

1;
__END__

=head1 NAME

Catalyst::Helper::Handel::Scaffold - Helper for creating Handel framework scaffolding

=head1 SYNOPSIS

    script/create.pl Handel::Scaffold <dsn> [<username> <password> <cartname> <ordername> <checkoutname>]
    script/create.pl Handel::Scaffold dbi:SQLite:dbname=handel.db

=head1 DESCRIPTION

A Helper for creating an entire cart/order/checkout framework scaffold.
If cartname isn't specified, Cart is assumed. If ordername isn't specified,
Orders is assumed. If no checkoutname is given, Checkout is assumed.

The cartname, ordername, and checkoutname arguments try to do the right thing with the
names given to them.

For example, you can pass the shortened class name without the MyApp::M/C, or pass the fully
qualified package name:

    MyApp::M::CartModel
    MyApp::Model::CartModel
    CartModel

In all three cases everything before M{odel)|C(ontroller) will be stripped and the class CartModel
will be used.

=head1 METHODS

=head2 mk_stuff

Makes Cart and Order models, Cart, Order and Checkout controllers, templates files
and a TT view for you.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Handel::Cart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/