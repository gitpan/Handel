package Handel::L10N;
use strict;
use warnings;
use vars qw(@EXPORT_OK %Lexicon $handle);

BEGIN {
    use base 'Locale::Maketext';
    use base 'Exporter';
};

@EXPORT_OK = qw(translate);

%Lexicon = (
    _AUTO => 1
);

$handle = __PACKAGE__->get_handle();

sub translate {
    return $handle->maketext(@_);
};

1;
__END__

=head1 NAME

Handel::L10N - Localization module for Handel

=head1 VERSION

    $Id: L10N.pm 20 2004-12-30 05:06:44Z claco $

=head1 SYNOPSIS

    use Handel::L10N qw(translate);

    warn translate('This is my message');

=head1 DESCRIPTION

This module is simply a subclass of L<Localte::Maketext>. By default it doesn't
export anything. You can either use it directly:

    use Handel::L10N;

    warn Handel::L10N::translate('My message');

You can also export C<translate> into the users namespace:

    use Handel::L10N qw(translate);

    warn translate('My message');

=head1 METHODS

=head2 C<translate>

Translates the supplied text into the appropriate language if avsailable. If no
match is available, the original text is returned.

=head1 SEE ALSO

L<Locale::Maketext>, L<Handel::L10N::us_en>, L<Handel::L10N::fr>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/



