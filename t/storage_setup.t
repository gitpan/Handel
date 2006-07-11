#!perl -wT
# $Id: storage_setup.t 1318 2006-07-10 23:42:32Z claco $
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
        plan tests => 38;
    };

    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    ## Setup SQLite DB for tests
    my $dbfile  = "t/storage_setup.db";
    my $db      = "dbi:SQLite:dbname=$dbfile";
    my $create  = 't/sql/cart_create_table.sql';

    unlink $dbfile;
    executesql($db, $create);

    ## setup a schema
    my $storage = Handel::Storage->new({
        cart_class         => 'Handel::Base',
        item_class         => 'Handel::Base',
        schema_class       => 'Handel::Base',
        schema_source      => 'SchemaSource',
        iterator_class     => 'Handel::Base',
        currency_class     => 'Handel::Base',
        item_relationship  => 'ItemRelationship',
        autoupdate         => 2,
        connection_info    => [qw/MyDSN MyUser MyPass/, {}],
        default_values     => {foo => 'bar',baz => 'quix'},
        validation_profile => [param1 => [ ['NOT_BLANK'], ['LENGTH', 4, 10] ]],
        add_columns        => [qw/foo bar baz/],
        remove_columns     => [qw/quix temp/],
        constraints        => {
            foo => {'check_foo' => sub{}},
            bar => {'check_bar' => sub{}}
        },
        currency_columns   => [qw/foo bar/],
        table_name         => 'mycarts'
    });

    isa_ok($storage, 'Handel::Storage');

    ## now call setup again and make sure it overides the old
    my $default_values = {
        foo => 'new',
        baz => 'old'
    };

    my $validation_profile = [
        param1 => [ ['BLANK'], ['ASCII', 2, 12] ]
    ];

    my $constraints = {
        one => sub{},
        two => sub{}
    };

    my $currency_columns = [qw/baz quix/];
    my $connection_info = [qw/MyOtherDSN MyOtherUser MyOtherPass/, {}];
    my $add_columns = [qw/one two three/];
    my $remove_columns = [qw/this that/];

    $storage->setup({
        cart_class         => 'Handel::Cart',
        item_class         => 'Handel::Cart::Item',
        schema_class       => 'Handel::Cart::Schema',
        schema_source      => 'Cart::Item',
        iterator_class     => 'Handel::Iterator',
        currency_class     => 'Handel::Currency',
        item_relationship  => 'rel_items',
        autoupdate         => 3,
        connection_info    => $connection_info,
        default_values     => $default_values,
        validation_profile => $validation_profile,
        add_columns        => $add_columns,
        remove_columns     => $remove_columns,
        constraints        => $constraints,
        currency_columns   => $currency_columns,
        table_name         => 'newcarts'
    });

    ## cart_class
    is($storage->cart_class, 'Handel::Cart');
    is(Handel::Storage->cart_class, undef);

    ## item_class
    is($storage->item_class, 'Handel::Cart::Item');
    is(Handel::Storage->item_class, undef);

    ## schema_class
    is($storage->schema_class, 'Handel::Cart::Schema');
    is(Handel::Storage->schema_class, undef);

    ## schema_source
    is($storage->schema_source, 'Cart::Item');
    is(Handel::Storage->schema_source, undef);

    ## iterator_class
    is($storage->iterator_class, 'Handel::Iterator');
    is(Handel::Storage->iterator_class, 'Handel::Iterator');

    ## currency_class
    is($storage->currency_class, 'Handel::Currency');
    is(Handel::Storage->currency_class, 'Handel::Currency');

    ## item_relationship
    is($storage->item_relationship, 'rel_items');
    is(Handel::Storage->item_relationship, 'items');

    ## autoupdate
    is($storage->autoupdate, 3);
    is(Handel::Storage->autoupdate, 1);

    ## connection_info
    is_deeply($storage->connection_info, $connection_info);
    is(Handel::Storage->connection_info, undef);

    ## default_values
    is_deeply($storage->default_values, $default_values);
    is(Handel::Storage->default_values, undef);

    ## validation_profile
    is_deeply($storage->validation_profile, $validation_profile);
    is(Handel::Storage->validation_profile, undef);

    ## constraints
    is_deeply($storage->constraints, $constraints);
    is(Handel::Storage->constraints, undef);

    ## add_columns
    is_deeply($storage->_columns_to_add, $add_columns);
    is(Handel::Storage->_columns_to_add, undef);

    ## remove_columns
    is_deeply($storage->_columns_to_remove, $remove_columns);
    is(Handel::Storage->_columns_to_remove, undef);

    ## currenct_columns
    is_deeply($storage->currency_columns, $currency_columns);
    is(Handel::Storage->currency_columns, undef);

    ## table_name
    is_deeply($storage->table_name, 'newcarts');
    is(Handel::Storage->table_name, undef);

    ## throw exception if setup gets no $args
    {
        try {
            my $storage = Handel::Storage->new;
            $storage->setup();

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };

    ## throw exception if schema_instance already exists
    {
        my $storage = Handel::Storage->new;
        $storage->setup({
            schema_class    => 'Handel::Cart::Schema',
            schema_source   => 'Carts',
            connection_info => [$db]
        });
        my $schema_instance = $storage->schema_instance;
        isa_ok($schema_instance, 'Handel::Cart::Schema');

    try {
            $storage->setup({
                schema_class => 'Handel::Order::Schema'
            });

            fail('no exception thrown');
        } catch Handel::Exception::Storage with {
            pass;
        } otherwise {
            fail;
        };
    };
};
