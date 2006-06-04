# $Id: Cart.pm 1157 2006-05-19 22:00:35Z claco $
package Handel::Schema::Cart;
use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/UUIDColumns Core/);
__PACKAGE__->table('cart');
__PACKAGE__->source_name('Carts');
__PACKAGE__->add_columns(qw/id shopper type name description/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->uuid_columns('id');
__PACKAGE__->has_many(items => 'Handel::Schema::Cart::Item', {'foreign.cart' => 'self.id'});

1;
__END__

=head1 NAME

Handel::Schema::Cart - Schema class for cart table

=head1 SYNOPSIS

    use Handel::Cart::Schema;
    use strict;
    use warnings;

    my $schema = Handel::Cart::Schema->connect;

    my $cart = $schema->resultset("Carts")->find('12345678-9098-7654-3212-345678909876');

=head1 DESCRIPTION

Handel::Schema::Cart is loaded by Handel::Cart::Schema to read/write data to
the cart table.

=head1 SEE ALSO

L<DBIx::Class::Schema>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
