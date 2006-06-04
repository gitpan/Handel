# $Id: Order.pm 1178 2006-05-31 01:59:59Z claco $
package Handel::Schema::Order;
use strict;
use warnings;
use base qw/DBIx::Class/;
use Handel::Currency;

__PACKAGE__->load_components(qw/UUIDColumns Core/);
__PACKAGE__->table('orders');
__PACKAGE__->source_name('Orders');
__PACKAGE__->add_columns(qw/id shopper type number created updated comments
    shipmethod shipping handling tax subtotal total
    billtofirstname billtolastname billtoaddress1 billtoaddress2 billtoaddress3
    billtocity billtostate billtozip billtocountry  billtodayphone
    billtonightphone billtofax billtoemail shiptosameasbillto
    shiptofirstname shiptolastname shiptoaddress1 shiptoaddress2 shiptoaddress3
    shiptocity shiptostate shiptozip shiptocountry shiptodayphone
    shiptonightphone shiptofax shiptoemail/
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->uuid_columns('id');
__PACKAGE__->has_many(items => 'Handel::Schema::Order::Item', {'foreign.orderid' => 'self.id'});
__PACKAGE__->inflate_column('subtotal', {
    inflate => sub {Handel::Currency->new(@_)},
    deflate => sub {shift}
});
__PACKAGE__->inflate_column('total', {
    inflate => sub {Handel::Currency->new(@_)},
    deflate => sub {shift}
});
__PACKAGE__->inflate_column('shipping', {
    inflate => sub {Handel::Currency->new(@_)},
    deflate => sub {shift}
});
__PACKAGE__->inflate_column('handling', {
    inflate => sub {Handel::Currency->new(@_)},
    deflate => sub {shift}
});
__PACKAGE__->inflate_column('tax', {
    inflate => sub {Handel::Currency->new(@_)},
    deflate => sub {shift}
});

1;
__END__

=head1 NAME

Handel::Schema::Order - Schema class for order table

=head1 SYNOPSIS

    use Handel::Order::Schema;
    use strict;
    use warnings;

    my $schema = Handel::Order::Schema->connect;

    my $cart = $schema->resultset("Orders")->find('12345678-9098-7654-3212-345678909876');

=head1 DESCRIPTION

Handel::Schema::Order is loaded by Handel::Order::Schema to read/write data to
the order table.

=head1 SEE ALSO

L<DBIx::Class::Schema>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
