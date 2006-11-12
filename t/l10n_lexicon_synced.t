#!perl -wT
# $Id: l10n_lexicon_synced.t 1552 2006-11-07 03:31:50Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'use Module::Find';
    if($@) {
        plan skip_all => 'Module::Find not installed';
    } else {
        plan tests => 265;
        setmoduledirs('lib');
    };

    use_ok('Handel::L10N::en_us');
};


no strict 'refs';
no warnings 'once';

my $primary = \%Handel::L10N::en_us::Lexicon;

my @lexicons = useall('Handel::L10N');
foreach my $lex (@lexicons) {
    my $entries = \%{"$lex\:\:Lexicon"};

    ## make sure our counts match
    is(scalar keys %{$primary}, scalar keys %{$entries}, "$lex has differing number of entries");


    ## make sure all the entries are actually there
    foreach my $entry (keys %{$primary}) {
        ok(exists $entries->{$entry}, "No entry found for $entry in $lex");
    };
};
