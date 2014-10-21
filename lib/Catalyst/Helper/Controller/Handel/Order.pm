# $Id: Order.pm 795 2005-09-12 02:07:53Z claco $
package Catalyst::Helper::Controller::Handel::Order;
use strict;
use warnings;
use Path::Class;

sub mk_compclass {
    my ($self, $helper, $model) = @_;
    my $file = $helper->{'file'};
    my $dir  = dir($helper->{'base'}, 'root', $helper->{'uri'});

    $helper->{'model'} = $model ? $helper->{'app'} . '::M::' . $model :
                         $helper->{'app'} . '::M::Orders';

    $helper->mk_dir($dir);
    #$helper->mk_component($helper->{'app'}, 'view', 'TT', 'TT');
    $helper->render_file('controller', $file);
    $helper->render_file('list', file($dir, 'list.tt'));
    $helper->render_file('view', file($dir, 'view.tt'));
};

sub mk_comptest {
    my ($self, $helper) = @_;
    my $test = $helper->{'test'};

    $helper->render_file('test', $test);
};

1;
__DATA__
__controller__
package [% class %];
use strict;
use warnings;
use Handel::Constants qw(:returnas :order);
use base 'Catalyst::Base';

sub begin : Private {
    my ($self, $c) = @_;
    my $shopperid = $c->req->cookie('shopperid')->value;

    if (!$shopperid) {
        $c->res->redirect($c->req->base . 'cart/');
    } else {
        $c->stash->{'shopperid'} = $shopperid;
    };
};

sub end : Private {
    my ($self, $c) = @_;

    $c->forward('[% app %]::V::TT') unless $c->res->output;
};

sub default : Private {
    my ($self, $c) = @_;

    $c->forward('list');
};

sub view : Local {
    my ($self, $c, $id) = @_;

    $c->stash->{'order'} = [% model %]->load({
        shopper => $c->stash->{'shopperid'},
        type    => ORDER_TYPE_SAVED,
        id      => $id
    }, RETURNAS_ITERATOR)->first;

    $c->stash->{'template'} = '[% uri %]/view.tt';
};

sub list : Local {
    my ($self, $c) = @_;

    $c->stash->{'orders'} = [% model %]->load({
        shopper => $c->stash->{'shopperid'},
        type    => ORDER_TYPE_SAVED
    }, RETURNAS_ITERATOR);

    $c->stash->{'template'} = '[% uri %]/list.tt';
};

1;
__test__
use Test::More tests => 2;
use strict;
use warnings;

use_ok(Catalyst::Test, '[% app %]');
use_ok('[% class %]');
__list__
[% TAGS [- -] %]
[% USE HTML %]
<h1>Your Previous Orders</h1>
<p>
    <a href="[% base _ '[- uri -]/' %]">View Order List</a>
</p>
[% IF orders.count %]
    <table border="0" cellpadding="3" cellspacing="5">
        <tr>
            <th align="left">Order#</th>
            <th align="right">Created</th>
        </tr>
    [% WHILE (order = orders.next) %]
        <tr>
            <td align="left">
                <a href="[% base _ '[- uri -]/view/' _ order.id _ '/' %]">[% HTML.escape(order.number) %]</a>
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
[% TAGS [- -] %]
[% USE HTML %]
[% IF order %]
    <h1>Order# [% HTML.escape(order.number) %]</h1>
    <p>
        <a href="[% base _ '[- uri -]/' %]">View Order List</a>
    </p>
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
                [% FOREACH item = order.items %]
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
    <h1>Order Not Found</h1>
    <p>
        <a href="[% base _ '[- uri -]/' %]">View Order List</a>
    </p>
    <p>The order requested could not be found.</p>
[% END %]
__END__

=head1 NAME

Catalyst::Helper::Controller::Handel::Order - Helper for Handel::Order Controllers

=head1 SYNOPSIS

    script/create.pl controller <newclass> Handel::Order [<modelclass>]
    script/create.pl controller Orders Handel::Order OrderModel

=head1 DESCRIPTION

A Helper for creating controllers based on Handel::Order objects. If no modelclass
is specified, ::M::Orders is assumed.


=head1 METHODS

=head2 mk_compclass

Makes a Handel::Order Controller class and template files for you.

=head2 mk_comptest

Makes a Handel::Order Controller test for you.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Handel::Order>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/