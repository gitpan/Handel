package Handel::L10N::fr;
use strict;
use warnings;
use vars qw(%Lexicon);

BEGIN {
    use base 'Handel::L10N';
};

%Lexicon = (
    'An unspecified commerce error has ocurred' =>
        'Une erreur non spécifiée de commerce a ocurred',

    'The supplied field(s) failed database constraints' =>
        'Le field(s) assuré a échoué des contraintes de base de données',

    'The argument supplied is invalid or of the wrong type' =>
        "L'argument fourni est inadmissible ou du type inapproprié"
);

1;
__END__

=head1 NAME

Handel::L10N::fr - French Language Pack for Handel

=head1 VERSION

    $Id: fr.pm 21 2004-12-30 05:06:55Z claco $

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    cpan@chrislaco.com
    http://today.icantfocus.com/blog/