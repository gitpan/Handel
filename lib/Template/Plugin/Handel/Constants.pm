# $Id$
package Template::Plugin::Handel::Constants;
use strict;
use warnings;
use base qw/Template::Plugin/;
use Handel::Constants ();

sub new {
    my ($class, $context, @params) = @_;
    my $self = bless {_CONTEXT => $context}, $class;

    foreach my $const (@Handel::Constants::EXPORT_OK) {
        if ($const =~ /^[A-Z]{1}/) {
            $self->{$const} = Handel::Constants->$const;
        };
    };

    return $self;
};

sub load {
    my ($class, $context) = @_;

    return $class;
};

1;
__END__

=head1 NAME

Template::Plugin::Handel::Constants - Template Toolkit plugin for constants

=head1 SYNOPSIS

    [% USE hdl = Handel.Constants %]
    [% hdl.CART_TYPE_SAVED %]

    or

    [% USE Handel.Constants %]
    [% Handel.Constants.CART_TYPE_SAVED %]

=head1 DESCRIPTION

Template::Plugin::Handel::Constants is a TT2 (Template Toolkit 2) plugin to
access Handel::Constants inside of TT2 pages.

It contains all of the exportable constants declared in
Handel::Constants::EXPORT_OK.

=head1 SEE ALSO

L<Handel::Constants>, L<Template::Plugin>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
