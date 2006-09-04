# $Id: Handel.pm 1392 2006-09-04 01:18:53Z claco $
package Handel;
use strict;
use warnings;
use vars qw/$VERSION/;
use Handel::Exception qw/:try/;
use Handel::L10N qw/translate/;
use base qw/Class::Accessor::Grouped/;

$VERSION = '0.99_08';

__PACKAGE__->config_class('Handel::ConfigReader');

sub config_class {
    my ($self, $config_class) = @_;

    if ($config_class) {
        eval "require $config_class";

        throw Handel::Exception(
            -details => translate('The config_class [_1] could not be loaded', $config_class) . '.')
                if $@;

        $self->set_inherited('config_class', $config_class);
    };

    return $self->get_inherited('config_class');
};

sub config {
    return shift->config_class->instance;
};

1;
__END__

=head1 NAME

Handel - Simple commerce framework with AxKit/TT/Catalyst support

=head1 SYNOPSIS

    use Handel;
    Handel->config_class('My::ConfigReader');
    
    my $config = Handel->config;
    # $config->isa('My::ConfigReader')

=head1 DESCRIPTION

This is a generic class containing the default configuration used by other
Handel classes.

To learn more about what Handel is and how it works, take a look at the
L<Handel::Manual|manual>.

=head1 METHODS

=head2 config_class

=over

=item Arguments: $config_class

=back

Gets/sets the name of the configuration class to use. The default configuration
class is Handel::ConfigReader.

A L<Handel::Exception|Handel::Exception> exception will be thrown if the
specified class can not be loaded.

=head2 config

Returns an instance of the specified configuration class.

=head1 SEE ALSO

L<Handel::Cart>, L<Handel::Order>, L<Handel::Checkout>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
