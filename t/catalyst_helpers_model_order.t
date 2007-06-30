#!perl -w
# $Id: /local/Handel/trunk/t/catalyst_helpers_model_order.t 1574 2007-06-30T04:31:38.958855Z claco  $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Cwd;
    use File::Path;
    use File::Spec::Functions;

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

    plan tests => 10;

    use_ok('Catalyst::Helper');
    use_ok('Catalyst::Helper::Model::Handel::Order');
    use_ok('Catalyst::Model::Handel::Order');
};

my $helper = Catalyst::Helper->new;
my $app = 'TestApp';


## setup var
chdir('t');
mkdir('var') unless -d 'var';
chdir('var');


## create the test app
{
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


## create the default model without defaults
{
    my $module = catfile($app, 'lib', $app, 'Model', 'MyOrder.pm');
    $helper->mk_component($app, 'model', 'MyOrder', 'Handel::Order');
    file_exists_ok($module);
    file_contents_like($module, qr/\['', '', ''\]/);
};


## load it up
{
    my $lib = catfile(cwd, $app, 'lib');
    eval "use lib '$lib';use $app\:\:Model\:\:Order";
    ok(!$@, 'loaded new class');
};
