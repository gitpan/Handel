# $Id: Message.pm 576 2005-07-09 02:23:04Z claco $
package Handel::Checkout::Message;
use strict;
use warnings;
use vars '$AUTOLOAD';

sub new {
    my ($class, %args) = @_;
    my $self = bless \%args, ref $class || $class;

    return $self;
};

sub AUTOLOAD {
    my $self = shift;

    my $name = $AUTOLOAD;
    $name =~ s/.*://;

    if (@_) {
        return $self->{$name} = shift;
    } else {
        return $self->{$name};
    };
};

1;
__END__

=head1 NAME

Handel::Checkout::Message - Checkout Pipeline Process Message

=head1 SYNOPSIS

    use Handel::Checkout::Message;

    my $message = Handel::Checkout::Message->new(
        text => 'My Message',
        otherproperty => 'some data'
    );

    $message->tempdata('stuff');

    print $message->text;
    print $message->otherproperty;
    print $message->tempdata;

=head1 DESCRIPTION

Handel::Checkout::Message is just a simple blessed hash to hold any and every
property you throw at it. It is autoloaded, so any instance method simple loads
or sets the corresponding key value in the hash.

=head1 CONSTRUCTOR

=head2 new([%options])

    my $message = Handel::Checkout::Message->new(
        text => 'My Message',
        otherproperty => 'some data'
    );

=head1 SEE ALSO

L<Handel::Constants>, L<Handel::Checkout::Plugin>, L<Handel::Order>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
