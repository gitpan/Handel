# $Id: /local/CPAN/Handel/lib/Catalyst/Helper/Controller/Handel/Cart.pm 1058 2007-08-23T02:05:31.088429Z claco  $
## no critic (ProhibitCaptureWithoutTest)
package Catalyst::Helper::Controller::Handel::Cart;
use strict;
use warnings;

BEGIN {
    use Catalyst 5.7001;
    use Catalyst::Utils;
    use Path::Class;
};

=head1 NAME

Catalyst::Helper::Controller::Handel::Cart - Helper for Handel::Cart Controllers

=head1 SYNOPSIS

    script/create.pl controller <newclass> Handel::Cart [<modelclass> <checkoutcontroller>]
    script/create.pl controller Cart       Handel::Cart Cart Checkout

=head1 DESCRIPTION

A Helper for creating controllers based on Handel::Cart objects. If no modelclass
is specified, ::M::Cart is assumed.

Both the modelclass and checkoutcontroller arguments try to do the right thing with the
names given to them.

For example, you can pass the shortened class name without the MyApp::M/C, or pass the fully
qualified package name:

    MyApp::M::CartModel
    MyApp::Model::CartModel
    CartModel

In all three cases everything before M{odel)|C(ontroller) will be stripped and the class CartModel
will be used.

B<The code generated by this helper requires FormValidator::Simple and YAML to be installed to operate.>

=head1 METHODS

=head2 mk_compclass

Makes a Handel::Cart Controller class and template files for you.

=cut

sub mk_compclass {
    my ($self, $helper, $model, $checkout) = @_;
    my $file = $helper->{'file'};
    my $dir  = dir($helper->{'base'}, 'root', $helper->{'uri'});

    $model     ||= 'Cart';
    $checkout  ||= 'Checkout';

    $model =~ /^(.*::M(odel)?::)?(.*)$/i;
    $model = $3 ? $3 : 'Cart';
    $helper->{'model'} = $model;

    $checkout =~ /^(.*::C(ontroller)?::)?(.*)$/i;
    my $couri = $3 ? lc($3) : 'checkout';
    $couri =~ s/::/\//g;
    $helper->{'couri'} = $couri;


    $helper->{'action'} = Catalyst::Utils::class2prefix($helper->{'class'});

    $helper->mk_dir($dir);
    $helper->render_file('controller', $file);

    $helper->render_file('default', file($dir, 'default'));
    $helper->render_file('list', file($dir, 'list'));
    $helper->render_file('errors', file($dir, 'errors'));
    $helper->render_file('profiles', file($dir, 'profiles.yml'));
    $helper->render_file('messages', file($dir, 'messages.yml'));

    $helper->render_file('products', file($helper->{'base'}, 'root', 'static', 'products.htm'));

    return 1;
};

=head2 mk_comptest

Makes a Handel::Cart Controller test for you.

=cut

sub mk_comptest {
    my ($self, $helper) = @_;
    my $test = $helper->{'test'};

    $helper->render_file('test', $test);

    return 1;
};

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Handel::Cart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

=cut

1;
__DATA__

=begin pod_to_ignore

__controller__
package [% class %];
use strict;
use warnings;

BEGIN {
    use base qw/Catalyst::Controller/;
    use Handel::Constants qw/:cart/;
    use FormValidator::Simple 0.17;
    use YAML 0.65;
};

=head1 NAME

[% class %] - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 COMPONENT

=cut

sub COMPONENT {
    my $self = shift->NEXT::COMPONENT(@_);

    $self->{'validator'} = FormValidator::Simple->new;
    $self->{'validator'}->set_messages(
        $_[0]->path_to('root', '[% action %]', 'messages.yml')
    );

    $self->{'profiles'} = YAML::LoadFile($_[0]->path_to('root', '[% action %]', 'profiles.yml'));

    return $self;
};

=head2 default 

Default action when browsing to [% uri %]/. If no session exists, or the shopper
id isn't set, no cart will be loaded. This keeps non-shoppers like Google
and others from wasting sessions and cart records for no good reason.

=cut

sub default : Private {
    my ($self, $c) = @_;
    $c->stash->{'template'} = '[% action %]/default';

    if ($c->sessionid && $c->session->{'shopper'}) {
        if (my $cart = $c->forward('load')) {
            $c->stash->{'cart'} = $cart;
            $c->stash->{'items'} = $cart->items;
        };
    };

    return;
};

