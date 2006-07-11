#!perl -wT
# $Id: storage_new.t 1318 2006-07-10 23:42:32Z claco $
use strict;
use warnings;
use Test::More tests => 35;

BEGIN {
    use_ok('Handel::Storage');
    use_ok('Handel::Exception', ':try');
};


{
    my $default_values = {
        foo => 'bar',
        baz => 'quix'
    };

    my $validation_profile = [
        param1 => [ ['NOT_BLANK'], ['LENGTH', 4, 10] ]
    ];

    my $constraints = {
        foo => {'check_foo' => sub{}},
        bar => {'check_bar' => sub{}}
    };

    my $connection_info = [qw/MyDSN MyUser MyPass/, {}];
    my $add_columns = [qw/foo bar baz/];
    my $remove_columns = [qw/quix temp/];
    my $currency_columns = [qw/foo/];

    my $storage = Handel::Storage->new({
        cart_class         => 'Handel::Base',
        item_class         => 'Handel::Base',
        schema_class       => 'Handel::Base',
        schema_source      => 'SchemaSource',
        iterator_class     => 'Handel::Base',
        currency_class     => 'Handel::Base',
        item_relationship  => 'ItemRelationship',
        autoupdate         => 2,
        connection_info    => $connection_info,
        default_values     => $default_values,
        validation_profile => $validation_profile,
        add_columns        => $add_columns,
        remove_columns     => $remove_columns,
        constraints        => $constraints,
        currency_columns   => $currency_columns,
        table_name         => 'mycarts'
    });

    isa_ok($storage, 'Handel::Storage');

    ## cart_class
    is($storage->cart_class, 'Handel::Base');
    is(Handel::Storage->cart_class, undef);

    ## item_class
    is($storage->item_class, 'Handel::Base');
    is(Handel::Storage->item_class, undef);

    ## schema_class
    is($storage->schema_class, 'Handel::Base');
    is(Handel::Storage->schema_class, undef);

    ## schema_source
    is($storage->schema_source, 'SchemaSource');
    is(Handel::Storage->schema_source, undef);

    ## iterator_class
    is($storage->iterator_class, 'Handel::Base');
    is(Handel::Storage->iterator_class, 'Handel::Iterator');

    ## currency_class
    is($storage->currency_class, 'Handel::Base');
    is(Handel::Storage->currency_class, 'Handel::Currency');
    
    ## item_relationship
    is($storage->item_relationship, 'ItemRelationship');
    is(Handel::Storage->item_relationship, 'items');

    ## autoupdate
    is($storage->autoupdate, 2);
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

    ## currency_columns
    is_deeply($storage->currency_columns, $currency_columns);
    is(Handel::Storage->currency_columns, undef);

    ## table_name
    is_deeply($storage->table_name, 'mycarts');
    is(Handel::Storage->table_name, undef);
};
