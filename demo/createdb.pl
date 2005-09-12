#!perl -wT
# $Id: createdb.pl 762 2005-08-30 00:23:54Z claco $
use strict;
use warnings;
use lib '../t/lib';
use Handel::TestHelper qw(executesql);

my $dbfile  = 'handel.db';
my $db      = "dbi:SQLite:dbname=$dbfile";
my $cart    = '../t/sql/cart_create_table.sql';
my $order   = '../t/sql/order_create_table.sql';

executesql($db, $cart);
executesql($db, $order);