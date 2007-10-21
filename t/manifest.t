#!perl -wT
# $Id: /local/CPAN/Handel/trunk/t/manifest.t 1988 2007-10-21T21:05:56.869869Z claco  $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

    eval 'use Test::CheckManifest 0.09';
    if($@) {
        plan skip_all => 'Test::CheckManifest 0.09 not installed';
    };
};

ok_manifest({
    exclude => ['/t/var', '/cover_db', '/t/conf', '/t/logs/', '/t/htdocs/index.html'],
    filter  => [qr/\.kpf/, qr/\.svn/, qr/cover/, qr/\.tws/, qr/(SMOKE$|TEST$)/, qr/Build(\.PL|\.bat)?/],
    bool    => 'or'
});