=head2 add

=over

=item Parameters: (See L<Handel::Cart/add>)

=back

Adds an item to the current cart during POST.

    [% uri %]/add/

=cut

sub add : Local {
    my ($self, $c) = @_;
    
    if ($c->req->method eq 'POST') {
        my $cart = $c->forward('create');
        $cart->add($c->req->params);
    };

    $c->res->redirect($c->uri_for('[% uri %]/'));
};

=head2 clear

Clears all items form the current shopping cart during POST.

    [% uri %]/clear/

=cut

sub clear : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        if (my $cart = $c->forward('load')) {
            $cart->clear;
        };
    };

    $c->res->redirect($c->uri_for('[% uri %]/'));
};

=head2 create

Creats a new temporary shopping cart or returns the existing cart, creating a
new session shopper id if necessary.

    my $cart = $c->forward('create');

=cut

sub create : Private {
    my ($self, $c) = @_;

    if (!$c->session->{'shopper'}) {
        $c->session->{'shopper'} = $c->model('[% model %]')->storage->new_uuid;
    };

    if (my $cart = $c->forward('load')) {
        return $cart;
    } else {
        return $c->model('[% model %]')->create({
            shopper => $c->session->{'shopper'},
            type    => CART_TYPE_TEMP
        });
    };

    return;
};

=head2 delete

=over

=item Parameters: id

=back

Deletes an item from the current shopping cart during a POST.

    [% uri %]/delete/

=cut

sub delete : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        if ($c->forward('validate')) {
            if (my $cart = $c->forward('load')) {
                $cart->delete({
                    id => $c->req->params->{'id'}
                });

                $c->res->redirect($c->uri_for('[% uri %]/'));
            };
        } else {
            $c->forward('default');
        };
    } else {
        $c->res->redirect($c->uri_for('[% uri %]/'));
    };

    return;
};

=head2 destroy

=over

=item Parameters: id

=back

Deletes the specified saved cart and all of its items during a POST.

    [% uri %]/destroy/

=cut

sub destroy : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        if ($c->forward('validate')) {
            my $cart = $c->model('[% model %]')->search({
                id      => $c->req->params->{'id'},
                shopper => $c->session->{'shopper'},
                type    => CART_TYPE_SAVED
            })->first;

            if ($cart) {
                $cart->destroy;
            } else {
                warn "not cart";
            };

            $c->res->redirect($c->uri_for('[% uri %]/list/'));
        } else {
            $c->forward('list');
        };
    } else {
        $c->res->redirect($c->uri_for('[% uri %]/'));
    };

    return;
};

=head2 list

Displays a list of the current shoppers saved carts/wishlists.

    [% uri %]/list/

=cut

sub list : Local {
    my ($self, $c) = @_;
    $c->stash->{'template'} = '[% action %]/list';

    if ($c->sessionid && $c->session->{'shopper'}) {
        my $carts = $c->model('[% model %]')->search({
            shopper => $c->session->{'shopper'},
            type    => CART_TYPE_SAVED
        });

        $c->stash->{'carts'} = $carts;
    };

    return;
};

=head2 load

Loads the shoppers current cart.

    my $cart = $c->forward('load');

=cut

sub load : Private {
    my ($self, $c) = @_;

    if ($c->sessionid && $c->session->{'shopper'}) {
        return $c->model('[% model %]')->search({
            shopper => $c->session->{'shopper'},
            type    => CART_TYPE_TEMP
        })->first;
    };

    return;
};

=head2 restore

=over

=item Parameters: id

=back

Restores a saved shopping cart into the shoppers current cart during a POST.

    [% uri %]/restore/

=cut

sub restore : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        if ($c->forward('validate')) {
            if (my $cart = $c->forward('create')) {
                $cart->restore({
                    id      => $c->req->param('id'),
                    shopper => $c->session->{'shopper'},
                    type    => CART_TYPE_SAVED
                }, $c->req->param('mode') || CART_MODE_APPEND);

                $c->res->redirect($c->uri_for('[% uri %]/'));
            };
        } else {
            $c->forward('list');
        };
    } else {
        $c->res->redirect($c->uri_for('[% uri %]/'));
    };

    return;
};

=head2 save

=over

=item Parameters: name

=back

Saves the current cart with the name specified.

    [% uri %]/save/

=cut

