#!perl -wT
# $Id: storage_clone.t 1259 2006-06-29 01:24:53Z claco $
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Handel::TestHelper qw(executesql);

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 37;
    };

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    ## Setup SQLite DB for tests
    my $dbfile  = "t/storage_clone.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';

    unlink $dbfile;
    executesql($db, $create);

    ## create a new storage and check schema_instance configuration
    my $sub = sub{};
    my $storage = Handel::Storage->new({
        cart_class         => 'Handel::Cart',
        item_class         => 'Handel::Cart::Item',
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Carts',
        connection_info    => [$db],
        default_values     => {id => 1, name => 'New Cart'},
        validation_profile => {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]},
        add_columns        => [qw/one two/],
        remove_columns     => [qw/name/],
        constraints        => {
            id   => {'check_id' => $sub},
            name => {'check_name' => $sub}},
        currency_columns   => [qw/name/]
    });
    isa_ok($storage, 'Handel::Storage');

    my $clone = $storage->clone;
    isa_ok($clone, 'Handel::Storage');
    
    is_deeply($clone, $storage);
    
    ## make them diverge
    $clone->cart_class('Handel::Base');
    is($clone->cart_class, 'Handel::Base');
    is($storage->cart_class, 'Handel::Cart');

    $clone->item_class('Handel::Base');
    is($clone->item_class, 'Handel::Base');
    is($storage->item_class, 'Handel::Cart::Item');

    $clone->schema_class('Handel::Base');
    is($clone->schema_class, 'Handel::Base');
    is($storage->schema_class, 'Handel::Cart::Schema');

    $clone->schema_source('Items');
    is($clone->schema_source, 'Items');
    is($storage->schema_source, 'Carts');

    $clone->iterator_class('Handel::Base');
    is($clone->iterator_class, 'Handel::Base');
    is($storage->iterator_class, 'Handel::Iterator');

    $clone->currency_class('Handel::Base');
    is($clone->currency_class, 'Handel::Base');
    is($storage->currency_class, 'Handel::Currency');
    
    $clone->item_relationship('rel_items');
    is($clone->item_relationship, 'rel_items');
    is($storage->item_relationship, 'items');
    
    $clone->autoupdate(3);
    is($clone->autoupdate, 3);
    is($storage->autoupdate, 1);

    $clone->connection_info(['MyDSN', 'MyUser', 'MyPass']);
    is_deeply($clone->connection_info, ['MyDSN', 'MyUser', 'MyPass']);
    is_deeply($storage->connection_info, [$db]);

    $clone->default_values->{id} = 2;
    is_deeply($clone->default_values, {id => 2, name => 'New Cart'});
    is_deeply($storage->default_values, {id => 1, name => 'New Cart'});

    $clone->validation_profile->{'cart'} = [qw/foo/];
    is_deeply($clone->validation_profile, {cart=>['foo']});
    is_deeply($storage->validation_profile, {cart => [param1 => [ ['BLANK'], ['ASCII', 2, 12] ]]});

    $clone->add_columns('quix');
    is_deeply($clone->_columns_to_add, [qw/one two quix/]);
    is_deeply($storage->_columns_to_add, [qw/one two/]);
    
    $clone->remove_columns('phil');
    is_deeply($clone->_columns_to_remove, [qw/name phil/]);
    is_deeply($storage->_columns_to_remove, [qw/name/]);
    
    my $foo = sub{};
    $clone->add_constraint('foo', 'check foo', $foo);
    is_deeply($clone->constraints, {
            id   => {'check_id' => $sub},
            name => {'check_name' => $sub},
            foo  => {'check foo' => $foo}
    });
    is_deeply($storage->constraints, {
            id   => {'check_id' => $sub},
            name => {'check_name' => $sub}
    });

    push @{$clone->currency_columns}, 'dongle';
    is_deeply($clone->currency_columns, [qw/name dongle/]);
    is_deeply($storage->currency_columns, [qw/name/]);

    undef $clone;

    ## throw exception as a class method
    {
        try {
            my $storage = Handel::Storage->clone;

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };
    
    ## throw exception as with existing schema_instance

    
    {
        try {
            my $schema = $storage->schema_instance;
            $storage->clone;
            
            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            diag shift;
            fail;
        };
    };
};
