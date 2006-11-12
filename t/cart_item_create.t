#!perl -wT
# $Id: cart_item_create.t 1489 2006-10-22 01:02:43Z claco $
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Scalar::Util qw/refaddr/;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 49;
    };

    use_ok('Handel::Cart::Item');
    use_ok('Handel::Subclassing::CartItem');
    use_ok('Handel::Constraints', 'constraint_uuid');
    use_ok('Handel::Exception', ':try');
};


## This is a hack, but it works. :-)
my $schema = Handel::Test->init_schema(no_populate => 1);
my $altschema = Handel::Test->init_schema(no_populate => 1, db_file => 'althandel.db', namespace => 'Handel::AltSchema');

&run('Handel::Cart::Item', 1);
&run('Handel::Subclassing::CartItem', 2);

sub run {
    my ($subclass, $dbsuffix) = @_;

    Handel::Test->populate_schema($schema, clear => 1);
    local $ENV{'HandelDBIDSN'} = $schema->dsn;


    ## test for Handel::Exception::Argument where first param is not a hashref
    {
        try {
            my $item = $subclass->create(sku => 'FOO');

            fail;
        } catch Handel::Exception::Argument with {
            pass;
        } otherwise {
            fail;
        };
    };


    ## create a new cart item object
    {
        my $data = {
            sku         => 'sku1234',
            price       => 1.23,
            quantity    => 2,
            description => 'My SKU',
            cart        => '00000000-0000-0000-0000-000000000000'
        };
        if ($subclass ne 'Handel::Cart::Item') {
            $data->{'custom'} = 'custom';
        };

        my $item = $subclass->create($data);
        isa_ok($item, 'Handel::Cart::Item');
        isa_ok($item, $subclass);
        ok(constraint_uuid($item->id));
        is($item->sku, 'sku1234');
        is($item->price, 1.23);
        is($item->quantity, 2);
        is($item->description, 'My SKU');
        is($item->total, 2.46);
        if ($subclass ne 'Handel::Cart::Item') {
            is($item->custom, 'custom');
        };


        is($item->price->format, '1.23 USD');
        is($item->price->format('FMT_NAME'), '1.23 US Dollar');
        is($item->total->format, '2.46 USD');
        is($item->total->format('FMT_NAME'), '2.46 US Dollar');
        {
            local $ENV{'HandelCurrencyCode'} = 'CAD';
            
            is($item->price->format, '1.23 CAD');
            is($item->price->format('FMT_NAME'), '1.23 Canadian Dollar');
            is($item->total->format, '2.46 CAD');
            is($item->total->format('FMT_NAME'), '2.46 Canadian Dollar');
        };
        
    };

};


## pass in storage instead
{
    my $storage = Handel::Cart::Item->storage_class->new;
    local $ENV{'HandelDBIDSN'} = $altschema->dsn;

    my $item = Handel::Cart::Item->create({
        sku         => 'sku1234',
        price       => 1.23,
        quantity    => 2,
        description => 'My Alt SKU',
        cart        => '00000000-0000-0000-0000-000000000000'
    }, {
        storage => $storage
    });
    isa_ok($item, 'Handel::Cart::Item');
    ok(constraint_uuid($item->id));
    is($item->sku, 'sku1234');
    is($item->price, 1.23);
    is($item->quantity, 2);
    is($item->description, 'My Alt SKU');
    is($item->total, 2.46);
    is(refaddr $item->result->storage, refaddr $storage, 'storage option used');
    is($altschema->resultset('CartItems')->search({description => 'My Alt SKU'})->count, 1, 'sku found in alt storage');
    is($schema->resultset('CartItems')->search({description => 'My Alt SKU'})->count, 0, 'sku not in class storage');
};
