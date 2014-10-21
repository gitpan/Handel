# $Id$
package Handel::Checkout::Message;
use strict;
use warnings;
use overload '""' => \&stringify, fallback => 1;

sub new {
    my ($class, %args) = @_;
    my $self = bless \%args, $class;

    return $self;
};

sub stringify {
    my $self = shift;

    if (my $text = $self->text) {
        return $text;
    } else {
        return ref $self;
    };
};

sub AUTOLOAD {
    my $self = shift;

    my $name = our $AUTOLOAD;
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

Handel::Checkout::Message stringifies to text() if available, otherwise it
returns $self.

=head1 CONSTRUCTOR

=head2 new

=over

=item Arguments: %options

=back

    my $message = Handel::Checkout::Message->new(
        text => 'My Message',
        otherproperty => 'some data'
    );

=head1 METHODS

=head2 stringify

Returns C<text> in scalar context. If no text is set, it returns the name of the
current message object.

=head1 SEE ALSO

L<Handel::Constants>, L<Handel::Checkout::Plugin>, L<Handel::Order>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
