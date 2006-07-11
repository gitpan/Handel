# $Id: Cart.pm 1318 2006-07-10 23:42:32Z claco $
package Catalyst::Helper::Model::Handel::Cart;
use strict;
use warnings;
use Catalyst 5.7;

sub mk_compclass {
    my ($self, $helper, $dsn, $user, $pass) = @_;
    my $file = $helper->{file};
    $helper->{'dsn'}  = $dsn  || '';
    $helper->{'user'} = $user || '';
    $helper->{'pass'} = $pass || '';

    $helper->render_file('model', $file);
};

sub mk_comptest {
    my ($self, $helper) = @_;
    my $test = $helper->{'test'};

    $helper->render_file('test', $test);
};

1;
__DATA__
__model__
package [% class %];
use strict;
use warnings;
use base qw/Handel::Cart/;

__PACKAGE__->connection_info('[% dsn %]', '[% user %]', '[% pass %]');

1;
__test__
use Test::More tests => 2;
use strict;
use warnings;

use_ok(Catalyst::Test, '[% app %]');
use_ok('[% class %]');
__END__

=head1 NAME

Catalyst::Helper::Model::Handel::Cart - Helper for Handel::Cart Models

=head1 SYNOPSIS

    script/create.pl model <newclass> Handel::Cart <dsn> [<username> <password>]
    script/create.pl model Cart Handel::Cart dbi:mysql:dbname=handel.db myuser mysecret

=head1 DESCRIPTION

A Helper for creating models based on Handel::Cart objects.

=head1 METHODS

=head2 mk_compclass

Makes a Handel::Cart Model class for you.

=head2 mk_comptest

Makes a Handel::Cart Model test for you.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Handel::Cart>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