sub save : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        if ($c->forward('validate')) {
            if (my $cart = $c->forward('load')) {
                $cart->name($c->req->param('name') || 'My Cart');
                $cart->save;

                $c->res->redirect($c->uri_for('[% uri %]/list/'));
            };
        } else {
            $c->forward('default');
        };
    } else {
        $c->res->redirect($c->uri_for('[% uri %]/'));
    };

    return;
};

=head2 update

=over

=item Parameters: quantity

=back

Updates the specified cart item qith the quantity given.

    [% uri %]/update/

=cut

sub update : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        if ($c->forward('validate')) {
            if (my $cart = $c->forward('load')) {
                my $item = $cart->items({
                    id => $c->req->param('id')
                })->first;

                if ($item) {
                    $item->quantity($c->req->param('quantity'));
                };

                $c->res->redirect($c->uri_for('[% uri %]/'));
            };
        } else {
            $c->forward('default');
        };
    } else {
        $c->res->redirect($c->uri_for('[% uri %]/'));
    };

    return;
};

=head2 validate

Validates the current form parameters using the profile in profiles.yml that
matches the current action.

    if ($c->forward('validate')) {
    
    };

=cut

sub validate : Private {
    my ($self, $c) = @_;

    $self->{'validator'}->results->clear;

    my $results = $self->{'validator'}->check(
        $c->req,
        $self->{'profiles'}->{$c->action}
    );

    if ($results->success) {
        return $results;
    } else {
        $c->stash->{'errors'} = $results->messages($c->action);
    };

    return;
};

=head1 AUTHOR

A clever guy

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__test__
use Test::More tests => 3;
use strict;
use warnings;

use_ok('Catalyst::Test', '[% app %]');
use_ok('[% class %]');

ok(request('[% uri %]')->is_success, 'Request should succeed');
__default__
[% TAGS [- -] -%]
[% USE HTML %]
<h1>Your Shopping Cart</h1>
[% INCLUDE [- action -]/errors %]
[% IF items.count %]
    <table border="0" cellpadding="3" cellspacing="5">
        <tr>
            <th align="left">SKU</th>
            <th align="left">Description</th>
            <th align="right">Price</th>
            <th align="center">Quantity</th>
            <th align="right">Total</th>
            <th colspan="2"></th>
        </tr>
	[% WHILE (item = items.next) %]
        <tr>
            <form action="[% c.uri_for('[- uri -]/update/') %]" method="post">
                <input type="hidden" name="id" value="[% HTML.escape(item.id) %]">
                <td align="left">[% HTML.escape(item.sku) %]</td>
                <td align="left">[% HTML.escape(item.description) %]</td>
                <td align="right">[% HTML.escape(item.price.as_string('FMT_SYMBOL')) %]</td>
                <td align="center"><input style="text-align: center;" type="text" size="3" name="quantity" value="[% HTML.escape(item.quantity) %]"></td>
                <td align="right">[% HTML.escape(item.total.as_string('FMT_SYMBOL')) %]</td>
                <td><input type="submit" value="Update"></td>
            </form>
            <form action="[% c.uri_for('[- uri -]/delete/') %]" method="POST">
                <input type="hidden" name="id" value="[% HTML.escape(item.id) %]">
                <td>
                    <input type="submit" value="Delete">
                </td>
            </form>
        </tr>
	[% END %]
        <tr>
            <td colspan="7" height="20"></td>
        </tr>
        <tr>
            <th colspan="4" align="right">Subtotal:</th>
            <td align="right">[% HTML.escape(cart.subtotal.as_string('FMT_SYMBOL')) %]</td>
            <td colspan="2"></td>
        </tr>
        <tr>
            <td colspan="7" align="right">
                <form action="[% c.uri_for('[- uri -]/clear/') %]" method="POST">
                    <input type="submit" value="Empty Cart">
                </form>
                <form action="[% c.uri_for('/[- couri -]/') %]" method="POST">
                    <input type="submit" value="Checkout">
                </form>
            </td>
        </tr>
    </table>
    <form action="[% c.uri_for('[- uri -]/save/') %]" method="POST">
        <input type="text" name="name">
        <input type="submit" value="Save Cart">
    </form>
[% ELSE %]
    <p>Your shopping cart is empty.</p>
