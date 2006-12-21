# $Id: Currency.pm 1594 2006-11-15 04:54:59Z claco $
package Handel::Currency;
use strict;
use warnings;
use overload
    '0+'     => \&value,
    'bool'   => \&value,
    '=='     => \&value,
    '""'     => \&stringify,
    fallback => 1;

BEGIN {
    use base qw/Class::Accessor::Grouped/;
    use Handel;
    use Handel::Constraints qw/:all/;
    use Handel::Exception;
    use Handel::L10N qw/translate/;
    use Locale::Currency;
    use Locale::Currency::Format;
    use Scalar::Util qw/blessed/;
    use Class::Inspector;
    use Carp;

    __PACKAGE__->mk_group_accessors('simple', qw/converter _code _format/);
    __PACKAGE__->mk_group_accessors('component_class', qw/converter_class/);
};

__PACKAGE__->converter_class('Finance::Currency::Convert::WebserviceX');

sub new {
    my $class = shift;
    my $self  = bless {
        value     => $_[0] || 0
    }, $class;

    if ($_[1]) {
        $self->code($_[1]);
    };
    if ($_[2]) {
        $self->_format($_[2]);
    };

    return $self;
};

sub code {
    my $self = shift;

    if (scalar @_) {
        my $code = shift;

        throw Handel::Exception::Argument(
            -details => translate('CURRENCY_CODE_INVALID', $code)
        ) unless constraint_currency_code($code); ## no critic

        $self->_code($code);
    };

    return $self->_code;
};

sub format {
    my ($self, $format) = @_;
    my $cfg = Handel->config;
    my $code = $self->code || $cfg->{'HandelCurrencyCode'};


    if (!defined $format) {
        $format = $self->_format || $cfg->{'HandelCurrencyFormat'};
    };
    ## funky eval to get string versions of constants back into the values
    eval '$format = ' .  $format; ## no critic

    throw Handel::Exception::Argument(
        -details => translate('CURRENCY_CODE_INVALID', $code)
    ) unless constraint_currency_code($code); ## no critic

    return _to_utf8(currency_format($code, $self->value, $format));
};

sub convert {
    my ($self, $to) = @_;
    my $class = blessed($self);
    my $cfg = Handel->config;
    my $from = $self->code || $cfg->{'HandelCurrencyCode'};

    $to ||= '';
    if (uc($from) eq uc($to)) {
        return $self;
    };

    throw Handel::Exception::Argument(
        -details => translate('CURRENCY_CODE_INVALID', $from)
    ) unless constraint_currency_code($from); ## no critic

    throw Handel::Exception::Argument(
        -details => translate('CURRENCY_CODE_INVALID', $to)
    ) unless constraint_currency_code($to); ## no critic

    if (!$self->converter) {
        $self->converter($self->converter_class->new)
    };

    return $class->new(
        $self->converter->convert($self->value, $from, $to) || 0,
        $to,
        $self->_format
    );
};

sub name {
    my $self = shift;
    my $code = $self->code || Handel->config->{'HandelCurrencyCode'};

    throw Handel::Exception::Argument(
        -details => translate('CURRENCY_CODE_INVALID', $code)
    ) unless constraint_currency_code($code); ## no critic

    return code2currency($code);
};

sub value {
    my $self = shift;

    return $self->{'value'};
};

sub stringify {
    my $self = shift;

    return $self->value;
};

sub _to_utf8 {
    my $value = shift;

    if ($] >= 5.008) { ## no critic
        require utf8;
        utf8::upgrade($value);
    };

    return $value;
};

sub get_component_class {
    my ($self, $field) = @_;

    return $self->get_inherited($field);
};

sub set_component_class {
    my ($self, $field, $value) = @_;

    if ($value) {
        if (!Class::Inspector->loaded($value)) {
            eval "use $value"; ## no critic

            throw Handel::Exception(
                -details => translate('COMPCLASS_NOT_LOADED', $field, $value)
            ) if $@; ## no critic
        };
    };

    $self->set_inherited($field, $value);

    return;
};

1;
__END__

=head1 NAME

Handel::Currency - Price container to do currency conversion/formatting

=head1 SYNOPSIS

    use Handel::Currency;

    my $curr = Handel::Currency->new(1.2. 'USD');
    print $curr->format;             # 1.20 USD
    print $curr->format('FMT_SYMBOL'); # $1.20

    print 'Your price in Canadian Dollars is: ';
    print $curr->convert('CAD')->value;

=head1 DESCRIPTION

