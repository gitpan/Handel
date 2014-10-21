# $Id: Checkout.pm 564 2005-06-27 11:46:39Z claco $
package Handel::Checkout;
use strict;
use warnings;

BEGIN {
    use Handel::ConfigReader;
    use Handel::Constants qw(:checkout :returnas);
    use Handel::Constraints qw(constraint_checkout_phase constraint_uuid);
    use Handel::Exception qw(:try);
    use Handel::L10N qw(translate);
    use Module::Pluggable 2.8 instantiate => 'new', sub_name => '_plugins';
};

sub new {
    my $class = shift;
    my $opts = shift || {};
    my $self = bless {
        plugins => [],
        handlers => {},
        phases => []
    }, ref $class || $class;

    $self->_set_search_path($opts);

    foreach ($self->_plugins($self)) {
        if (UNIVERSAL::isa($_, 'Handel::Checkout::Plugin')) {
            push @{$self->{'plugins'}}, $_;
            $_->register($self);
        };
    };

    $self->cart($opts->{'cart'}) if $opts->{'cart'};
    $self->order($opts->{'order'}) if $opts->{'order'};

    return $self;
};

sub plugins {
    my $self = shift;

    return @{$self->{'plugins'}};
};

sub add_handler {
    my ($self, $phase, $ref) = @_;
    my ($package) = caller;

    throw Handel::Exception::Argument( -details =>
        translate(
            'Param 1 is not a a valid CHECKOUT_PHASE_* value') . '.')
            unless constraint_checkout_phase($phase);

    throw Handel::Exception::Argument( -details =>
        translate(
            'Param 1 is not a CODE reference') . '.')
            unless ref($ref) eq 'CODE';

    foreach (@{$self->{'plugins'}}) {
        if (ref $_ eq $package) {
            push @{$self->{'handlers'}->{$phase}}, [$_, $ref];
            last;
        };
    };
};

sub cart {
    my ($self, $cart) = @_;

    if ($cart) {
        if (ref $cart eq 'HASH' || UNIVERSAL::isa($cart, 'Handel::Cart') || constraint_uuid($cart)) {
            $self->order(Handel::Order->new({cart => $cart}, 1));
        } else {
            throw Handel::Exception::Argument( -details =>
                translate('Param 1 is not a HASH reference, Handel::Cart object, or cart id') . '.');
        };
    };
};

sub order {
    my ($self, $order) = @_;

    if ($order) {
        if (ref $order eq 'HASH') {
            $self->{'order'} = Handel::Order->load($order, RETURNAS_ITERATOR)->first;
        } elsif (UNIVERSAL::isa($order, 'Handel::Order')) {
            $self->{'order'} = $order;
        } elsif (constraint_uuid($order)) {
            $self->{'order'} = Handel::Order->load({id => $order});
        } else {
            throw Handel::Exception::Argument( -details =>
                translate('Param 1 is not a HASH reference, Handel::Order object, or order id') . '.');
        }
    } else {
        return $self->{'order'};
    };
};

sub phases {
    my ($self, $phases) = @_;

    if ($phases) {
        throw Handel::Exception::Argument( -details =>
            translate(
                'Param 1 is not an ARRAY reference') . '.')
                unless ref($phases) eq 'ARRAY';

        $self->{'phases'} = $phases;
    } else {
        return $self->{'phases'} || CHECKOUT_DEFAULT_PHASES;
    };
};

sub process {
    my $self = shift;
    my $phases = shift;

    $self->_setup($self);

    if ($phases) {
        throw Handel::Exception::Argument( -details =>
            translate(
                'Param 1 is not an ARRAY reference') . '.')
                unless ref($phases) eq 'ARRAY';

        $self->{'phases'} = $phases;
    } else {
        $phases = $self->{'phases'} || CHECKOUT_DEFAULT_PHASES;
    };

    foreach my $phase (@{$phases}) {
        foreach my $handler (@{$self->{'handlers'}->{$phase}}) {
            my $status = $handler->[1]->($handler->[0], $self);

            if ($status == CHECKOUT_HANDLER_ERROR) {
                $self->_teardown($self);

                return CHECKOUT_STATUS_ERROR;
            };
        };
    };

    $self->_teardown($self);

    return CHECKOUT_STATUS_OK;
};

sub _setup {
    my $self = shift;

    foreach (@{$self->{'plugins'}}) {
        try {
            $_->setup($self);
        } otherwise {
            my $E = shift;
            warn $E->text;
        };
    };
};

