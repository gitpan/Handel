#!perl
# $Id: SMOKE.PL 169 2005-02-13 01:48:29Z claco $
use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestSmoke ();

Apache::TestSmoke->new(@ARGV)->run;