The Handel::Currency module provides basic currency formatting within Handel.
It can be used separately to format any number into a more friendly format:

    my $price = 1.23;
    my $currency = Handel::Currency->new($price);

    print $currency->format;

A new Handel::Currency object is automatically returned within the shopping
cart when calling C<subtotal>, C<total>, and C<price> as an lvalue:

    my $cart = Handel::Cart->search({id => '11111111-1111-1111-1111-111111111111'});

    print $cart->subtotal;              # 12.9
    print $cart->subtotal->format;      # 12.90 USD

By default, a Handel::Currency object will stringify to the original decimal
based price.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: $price [, $code, $format]

=back

To creates a new Handel::Currency object, simply call C<new> and pass in the
price to be formatted:

    my $currency = Handel::Currency->new(10.23);

You can also pass in the default currency code and/or currency format to be
used. If not code or format are supplied, future calls to C<format> and
C<convert> will use the C<HandelCurrencyCode> and C<HandelCurrencyFormat>
environment variables.

=head1 METHODS

=head2 code

=over

=item Arguments: $code

=back

Gets/sets the three letter currency code for the current currency object.

C<code> throws a L<Handel::Exception::Argument|Handel::Exception::Argument>
if C<code> isn't a valid currency code. If no code was passed during object
creation, I<no code will be return by this method>.

=head2 convert

=over

=item Arguments: $code

=back

Returns a new Handel::Currency object containing the converted price value.

If no C<code> is specified for the current currency object, the
C<HandelCurrencyCode> will be used as the currency code to convert from. If the
currency you are converting to is the same as the currency objects currency
code, convert will just return itself.

You can also simply chain the C<convert> call into a C<format> call.

    my $price = Handel::Currency->new(1.25, 'USA');
    print $price->convert('CAD')->format;

C<convert> throws a L<Handel::Exception::Argument|Handel::Exception::Argument>
if C<code> isn't valid currency code or isn't defined.

It is also acceptable to specify different default values.
See L</"CONFIGURATION"> and C<Handel::ConfigReader> for further details.

=head2 converter_class

=over

=item Arguments: $converter_class

=back

Gets/sets the converter class to be used when converting currency numbers.

    __PACKAGE__->currency_class('MyCurrencyConverter');

The converter class can be any class that supports the following method
signature:

    sub convert {
        my ($self, $price, $from, $to) = @_;

        return $converted_price;
    };

A L<Handel::Exception|Handel::Exception> exception will be thrown if the
specified class can not be loaded.

=head2 format

=over

=item Arguments: $options

=back

Returns the freshly formatted price in a format declared in
L<Locale::Currency::Format|Locale::Currency::Format>. If no format options are
specified, the defaults values from C<new> and then
C<HandelCurrencyFormat> are used. Currently the default format is
C<FMT_STANDARD>.

It is also acceptable to specify different default values.
See L</"CONFIGURATION"> and C<Handel::ConfigReader> for further details.

=head2 name

Returns the currency name for the currency objects currency code. If no
currency code is set, the code set in C<HandelCurrencyCode> will be used.

C<name> throws a L<Handel::Exception::Argument|Handel::Exception::Argument>
if code used isn't a valid currency code.

=head2 stringify

Returns C<value> in scalar context. For now, this returns the same thing that
was passed to C<new>. This maybe change in the future.

=head2 value

Returns the original price value given to C<new>. Always use this instead of
relying on stringification when deflating currency objects in DBIx::Class
schemas.

=head2 get_component_class

=over

=item Arguments: $name

=back

Gets the current class for the specified component name.

    my $class = $self->get_component_class('item_class');

There is no good reason to use this. Use the specific class accessors instead.

=head2 set_component_class

=over

=item Arguments: $name, $value

=back

Sets the current class for the specified component name.

    $self->set_component_class('item_class', 'MyItemClass');

A L<Handel::Exception|Handel::Exception> exception will be thrown if the
specified class can not be loaded.

There is no good reason to use this. Use the specific class accessors instead.

=head1 CONFIGURATION

=head2 HandelCurrencyCode

This sets the default currency code used when no code is passed into C<new>.
See L<Locale::Currency::Format|Locale::Currency::Format> for all available
currency codes. The default code is USD.

=head2 HandelCurrencyFormat

This sets the default options used to format the price. See
L<Locale::Currency::Format|Locale::Currency::Format> for all available currency
codes. The default format used is C<FMT_STANDARD>. Just like in
Locale::Currency::Format, you can combine options using C<|>.

=head1 SEE ALSO

L<Locale::Currency>, L<Locale::Currency::Format>,
L<Finance::Currency::Convert::WebserviceX>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
