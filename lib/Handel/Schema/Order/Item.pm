# $Id: Item.pm 1178 2006-05-31 01:59:59Z claco $
package Handel::Schema::Order::Item;
use strict;
use warnings;
use base qw/DBIx::Class/;
use Handel::Currency;

__PACKAGE__->load_components(qw/UUIDColumns Core/);
__PACKAGE__->table('order_items');
__PACKAGE__->source_name('Items');
__PACKAGE__->add_columns(qw/id orderid sku quantity price description total/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->uuid_columns('id');
__PACKAGE__->inflate_column('price', {
    inflate => sub {Handel::Currency->new(@_)},
    deflate => sub {shift}
});
__PACKAGE__->inflate_column('total', {
    inflate => sub {Handel::Currency->new(@_)},
    deflate => sub {shift}
});

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

