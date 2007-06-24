#!perl
# $Id: SMOKE.PL 1915 2007-06-24 15:35:46Z claco $
use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestSmoke ();

Apache::TestSmoke->new(@ARGV)->run;