#!perl -wT
# $Id: checkout_messages.t 1486 2006-10-18 23:44:59Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test tests => 174;

    use_ok('Handel::Checkout');
    use_ok('Handel::Subclassing::Checkout');
    use_ok('Handel::Subclassing::CheckoutStash');
    use_ok('Handel::Subclassing::Stash');
    use_ok('Handel::Exception', ':try');
    use_ok('Handel::Checkout::TestMessage');
};


## This is a hack, but it works. :-)
&run('Handel::Checkout');
&run('Handel::Subclassing::Checkout');
&run('Handel::Subclassing::CheckoutStash');

sub run {
    my ($subclass) = @_;


    ## test for Handel::Exception::Argument where message is not a scalar
    {
        try {
            my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});

            $checkout->add_message([1, 2, 3]);

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## test for Handel::Exception::Argument where message is not a Handel::Checkout;:Message subclass
    {
        try {
            my $fake = bless {}, 'FakeModule';
            my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});

            $checkout->add_message($fake);

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## create a message and test new %options
    {
        my $message = Handel::Checkout::Message->new(
            text => 'My Message',
            otherproperty => 'foo'
        );

        isa_ok($message, 'Handel::Checkout::Message');
        is($message->text, 'My Message');
        is($message->otherproperty, 'foo');
    };


    ## add a message that isa Apache::AxKit::Exception::Error
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});
        my $axkitmessage = bless {text => 'Foo'}, 'Apache::AxKit::Exception::Error';

        $checkout->add_message($axkitmessage);

        my @messages = @{$checkout->messages};
        is(scalar @messages, 1);

        my $message = $messages[0];
        isa_ok($message, 'Handel::Checkout::Message');
        is($messages[0]->text . '', 'Foo');

        ok($message->filename);
        ok($message->line);

        $checkout->clear_messages;
        @messages = @{$checkout->messages};
        is(scalar @messages, 0);
    };


    ## add a message using a scalar
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});

        $checkout->add_message('This is a message');

        my @messages = @{$checkout->messages};
        is(scalar @messages, 1);

        my $message = $messages[0];
        isa_ok($message, 'Handel::Checkout::Message');
        is($messages[0]->text, 'This is a message');

        ok($message->filename);
        ok($message->line);

        $checkout->clear_messages;
        @messages = @{$checkout->messages};
        is(scalar @messages, 0);
    };


    ## add a message using Handel::Checkout::Message object
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});
        my $newmessage = Handel::Checkout::Message->new(
            text => 'This is a new message',
            package => 'package',
            filename => 'filename',
            line => 'line'
        );

        $checkout->add_message($newmessage);

        my @messages = @{$checkout->messages};
        is(scalar @messages, 1);

        my $message = $messages[0];
        isa_ok($message, 'Handel::Checkout::Message');
        is($messages[0]->text, 'This is a new message');
        is($messages[0]->package, 'package');
        is($messages[0]->filename, 'filename');
        is($messages[0]->line, 'line');
    };


    ## add a message using Handel::Checkout::Message object with existing package/file/line
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});
        my $newmessage = Handel::Checkout::Message->new(text => 'This is a new message');

        $checkout->add_message($newmessage);

        my @messages = @{$checkout->messages};
        is(scalar @messages, 1);

        my $message = $messages[0];
        isa_ok($message, 'Handel::Checkout::Message');
        is($messages[0]->text, 'This is a new message');

        ok($message->filename);
        ok($message->line);
    };


    ## add a message using Handel::Checkout::Message subclass
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});
        my $newmessage = Handel::Checkout::TestMessage->new(text => 'This is a new message');

        $checkout->add_message($newmessage);

        my @messages = @{$checkout->messages};
        is(scalar @messages, 1);

        my $message = $messages[0];
        isa_ok($message, 'Handel::Checkout::Message');
        is($messages[0]->text, 'This is a new message');

        ok($message->filename);
        ok($message->line);

        is("$message", 'This is a new message', 'message stringifies to message text');

        $message->{'text'} = undef;
        is("$message", ref $message, 'message stringifies to object in lue of text');
    };


    ## Check returns in list and scalar context
    {
        my $checkout = $subclass->new({pluginpaths => 'Handel::LOADNOTHING'});

        $checkout->add_message('Message1');
        $checkout->add_message('Message2');

        my @messages = @{$checkout->messages};
        is(scalar @messages, 2);

        isa_ok($messages[0], 'Handel::Checkout::Message');
        is($messages[0]->text, 'Message1');
        is($messages[0], 'Message1');
        ok($messages[0]->filename);
        ok($messages[0]->line);

        isa_ok($messages[1], 'Handel::Checkout::Message');
        is($messages[1]->text, 'Message2');
        is($messages[1], 'Message2');
        ok($messages[1]->filename);
        ok($messages[1]->line);

        my $messagesref = $checkout->messages;
        isa_ok($messagesref, 'ARRAY');
        isa_ok($messagesref->[0], 'Handel::Checkout::Message');
        is($messagesref->[0]->text, 'Message1');
        is($messagesref->[0], 'Message1');
        ok($messagesref->[0]->filename);
        ok($messagesref->[0]->line);

        is($messagesref->[1]->text, 'Message2');
        is($messagesref->[1], 'Message2');
        ok($messagesref->[1]->filename);
        ok($messagesref->[1]->line);
    };

};


package Apache::AxKit::Exception::Error;
use strict;
use warnings;
use overload
    '""' => sub{shift->{'text'}},
    fallback => 1;

1;
