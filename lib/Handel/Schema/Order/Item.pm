# $Id: Item.pm 1311 2006-07-09 18:28:51Z claco $
package Handel::Schema::Order::Item;
use strict;
use warnings;
use base qw/DBIx::Class/;
use Handel::Currency;

__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('order_items');
__PACKAGE__->source_name('Items');
__PACKAGE__->add_columns(
    id => {
        data_type      => 'varchar',
        size           => 36,
        is_nullable    => 0,
    },
    orderid => {
        data_type      => 'varchar',
        size           => 36,
        is_nullable    => 0,
        is_foreign_key => 1
    },
    sku => {
        data_type      => 'varchar',
        size           => 25,
        is_nullable    => 0,
    },
    quantity => {
        data_type      => 'tinyint',
        size           => 3,
        is_nullable    => 0,
        default_value  => 1
    },
    price => {
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
    description => {
        data_type     => 'varchar',
        size          => 255,
        is_nullable   => 1,
        default_value => undef
    }
);
__PACKAGE__->set_primary_key('id');

1;
__END__

=head1 NAME

Handel::Schema::Order::Item - Schema class for order_items table

=head1 SYNOPSIS

    use Handel::Order::Schema;
    use strict;
    use warnings;

    my $schema = Handel::Order::Schema->connect;

    my $item = $schema->resultset("Items")->find('12345678-9098-7654-3212-345678909876');

=head1 DESCRIPTION

Handel::Schema::Order::Item is loaded by Handel::Order::Schema to read/write data
to the order_items table.

=head1 SEE ALSO

L<DBIx::Class::Schema>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

