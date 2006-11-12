# $Id: Order.pm 1475 2006-10-16 01:03:10Z claco $
## no critic (ProhibitCaptureWithoutTest)
package Catalyst::Helper::Controller::Handel::Order;
use strict;
use warnings;

BEGIN {
    use Catalyst 5.7001;
    use Catalyst::Utils;
    use Path::Class;
};

=head1 NAME

Catalyst::Helper::Controller::Handel::Order - Helper for Handel::Order Controllers

=head1 SYNOPSIS

    script/create.pl controller <newclass> Handel::Order [<modelclass>]
    script/create.pl controller Orders Handel::Order OrderModel

=head1 DESCRIPTION

A Helper for creating controllers based on Handel::Order objects. If no modelclass
is specified, ::M::Orders is assumed.

The modelclass argument tries to do the right thing with the names given to it.

For example, you can pass the shortened class name without the MyApp::M/C, or pass the fully
qualified package name:

    MyApp::M::OrderModel
    MyApp::Model::OrderModel
    OrderModel

In all three cases everything before M{odel)|C(ontroller) will be stripped and the class OrderModel
will be used.

B<The code generated by this helper requires FormValidator::Simple and YAML to be installed to operate.>

=head1 METHODS

=head2 mk_compclass

Makes a Handel::Order Controller class and template files for you.

=cut

sub mk_compclass {
    my ($self, $helper, $model) = @_;
    my $file = $helper->{'file'};
    my $dir  = dir($helper->{'base'}, 'root', $helper->{'uri'});

    $model ||= 'Order';
    $model =~ /^(.*::M(odel)?::)?(.*)$/i;
    $model = $3 ? $3 : 'Order';
    $helper->{'model'} = $model;

    $helper->{'action'} = Catalyst::Utils::class2prefix($helper->{'class'});

    $helper->mk_dir($dir);
    $helper->render_file('controller', $file);

    $helper->render_file('default', file($dir, 'default'));
    $helper->render_file('view', file($dir, 'view'));
    $helper->render_file('errors', file($dir, 'errors'));
    $helper->render_file('profiles', file($dir, 'profiles.yml'));
    $helper->render_file('messages', file($dir, 'messages.yml'));

    return 1;
};

=head2 mk_comptest

Makes a Handel::Order Controller test for you.

=cut

sub mk_comptest {
    my ($self, $helper) = @_;
    my $test = $helper->{'test'};

    $helper->render_file('test', $test);

    return 1;
};

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Handel::Order>

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
    use Handel::Constants qw/:order/;
    use FormValidator::Simple 0.17;
    use YAML;
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

Default action when browsing to [% uri %]/ that lists the saved orders for the
current shopper. If no session exists, or the shopper id isn't set, no orders
will be loaded. This keeps non-shoppers like Google and others from wasting
sessions and order records for no good reason.

=cut

sub default : Private {
    my ($self, $c) = @_;
    $c->stash->{'template'} = '[% action %]/default';

    if ($c->sessionid && $c->session->{'shopper'}) {
        my $orders = $c->model('[% model %]')->search({
            shopper => $c->session->{'shopper'},
            type    => ORDER_TYPE_SAVED
        });

        $c->stash->{'orders'} = $orders;
    };

    return;
};

=head2 create

Creates a new order from the current shopping cart.

    my $order = $c->forward('create');

=cut

sub create : Private {
    my ($self, $c, $cart) = @_;

    if ($c->sessionid && $c->session->{'shopper'}) {
        return $c->model('[% model %]')->create({
            shopper => $c->session->{'shopper'},
            type    => ORDER_TYPE_TEMP,
            cart    => $cart
        });
    };

    return;
};

=head2 load

Loads the current temporary order for the current shopper.

    my $order = $c->forward('load');

=cut

sub load : Private {
    my ($self, $c) = @_;

    if ($c->sessionid && $c->session->{'shopper'}) {
        return $c->model('[% model %]')->search({
            shopper => $c->session->{'shopper'},
            type    => ORDER_TYPE_TEMP
        })->first;
    };

    return;
};

=head2 view

=over

=item Parameters: id

=back

Loads the specified order and displays its details during a GET operation.

    [% uri %]/view/$id

=cut

