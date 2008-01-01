#!perl -wT
# $Id: /local/CPAN/Handel/demo/createdb.pl 1043 2007-06-24T15:35:46.298350Z claco  $
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