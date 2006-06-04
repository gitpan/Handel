# $Id: Schema.pm 1177 2006-05-31 01:59:23Z claco $
package Handel::Order::Schema;
use strict;
use warnings;
use base qw/Handel::Schema/;

__PACKAGE__->load_classes(qw//, {'Handel::Schema' => [qw/Order Order::Item/]});

1;
__END__

=head1 NAME

Handel::Order::Schema - Default Schema class for Handel::Order

=head1 SYNOPSIS

    use Handel::Order::Schema;
    use strict;
    use warnings;

    my $schema = Handel::Order::Schema->connect;

    my $cart = $schema->resultset("Orders")->find('12345678-9098-7654-3212-345678909876');

=head1 DESCRIPTION

Handel::Schema::Order is the default schema class used for all reading/writing in
Handel::Order.

=head1 SEE ALSO

L<DBIx::Class::Schema>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

