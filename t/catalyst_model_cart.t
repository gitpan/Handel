#!perl -wT
# $Id: /local/Handel/trunk/t/catalyst_model_cart.t 1638 2007-06-24T15:35:46.298350Z claco  $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'use Test::MockObject 1.07';
    if (!$@) {
        plan tests => 14;
    } else {
        plan skip_all => 'Test::MockObject 1.07 not installed';
    };

    my @models = (
        bless({}, 'Catalyst::Model::Handel::Cart'),
        bless({cart_class => 'MyCart'}, 'Catalyst::Model::Handel::Cart'),
        bless({cart_class => 'BogusCart'}, 'Catalyst::Model::Handel::Cart'),
        bless({cart_class => 'Handel::Subclassing::Cart', mysetting => 'foo'}, 'Catalyst::Model::Handel::Cart'),
    );

    Test::MockObject->fake_module('Catalyst::Model' => (
        new => sub {
            return shift @models;
        }
    ));

    my $cartstorage = Test::MockObject->new;
    $cartstorage->set_always('clone', $cartstorage);
    $cartstorage->mock('mysetting' => sub {
        my $self = shift;

        if (@_) {
            $self->{'mysetting'} = shift;
        };

        return $self->{'mysetting'};
    });
    Test::MockObject->fake_module('Handel::Subclassing::Cart' => (
        storage => sub {$cartstorage},
        forwardmethod => sub {return $_[1];},
        new => sub {return $_[1];}
    ));

    my $mycartstorage = Test::MockObject->new;
    $mycartstorage->set_always('clone', $mycartstorage);
    Test::MockObject->fake_module('MyCart' => (
        storage => sub {$mycartstorage}
    ));

    use_ok('Catalyst::Model::Handel::Cart');
    use_ok('Handel::Exception', ':try');
};


## test model with the default class
{
    my $model = Catalyst::Model::Handel::Cart->COMPONENT;
    isa_ok($model, 'Catalyst::Model::Handel::Cart');
    isa_ok($model->cart_manager, 'Handel::Cart', 'set default cart manager');
};


## test model with other class
{
    my $model = Catalyst::Model::Handel::Cart->COMPONENT;
    isa_ok($model, 'Catalyst::Model::Handel::Cart');
    isa_ok($model->cart_manager, 'MyCart', 'set custom cart manager');
};


## throw exception when bogus cart_class is given
{
    try {
        local $ENV{'LANG'} = 'en';
        my $model = Catalyst::Model::Handel::Cart->COMPONENT;

        fail('no exception thrown');
    } catch Error::Simple with {
        pass('caught simple exception');
        like(shift, qr/could not load cart class/i, 'could not load class in message');
    } otherwise {
        fail('caught other exception');
    };
};


## test model with other unloaded class
{
    my $model = Catalyst::Model::Handel::Cart->COMPONENT;
    isa_ok($model, 'Catalyst::Model::Handel::Cart');
    isa_ok($model->cart_manager, 'Handel::Subclassing::Cart', 'set custom cart manager');
    ok($model->cart_manager->storage->called('mysetting'), 'pass mysetting to storage config');
    is($model->cart_manager->storage->mysetting, 'foo', 'mysetting was set');
    is($model->forwardmethod('foo'), 'foo', 'methods forwarded to manager instance');
    is($model->new('foonew'), 'foonew', 'new forwarded to manager instance');
};
