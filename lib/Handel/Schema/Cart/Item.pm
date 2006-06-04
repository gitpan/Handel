# $Id: Item.pm 1157 2006-05-19 22:00:35Z claco $
package Handel::Schema::Cart::Item;
use strict;
use warnings;
use base qw/DBIx::Class/;
use Handel::Currency;

__PACKAGE__->load_components(qw/UUIDColumns Core/);
__PACKAGE__->table('cart_items');
__PACKAGE__->source_name('Items');
__PACKAGE__->add_columns(qw/id cart sku quantity price description/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->uuid_columns('id');
__PACKAGE__->inflate_column('price', {
    inflate => sub {Handel::Currency->new(@_)},
    deflate => sub {shift}
});

1;
__END__

=head1 NAME

Handel::Schema::Cart::Item - Schema class for cart_items table

=head1 SYNOPSIS

    use Handel::Cart::Schema;
    use strict;
    use warnings;

    my $schema = Handel::Cart::Schema->connect;

    my $item = $schema->resultset("Items")->find('12345678-9098-7654-3212-345678909876');

=head1 DESCRIPTION

Handel::Schema::Cart::Item is loaded by Handel::Cart::Schema to read/write data
to the cart_items table.

=head1 SEE ALSO

L<DBIx::Class::Schema>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
