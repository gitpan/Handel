# $Id: Currency.pm 1335 2006-07-15 02:43:12Z claco $
package Handel::Currency;
use strict;
use warnings;
use overload '""' => \&stringify, fallback => 1;

BEGIN {
    use Handel;
    use Handel::Constraints qw/:all/;
    use Handel::Exception;
    use Handel::L10N qw/translate/;
};

sub new {
    my ($class, $value) = @_;
    my $self = bless {price => $value}, ref($class) || $class;

    eval 'use Finance::Currency::Convert::WebserviceX';
    if (!$@) {
        $self->{'converter'} = Finance::Currency::Convert::WebserviceX->new;
    };

    return $self;
};

sub format {
    my ($self, $code, $format) = @_;

    eval 'use Locale::Currency::Format';
    return $self->{'price'} if $@;

    my $cfg = Handel->config;

    eval '$format = ' .  ($format || $cfg->{'HandelCurrencyFormat'});
    $code   ||= $cfg->{'HandelCurrencyCode'};

    throw Handel::Exception::Argument(
        -details => translate("Currency code '[_1]' is invalid or malformed", $code) . '.') unless
            constraint_currency_code($code);

    return _to_utf8(currency_format($code, $self->{'price'}, $format));
};

sub convert {
    my ($self, $from, $to, $format, $options) = @_;
    my $cfg = Handel->config;

    $from ||= $cfg->{'HandelCurrencyCode'};
    $to   ||= $cfg->{'HandelCurrencyCode'};
    eval '$options = ' .  ($options || $cfg->{'HandelCurrencyFormat'});

    return if uc($from) eq uc($to);

    throw Handel::Exception::Argument(
        -details => translate("Currency code '[_1]' is invalid or malformed", $from) . '.') unless
            constraint_currency_code($from);

    throw Handel::Exception::Argument(
        -details => translate("Currency code '[_1]' is invalid or malformed", $to) . '.') unless
            constraint_currency_code($to);

    my $result = defined $self->{'converter'} ?
        $self->{'converter'}->convert($self->{'price'}, $from, $to) :
        undef;

    eval 'use Locale::Currency::Format';
    if (!$@ && defined $result && $format) {
        return _to_utf8(currency_format($to, $result, $options));
    };

    return $result;
};

sub value {
    my $self = shift;
    
    return $self->{'price'};
};

sub stringify {
    my $self = shift;

    return $self->{'price'};
};

sub _to_utf8 {
    my $value = shift;

    if ($] >= 5.008) {
        require utf8;
        utf8::upgrade($value);
    };

    return $value;
};

1;
__END__

=head1 NAME

Handel::Currency - Price container to do currency conversion/formatting

=head1 SYNOPSIS

    use Handel::Currency;
    
    my $curr = Handel::Currenct-new(1.2);
    print $curr->format();          # 1.20 USD
    print $curr->format('CAD');     # 1.20 CAD
    print $curr->format(undef, 'FMT_SYMBOL');   # $1.20
    
    print 'Your price in Canadian Dollars is: ';
    print $curr->convert('USD', 'CAD');

=head1 DESCRIPTION

The Handel::Currency module provides basic currency formatting within Handel.
It can be used separately to format any number into a more friendly format:

    my $price = 1.23;
    my $currency = Handel::Currency->new($price);
    
    print $currency->format;

A new Handel::Currency object is automatically returned within the shopping
cart when calling C<subtotal>, C<total>, and C<price> as an lvalue:

    my $cart = Handel::Cart->load({id => '11111111-1111-1111-1111-111111111111'});

    print $cart->subtotal;              # 12.9
    print $cart->subtotal->format();    # 12.90 USD

By default, a Handel::Currency object will stringify to the original decimal
based price.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: $price

=back

The create a new Handel::Currency instance, simply call C<new> and pass in the
price to be formatted:

    my $currency = Handel::Currency->new(10.23);

=head1 METHODS

=head2 convert

=over

=item Arguments: $from, $to [, $format, $options]

=back

The C<convert> method converts the given price from one currency to another
using L<Finance::Currency::Convert::WebserviceX|Finance::Currency::Convert::WebserviceX>.

In situations where Finance::Currency::Convert::WebserviceX isn't installed,
C<convert> simply returns undef.

If no C<from> is specified, C<HandelCurrencyCode> will be used instead.

C<convert> throws a L<Handel::Exception::Argument|Handel::Exception::Argument>
if C<from> or C<to> aren't valid currency codes.

If C<format> is true, the result of the conversion will also be formatted
using the formatting options given or the default in C<HandelCurrencyFormat>.

=head2 format

=over

=item Arguments: $code [, $options]

=back

Returns the freshly formatted price in a currency and format declared in
C<Locale::Currency::Format|Locale::Currency::Format>. If no currency code or
format are specified, the defaults values from C<Handel::ConfigReader> are
used. Currently those defaults are C<USD> and C<FMT_STANDARD>.

It is also acceptable to specify different default values.
See L</"CONFIGURATION"> and C<Handel::ConfigReader> for further details.

In situations where Locale::Currency::Format isn't installed, C<format>
simply returns the price in its original format no harm no foul.

C<format> throws a L<Handel::Exception::Argument|Handel::Exception::Argument>
if C<code> isn't a valid currency code.

=head2 stringify

Returns C<value> in scalar context. For now, this returns the same thing that
was passed to C<new>. This maybe change in the future.

=head2 value

Returns the original price value given to C<new>. Always use this instead of
relying on stringification when deflating currency objects in DBIx::Class
schemas.

=head1 CONFIGURATION

=head2 HandelCurrencyCode

This sets the default currency code used when no code is passed into C<format>.
See L<Locale::Currency::Format|Locale::Currency::Format> for all available
currency codes. The default code is USD.

=head2 HandelCurrencyFormat

This sets the default options used to format the price. See
L<Locale::Currency::Format|Locale::Currency::Format> for all available currency
codes. The default format used is C<FMT_STANDARD>. Just like in
Locale::Currency::Format, you can combine options using C<|>.

=head1 SEE ALSO

L<Locale::Currency::Format>, L<Finance::Currency::Convert::WebserviceX>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
