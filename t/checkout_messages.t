#!perl -wT
# $Id: checkout_messages.t 701 2005-08-10 01:31:52Z claco $
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::Checkout::TestMessage;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 43;
    };

    use_ok('Handel::Checkout');
    use_ok('Handel::Exception', ':try');
};


## test for Handel::Exception::Argument where message is not a scalar
{
    try {
        my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::LOADNOTHING'});

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
        my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::LOADNOTHING'});

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


## add a message using a scalar
{
    my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::LOADNOTHING'});

    $checkout->add_message('This is a message');

    my @messages = @{$checkout->messages};
    is(scalar @messages, 1);

    my $message = $messages[0];
    isa_ok($message, 'Handel::Checkout::Message');
    is($messages[0]->text, 'This is a message');

    ok($message->filename);
    ok($message->line);
};


## add a message using Handel::Checkout::Message object
{
    my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::LOADNOTHING'});
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
    my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::LOADNOTHING'});
    my $newmessage = Handel::Checkout::TestMessage->new(text => 'This is a new message');

    $checkout->add_message($newmessage);

    my @messages = @{$checkout->messages};
    is(scalar @messages, 1);

    my $message = $messages[0];
    isa_ok($message, 'Handel::Checkout::Message');
    is($messages[0]->text, 'This is a new message');

    ok($message->filename);
    ok($message->line);
};


## Check returns in list and scalar context
{
    my $checkout = Handel::Checkout->new({pluginpaths => 'Handel::LOADNOTHING'});

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