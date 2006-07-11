# $Id: Order.pm 1311 2006-07-09 18:28:51Z claco $
package Handel::Schema::Order;
use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/Core/);
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
__PACKAGE__->add_columns(
    id => {
        data_type     => 'varchar',
        size          => 36,
        is_nullable   => 0,
    },
    shopper => {
        data_type     => 'varchar',
        size          => 36,
        is_nullable   => 0,
    },
    type => {
        data_type     => 'tinyint',
        size          => 3,
        is_nullable   => 0,
        default_value => 0
    },
    number => {
        data_type     => 'varchar',
        size          => 20,
        is_nullable   => 1,
        default_value => undef
    },
    created => {
        data_type     => 'datetime',
        size          => 19,
        is_nullable   => 1,
        default_value => undef
    },
    updated => {
        data_type     => 'datetime',
        size          => 19,
        is_nullable   => 1,
        default_value => undef
    },
    comments => {
        data_type     => 'varchar',
        size          => 100,
        is_nullable   => 1,
        default_value => undef
    },
    shipmethod => {
        data_type     => 'varchar',
        size          => 20,
        is_nullable   => 1,
        default_value => undef
    },
    shipping => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },
    handling => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },
    tax => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },
    subtotal => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },
    total => {
        data_type      => 'decimal',
        size           => [9,2],
        is_nullable    => 0,
        default_value  => '0.00'
    },
    billtofirstname => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    billtolastname => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    billtoaddress1 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    billtoaddress2 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    billtoaddress3 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    billtocity => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    billtostate => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    billtozip => {
        data_type     => 'varchar',
        size          => 10,
        is_nullable   => 1,
        default_value => undef
    },
    billtocountry => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    billtodayphone => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    billtonightphone => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    billtofax => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    billtoemail => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    shiptosameasbillto => {
        data_type     => 'tinyint',
        size          => 3,
        is_nullable   => 0,
        default_value => 1
    },
    shiptofirstname => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    shiptolastname => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    shiptoaddress1 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    shiptoaddress2 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    shiptoaddress3 => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    shiptocity => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    shiptostate => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    },
    shiptozip => {
        data_type     => 'varchar',
        size          => 10,
        is_nullable   => 1,
        default_value => undef
    },
    shiptocountry => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    shiptodayphone => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    shiptonightphone => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    shiptofax => {
        data_type     => 'varchar',
        size          => 25,
        is_nullable   => 1,
        default_value => undef
    },
    shiptoemail => {
        data_type     => 'varchar',
        size          => 50,
        is_nullable   => 1,
        default_value => undef
    }
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(items => 'Handel::Schema::Order::Item', {'foreign.orderid' => 'self.id'});

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