sub view : Local {
    my ($self, $c, $id) = @_;
    $c->stash->{'template'} = '[% action %]/view';

    if ($id && $c->sessionid && $c->session->{'shopper'}) {
        if ($c->forward('validate', [{id => $id}])) {
            my $order = $c->model('[% model %]')->search({
                shopper => $c->session->{'shopper'},
                id   => $id,
                type    => ORDER_TYPE_SAVED
            })->first;

            if ($order) {
                $c->stash->{'order'} = $order;
                $c->stash->{'items'} = $order->items;
            };
        };
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
    my ($self, $c, $query) = @_;

    $query ||= $c->req;

    $self->{'validator'}->results->clear;

    my $results = $self->{'validator'}->check(
        $query,
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
<h1>Your Order History</h1>
[% IF orders.count %]
    <table border="0" cellpadding="3" cellspacing="5">
        <tr>
            <th align="left">Order#</th>
            <th align="right">Created</th>
        </tr>
    [% WHILE (order = orders.next) %]
        <tr>
            <td align="left">
                <a href="[% c.uri_for('[- uri -]/view', order.id, '') %]">[% HTML.escape(order.number) %]</a>
            </td>
            <td>
                [% HTML.escape(order.updated) %]
            </td>
        </tr>
    [% END %]
    </table>
[% ELSE %]
    <p>You have no orders.</p>
[% END %]
__view__
[% TAGS [- -] -%]
[% USE HTML %]
<h1>Order Details</h1>
[% INCLUDE [- action -]/errors %]
[% IF order %]
    <table border="0" cellpadding="3" cellspacing="5">
        <tr>
            <th colspan="2" align="left">Billing</th>
            <th width="50"></th>
            <th colspan="2" align="left">Shipping</th>
        </tr>
        <tr>
            <td colspan="5" height="5">&nbsp;</td>
        </tr>
        <tr>
            <td align="right">Order Number:</td>
            <td align="left">[% HTML.escape(order.number) %]</td>
            <td colspan="3"></td>
        </tr>
        <tr>
            <td align="right">Order Created:</td>
            <td align="left">[% HTML.escape(order.updated) %]</td>
            <td colspan="3"></td>
        </tr>
        <tr>
            <td colspan="5" height="5">&nbsp;</td>
        </tr>
        <tr>
            <td align="right">First Name:</td>
            <td align="left">[% HTML.escape(order.billtofirstname) %]</td>
            <td></td>
            <td align="right">First Name:</td>
            <td align="left">[% HTML.escape(order.shiptofirstname) %]</td>
        </tr>
        <tr>
            <td align="right">Last Name:</td>
            <td align="left">[% HTML.escape(order.billtolastname) %]</td>
            <td></td>
            <td align="right">Last Name:</td>
            <td align="left">[% HTML.escape(order.shiptolastname) %]</td>
        </tr>
        <tr>
            <td colspan="5" height="5">&nbsp;</td>
        </tr>
        <tr>
            <td align="right">Address:</td>
            <td align="left">[% HTML.escape(order.billtoaddress1) %]</td>
            <td></td>
            <td align="right">Address:</td>
            <td align="left">[% HTML.escape(order.shiptoaddress1) %]</td>
        </tr>
        <tr>
            <td align="right"></td>
            <td align="left">[% HTML.escape(order.billtoaddress2) %]</td>
            <td></td>
            <td align="right"></td>
            <td align="left">[% HTML.escape(order.shiptoaddress2) %]</td>
        </tr>
        <tr>
            <td align="right"></td>
            <td align="left">[% HTML.escape(order.billtoaddress3) %]</td>
            <td></td>
            <td align="right"></td>
            <td align="left">[% HTML.escape(order.shiptoaddress3) %]</td>
        </tr>
        <tr>
            <td align="right">City:</td>
            <td align="left">[% HTML.escape(order.billtocity) %]</td>
            <td></td>
            <td align="right">City:</td>
            <td align="left">[% HTML.escape(order.shiptocity) %]</td>
        </tr>
        <tr>
            <td align="right">State/Province:</td>
            <td align="left">[% HTML.escape(order.billtostate) %]</td>
            <td></td>
            <td align="right">State/Province:</td>
            <td align="left">[% HTML.escape(order.shiptostate) %]</td>
        </tr>
        <tr>
            <td align="right">Zip/Postal Code:</td>
            <td align="left">[% HTML.escape(order.billtozip) %]</td>
            <td></td>
            <td align="right">Zip/Postal Code:</td>
            <td align="left">[% HTML.escape(order.shiptozip) %]</td>
        </tr>
        <tr>
            <td align="right">Country:</td>
            <td align="left">[% HTML.escape(order.billtocountry) %]</td>
            <td></td>
            <td align="right">Country:</td>
            <td align="left">[% HTML.escape(order.shiptocountry) %]</td>
        </tr>
        <tr>
            <td align="right">Day Phone:</td>
            <td align="left">[% HTML.escape(order.billtodayphone) %]</td>
            <td></td>
            <td align="right">Day Phone:</td>
            <td align="left">[% HTML.escape(order.shiptodayphone) %]</td>
        </tr>
        <tr>
            <td align="right">Night Phone:</td>
            <td align="left">[% HTML.escape(order.billtonightphone) %]</td>
            <td></td>
            <td align="right">Night Phone:</td>
            <td align="left">[% HTML.escape(order.shiptonightphone) %]</td>
        </tr>
        <tr>
            <td align="right">Fax:</td>
            <td align="left">[% HTML.escape(order.billtofax) %]</td>
            <td></td>
            <td align="right">Fax:</td>
            <td align="left">[% HTML.escape(order.shiptofax) %]</td>
        </tr>
        <tr>
            <td align="right">Email:</td>
            <td align="left">[% HTML.escape(order.billtoemail) %]</td>
            <td></td>
            <td align="right">Email:</td>
            <td align="left">[% HTML.escape(order.shiptoemail) %]</td>
        </tr>
        <tr>
            <td colspan="5" height="5">&nbsp;</td>
        </tr>
        <tr>
            <td align="right" valign="top">Comments:</td>
            <td colspan="4" valign="top">[% HTML.escape(order.comments) %]</td>
        </tr>
        <tr>
            <td colspan="5" height="5">&nbsp;</td>
        </tr>
        <tr>
            <td colspan="5">
                <table border="0" cellpadding="3" cellspacing="5" width="100%">
                    <tr>
                        <th align="left">SKU</th>
                        <th align="left">Description</th>
                        <th align="right">Price</th>
                        <th align="center">Quantity</th>
                        <th align="right">Total</th>
                    </tr>
                [% WHILE (item = items.next) %]
                    <tr>
                            <td align="left">[% HTML.escape(item.sku) %]</td>
                            <td align="left">[% HTML.escape(item.description) %]</td>
                            <td align="right">[% HTML.escape(item.price.format(undef, 'FMT_SYMBOL')) %]</td>
                            <td align="center">[% HTML.escape(item.quantity) %]</td>
                            <td align="right">[% HTML.escape(item.total.format(undef, 'FMT_SYMBOL')) %]</td>
                    </tr>
                [% END %]
                    <tr>
                            <td align="right" colspan="4">Subtotal:</td>
                            <td align="right">[% HTML.escape(order.subtotal.format(undef, 'FMT_SYMBOL')) %]</td>
                    </tr>
                    <tr>
                            <td align="right" colspan="4">Tax:</td>
                            <td align="right">[% HTML.escape(order.tax.format(undef, 'FMT_SYMBOL')) %]</td>
                    </tr>
                    <tr>
                            <td align="right" colspan="4">Shipping:</td>
                            <td align="right">[% HTML.escape(order.shipping.format(undef, 'FMT_SYMBOL')) %]</td>
                    </tr>
                    <tr>
                            <td align="right" colspan="4">Handling:</td>
                            <td align="right">[% HTML.escape(order.handling.format(undef, 'FMT_SYMBOL')) %]</td>
                    </tr>
                    <tr>
                            <td align="right" colspan="4">Total:</td>
                            <td align="right">[% HTML.escape(order.total.format(undef, 'FMT_SYMBOL')) %]</td>
                    </tr>
                </table>
            </td>
        </td>
    </table>
[% ELSE %]
	<p>The order requested could not be found.</p>
[% END %]
[% TAGS [- -] -%]
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
[% action %]/view:
  id:
    REGEX: The id field is in the wrong format.

__profiles__
[% action %]/view:
  - id
  -
    -
      - REGEX
      - !perl/regexp:
        REGEXP: '^[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}$'
        MODIFIERS: i

__END__