sub _teardown {
    my $self = shift;

    foreach (@{$self->{'plugins'}}) {
        try {
            $_->teardown($self);
        } otherwise {
            my $E = shift;
            warn $E->text;
        };
    };
};

sub _set_search_path {
    my ($self, $opts) = @_;
    my $config = Handel::ConfigReader->new;

    my $pluginpaths = ref $opts->{'pluginpaths'} eq 'ARRAY' ?
        join(' ', @{$opts->{'pluginpaths'}}) : $opts->{'pluginpaths'} || '';

    my $addpluginpaths = ref $opts->{'addpluginpaths'} eq 'ARRAY' ?
        join(' ', @{$opts->{'addpluginpaths'}}) : $opts->{'addpluginpaths'} || '' ;

    if ($pluginpaths) {
        $self->search_path(new => _path_to_array($pluginpaths));
    } elsif (my $path = $config->{'HandelPluginPaths'}) {
        $self->search_path(new => _path_to_array($path));
    } elsif ($path = $config->{'HandelAddPluginPaths'}) {
        $self->search_path(new => 'Handel::Checkout::Plugin', _path_to_array("$path $addpluginpaths"));
    };
};

sub _path_to_array {
    my $path = shift or return '';

    # ditch begin/end space, replace comma with space and
    # split on space
    $path =~ s/(^\s+|\s+$)//;
    $path =~ s/,/ /g;

    return split /\s+/, $path;
};

1;
__END__

=head1 NAME

Handel::Checkout - Checkout Pipeline Process

=head1 SYNOPSIS

    use Handel::Checkout;

    my $checkout = Handel::Checkout->new({
        cart    => '122345678-9098-7654-3212-345678909876',
        phases  => [CHECKOUT_PHASE_INITIALIZE, CHECKOUT_PHASE_VALIDATE]
    });

    if ($checkout->process == CHECKOUT_STATUS_OK) {
        print 'Your order number is ', $checkout->order->number;
    } else {
        ...
    };

=head1 DESCRIPTION

Handel::Checkout is a basic pipeline processor that uses plugins at
various phases to perform any work necessary from credit card authorization
to order delivery. Handel does not try to be all things to all people
needing to place online orders. Instead, it provides a basic plugin mechanism
allowing the checkout process to be customized for many different needs.

=head1 CONSTRUCTOR

=head2 new([\%options])

Creates a new checkout pipeline process and loads all available plugins.
C<new> accepts the following options in an optional HASH reference:

=over

=item cart

A HASH reference, Handel::Cart object, or a cart id. This will be loaded
into a new Handel::Order object and associated with the new checkout
process.

See C<cart> below for further details about the various values allowed
to be passed.

B<Note>: When creating a new order via Handel::Order, C<new> will automatically
create a checkout process and process the C<CHECKOUT_PHASE_INITIALIZE>.
However, when a new order is created using C<cart> in Handel::Checkout, the
automatic processing of C<CHECKOUT_PHASE_INITIALIZE> is disabled.

=item order

A HASH reference, Handel::Order object, or an order id. This will be loaded
and associated with the new checkout process.

See C<order> below for further details about the various values allowed
to be passed.

=item pluginpaths

An array reference or a comma (or space) seperated list containing the various
namespaces of plugins to be loaded. This will override any settings in
C<ENV> or F<httpd.conf> for the current checkout instance only.

    my $checkout = Handel::Checkout->new({
        pluginpaths => [MyNamespace::Plugins, Other::Plugin]
    });

    my $checkout = Handel::Checkout->new({
        pluginpaths => 'MyNamespace::Plugins, Other::Plugin'
    });

See L<"HandelPluginPaths"> for more information about settings/resetting
plugin search paths.

=item addpluginpaths

An array reference or a comma (or space) seperated list containing the various
namespaces of plugin paths in addition to Handel::Checkout::Plugin to be loaded.
If C<HandelAddPluginPaths> is also specified, the two will be combined.

    my $checkout = Handel::Checkout->new({
        addpluginpaths => [MyNamespace::Plugins, Other::Plugin]
    });

    my $checkout = Handel::Checkout->new({
        addpluginpaths => 'MyNamespace::Plugins, Other::Plugin'
    });

See L<"HandelAddPluginPaths"> for more information about settings/resetting
plugin search paths.

=item phases

An array reference containing the various phases to be executed.

    my $checkout = Handel::Checkout->new({
        phases => [CHECKOUT_PHASE_VALIDATION,
                   CHECKOUT_PHASE_AUTHORIZATION]
    });

