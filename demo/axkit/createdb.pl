#!perl -wT
# $Id: createdb.pl 179 2005-02-15 04:29:33Z claco $
use strict;
use warnings;
use lib '../../t/lib';
use Handel::TestHelper qw(executesql);

my $dbfile  = 'cart.db';
my $db      = "dbi:SQLite:dbname=$dbfile";
my $create  = '../../t/sql/cart_create_table.sql';

executesql($db, $create);