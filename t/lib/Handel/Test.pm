# $Id: Test.pm 1425 2006-09-23 19:31:16Z claco $
package Handel::Test;
use strict;
use warnings;

BEGIN {
    use base qw/Class::Accessor::Grouped/;
    __PACKAGE__->mk_group_accessors('inherited', qw/db_file/);

    use Handel::Test::Schema;
};

__PACKAGE__->db_file('t/var/handel.db');

## cribbed and modified from DBICTest in DBIx::Class tests
sub init_schema {
    my ($self, %args) = @_;
    my $db_file = $self->db_file;

    unlink($db_file) if -e $db_file;
    unlink($db_file . '-journal') if -e $db_file . '-journal';
    mkdir('t/var') unless -d 't/var';

    my $dsn = 'dbi:SQLite:' . __PACKAGE__->db_file;

    my $schema = Handel::Test::Schema->connect($dsn)->compose_namespace('Handel::TestSchema');
    $schema->storage->on_connect_do([
        'PRAGMA synchronous = OFF',
        'PRAGMA temp_store = MEMORY'
    ]);

    foreach my $source ($schema->sources) {
        $schema->source($source)->add_column('custom' => {
            data_type   => 'varchar',
            size        => 50,
            is_nullable => 1
        });
    };

    __PACKAGE__->deploy_schema($schema, %args);
    __PACKAGE__->populate_schema($schema, %args) unless $args{'no_populate'};

    return $schema;
};

sub deploy_schema {
    my ($self, $schema, %options) = @_;

    eval 'use SQL::Translator';
    if (!$@ && !$options{'no_deploy'}) {
        $schema->deploy();
    } else {
        open IN, 't/sql/test.sqlite.sql';
        my $sql;
        { local $/ = undef; $sql = <IN>; }
        close IN;
        ($schema->storage->dbh->do($_) || print "Error on SQL: $_\n") for split(/;\n/, $sql);
    };
};

sub populate_schema {
    my ($self, $schema, %options) = @_;

    if ($options{'clear'}) {
        foreach my $source ($schema->sources) {
            $schema->resultset($source)->delete_all;
        };
    };

    $schema->populate('Carts', [
        [ qw/id shopper type name description custom/ ],
        ['11111111-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111',0,'Cart 1', 'Test Temp Cart 1', 'custom'],
        ['22222222-2222-2222-2222-222222222222','11111111-1111-1111-1111-111111111111',0,'Cart 2', 'Test Temp Cart 2', 'custom'],
        ['33333333-3333-3333-3333-333333333333','33333333-3333-3333-3333-333333333333',1,'Cart 3', 'Saved Cart 1', 'custom']
    ]);

    $schema->populate('CartItems', [
        [ qw/id cart sku quantity price description custom/ ],
        ['11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111','SKU1111',1,1.11,'Line Item SKU 1', 'custom'],
        ['22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111','SKU2222',2,2.22,'Line Item SKU 2', 'custom'],
        ['33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222','SKU3333',3,3.33,'Line Item SKU 3', 'custom'],
        ['44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333','SKU4444',4,4.44,'Line Item SKU 4', 'custom'],
        ['55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333','SKU1111',5,5.55,'Line Item SKU 5', 'custom']
    ]);

    $schema->populate('Orders', [
        [ qw/id shopper type billtofirstname billtolastname billtoaddress1 billtoaddress2 billtoaddress3 billtocity billtostate billtozip billtocountry billtodayphone billtonightphone billtofax billtoemail comments created handling number shipmethod shipping shiptosameasbillto shiptofirstname shiptolastname shiptoaddress1 shiptoaddress2 shiptoaddress3 shiptocity shiptostate shiptozip shiptocountry shiptodayphone shiptonightphone shiptofax shiptoemail subtotal total updated tax custom/ ],
        ['11111111-1111-1111-1111-111111111111','11111111-1111-1111-1111-111111111111',0,'Christopher','Laco','BillToAddress1','BillToAddress2','BillToAddress3','BillToCity','BillToState','BillToZip','BillToCountry','1-111-111-1111','2-222-222-2222','3-333-333-3333','mendlefarg@gmail.com','Comments','2005-07-15 20:12:34',8.95,'O123456789','UPS Ground',23.95,0,'Christopher','Laco','ShipToAddress1','ShipToAddress2','ShipToAddress3','ShipToCity','ShipToState','ShipToZip','ShipToCountry','4-444-444-4444','5-555-555-5555','6-666-666-6666','chrislaco@hotmail.com',5.55,37.95,'2005-07-16 20:12:34', 6.66, 'custom'],
        ['22222222-2222-2222-2222-222222222222','11111111-1111-1111-1111-111111111111',1,'Christopher','Laco','BillToAddress1','BillToAddress2','BillToAddress3','BillToCity','BillToState','BillToZip','BillToCountry','1-111-111-1111','2-222-222-2222','3-333-333-3333','mendlefarg@gmail.com','Comments','2005-07-15 20:12:34',8.95,'O123456789','UPS Ground',23.95,0,'Christopher','Laco','ShipToAddress1','ShipToAddress2','ShipToAddress3','ShipToCity','ShipToState','ShipToZip','ShipToCountry','4-444-444-4444','5-555-555-5555','6-666-666-6666','chrislaco@hotmail.com',5.55,37.95,'2005-07-16 20:12:34', 6.66, 'custom'],
        ['33333333-3333-3333-3333-333333333333','33333333-3333-3333-3333-333333333333',1,'Christopher','Laco','BillToAddress1','BillToAddress2','BillToAddress3','BillToCity','BillToState','BillToZip','BillToCountry','1-111-111-1111','2-222-222-2222','3-333-333-3333','mendlefarg@gmail.com','Comments','2005-07-15 20:12:34',8.95,'O123456789','UPS Ground',23.95,0,'Christopher','Laco','ShipToAddress1','ShipToAddress2','ShipToAddress3','ShipToCity','ShipToState','ShipToZip','ShipToCountry','4-444-444-4444','5-555-555-5555','6-666-666-6666','chrislaco@hotmail.com',5.55,37.95,'2005-07-16 20:12:34', 6.66, 'custom']
    ]);

    $schema->populate('OrderItems', [
        [ qw/id orderid sku quantity price total description custom/ ],
        ['11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111','SKU1111',1,1.11,0,'Line Item SKU 1', 'custom'],
        ['22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111','SKU2222',2,2.22,0,'Line Item SKU 2', 'custom'],
        ['33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222','SKU3333',3,3.33,0,'Line Item SKU 3', 'custom'],
        ['44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333','SKU4444',4,4.44,0,'Line Item SKU 4', 'custom'],
        ['55555555-5555-5555-5555-555555555555', '33333333-3333-3333-3333-333333333333','SKU1111',5,5.55,0,'Line Item SKU 5', 'custom']
    ]);
};

1;