=back

=head1 METHODS

=head2 add_handler($phase, \&coderef)

Registers a code reference with the checkout phase specified. This is
usually called within C<register> on the current checkout context:

    sub register {
        my ($self, $ctx) = @_;

        $ctx->add_handler(CHECKOUT_PHASE_DELIVER, \&myhandler);
    };

    sub myhandler {
        ...
    };

=head2 cart

Creates a new Handel::Order object from the specified cart and associates
that order with the current checkout process. This is typeically only needed
the first time you want to run checkout for a specific cart. From then on,
you only need to load the already created order using C<order> below.

C<cart> can accept one of three possible parameter values:

=over

=item cart(\%filter)

When you pass a HASH reference, C<cart> will attempt to load all available
carts using Handel::Cart::load(\%filter). If multiple carts are found, only
the first one will be used.

    $checkout->cart({
        shopper => '12345678-9098-7654-3212-345678909876',
        type => CART_TYPE_TEMP
    });

=item cart(Handel::Cart)

You can also pass in an already existing Handel::Cart object. It will then
be loaded into a new order object ans associated with the current checkout
process.

    my $cart = Handel::Cart->load({
        id => '12345678-9098-7654-3212-345678909876'
    });

    $checkout->cart($cart);

=item cart($cartid)

Finally, you can pass a valid cart/uuid into C<cart>. The matching cart
will be loaded into a new Handel::Order object and associated with the
current checkout process.

    $checkout->cart('12345678-9098-7654-3212-345678909876');

=back

=head2 plugins

Returns the plugins loaded for checkout instance

    my $checkout = Handel::Checkout->new;
    my @plugins = $checkout->plugins;

    foreach (@plugins) {
        $_->cleanup_or_something;
    };

=head2 order

Gets/Sets an existing Handel::Order object with the existing checkout process.

C<order> can accept one of three possible parameter values:

=over

=item order(\%filter)

When you pass a HASH reference, C<order> will attempt to load all available
order using Handel::Order::load(\%filter). If multiple order are found, only
the first one will be used.

    $checkout->order({
        shopper => '12345678-9098-7654-3212-345678909876',
        id => '11111111-2222-3333-4444-5555666677778888'
    });

=item order(Handel::Order)

You can also pass in an already existing Handel::Order object. It will then
be associated with the current checkout process.

    my $order = Handel::Order->load({
        id => '12345678-9098-7654-3212-345678909876'
    });

    $checkout->order($order);

=item order($orderid)

Finally, you can pass a valid order/uuid into C<order>. The matching order
will be loaded and associated with the current checkout process.

    $checkout->order('12345678-9098-7654-3212-345678909876');

=back

=head2 phases(\@phases)

Get/Set the phases active for the current checkout process.

    $checkout->phases([
        CHECKOUT_PHASE_INITIALIZE,
        CHECKOUT_PHASE_VALIDATION
    ]);

=head2 process([\@phases])

Executes the current checkout process pipeline and returns CHECKOUT_STATUS_*.

=head1 CONFIGURATION

=head2 HandelPluginPaths

This resets the checkout plugin search path to a namespace of your choosing,
The default plugin search path is Handel::Checkout::Plugin::*

    PerlSetVar HandelPluginPaths MyApp::Plugins

In the example above, the checkout plugin search path will load all plugins
in the MyApp::Plugins::* namespace (but not MyApp::Plugin itself). Any plugins
in Handel::Checkout::Plugin::* will be ignored.

You can also pass a comma or space seperate list of namespaces.

    PerlSetVar HandelPluginPaths 'MyApp::Plugins, OtherApp::Plugins'

Any plugin found in the search path that isn't a subclass of Handel::Checkout::Plugin
will be ignored.

=head2 HandelAddPluginPaths

This adds an additional plugin search paths. This can be a comma or space
seperated list of namespaces.

    PerlSetVar HandelAddPluginPaths  'MyApp::Plugins, OtherApp::Plugins'

In the example above, when a checkout process is loaded, it will load
all plugins in the Handel::Checkout::Plugin::*, MyApp::Plugins::*, and
OtherApp::Plugins namespaces.

Any plugin found in the search path that isn't a subclass of Handel::Checkout::Plugin
will be ignored.

=head1 SEE ALSO

L<Handel::Constants>, L<Handel::Checkout::Plugin>, L<Handel::Order>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
