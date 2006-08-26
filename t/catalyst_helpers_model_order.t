#!perl -w
# $Id: catalyst_helpers_model_order.t 1386 2006-08-26 01:46:16Z claco $
use strict;
use warnings;
use Test::More;
use Cwd;
use File::Path;
use File::Spec::Functions;

BEGIN {
    eval 'use Catalyst 5.7001';
    plan(skip_all =>
        'Catalyst 5.7001 not installed') if $@;

    eval 'use Catalyst::Devel 1.0';
    plan(skip_all =>
        'Catalyst::Devel 1.0 not installed') if $@;

    eval 'use Test::File 1.10';
    plan(skip_all =>
        'Test::File 1.10 not installed') if $@;

    eval 'use Test::File::Contents 0.02';
    plan(skip_all =>
        'Test::File::Contents 0.02 not installed') if $@;

    plan tests => 6;

    use_ok('Catalyst::Helper');
};

my $helper = Catalyst::Helper->new;
my $app = 'TestApp';


## create the test app
{
    chdir('t');
    rmtree($app);

    $helper->mk_app($app);
    $FindBin::Bin = catdir(cwd, $app, 'lib');
};


## create the default model
{
    my $module = catfile($app, 'lib', $app, 'Model', 'Order.pm');
    $helper->mk_component($app, 'model', 'Order', 'Handel::Order', 'testdsn', 'testuser', 'testpass');
    file_exists_ok($module);
    file_contents_like($module, qr/'testdsn'/);
    file_contents_like($module, qr/'testuser'/);
    file_contents_like($module, qr/'testpass'/);
};


## load it up
{
    my $lib = catfile(cwd, $app, 'lib');
    eval "use lib '$lib';use $app\:\:Model\:\:Order";
    ok(!$@);
};