[% END %]
__list__
[% TAGS [- -] -%]
[% USE HTML %]
<h1>Your Saved Shopping Carts</h1>
[% INCLUDE [- action -]/errors %]
[% IF carts.count %]
    <table border="0" cellpadding="3" cellspacing="5">
        <tr>
            <th align="left">Name</th>
            <th align="right">Restore Mode</th>
            <th></th>
        </tr>
    [% WHILE (cart = carts.next) %]
        <tr>
            <td align="left" valign="top">[% HTML.escape(cart.name) %]</td>
            <td>
                <form action="[% c.uri_for('[- uri -]/restore/') %]" method="POST">
                    <input type="hidden" name="id" value="[% HTML.escape(cart.id) %]">
                    <select name="mode">
                        [% USE hc = Handel.Constants %]
                        <option value="[% HTML.escape(hc.CART_MODE_APPEND) %]">Append</option>
                        <option value="[% HTML.escape(hc.CART_MODE_MERGE) %]">Merge</option>
                        <option value="[% HTML.escape(hc.CART_MODE_REPLACE) %]">Replace</option>
                    </select>
                    <input type="submit" value="Restore Cart">
                </form>
            </td>
            <td>
                <form action="[% c.uri_for('[- uri -]/destroy/') %]" method="POST">
                    <input type="hidden" name="id" value="[% HTML.escape(cart.id) %]">
                    <input type="submit" value="Delete">
                </form>
            </td>
        </tr>
    [% END %]
    </table>
[% ELSE %]
    <p>You have no saved shopping carts.</p>
[% END %]
__errors__
[% TAGS [- -] -%]
[% IF errors %]
	<ul class="errors">
	[% FOREACH error IN errors %]
		<li>[% HTML.escape(error) %]</li>
	[% END %]
	</ul>
[% END %]
__messages__
[% action %]/save:
  name:
    NOT_BLANK: The name field cannot be empty.
    LENGTH: The name field must be between 1 and 50 characters.
[% action %]/update:
  id:
    REGEX: The id field is in the wrong format.
  quantity:
    NOT_BLANK: The quantity field cannot be empty.
    UINT: The quantity field must be a positive number.
[% action %]/delete:
  id:
    REGEX: The id field is in the wrong format.
[% action %]/destroy:
  id:
    REGEX: The id field is in the wrong format.
[% action %]/restore:
  id:
    REGEX: The id field is in the wrong format.
  mode:
    BETWEEN: The mode field must be between 1 and 3.
__profiles__
[% action %]/save:
  - name
  - [ [NOT_BLANK], [LENGTH, 1, 50] ]
[% action %]/delete:
  - id
  -
    -
      - REGEX
      - !!perl/regexp (?i-xsm:^[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}$)
[% action %]/destroy:
  - id
  -
    -
      - REGEX
      - !!perl/regexp (?i-xsm:^[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}$)
[% action %]/update:
  - id
  -
    -
      - REGEX
      - !!perl/regexp (?i-xsm:^[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}$)
  - quantity
  - [ [NOT_BLANK], [UINT] ]
[% action %]/restore:
  - id
  -
    -
      - REGEX
      - !!perl/regexp (?i-xsm:^[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}$)
  - mode
  - [ [BETWEEN, 1, 3] ]
__products__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<title>Nifty New Products</title>
		<base href="http://localhost:3000/" />
	</head>
	<body>
		<h1>Nifty New Products</h1>
		<p>
			<a href="[% uri %]/">View Cart</a> |
		</p>
		<h2>Mendlefarg 3000</h2>
		<p>
			It slices. It dices. It MVCs!
		</p>
		<form action="[% uri %]/add/" method="POST">
		  <p>
    			<input type="hidden" name="sku" value="MFG3000" />
    			<input type="hidden" name="description" value="Mendlefarg 3000" />
    			<input type="hidden" name="price" value="19.95" />
    			<input type="text" name="quantity" value="1" size="3" />
    			<input type="submit" value="Add To Cart" />
          </p>
         </form>

		<h2>Flimblebot 98</h2>
		<p>
			The most advanced flimble-based bot response software ever!
		</p>
		<form action="[% uri %]/add/" method="POST">
		  <p>
			<input type="hidden" name="sku" value="FB98" />
			<input type="hidden" name="description" value="Flimblebot 98 Single-User" />
			<input type="hidden" name="price" value="12.34" />
			<input type="text" name="quantity" value="1" size="3" />
			<input type="submit" value="Add To Cart" />
          </p>
		</form>
	</body>
</html>
__END__
