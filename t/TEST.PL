#!perl
# $Id: TEST.PL 837 2005-09-19 22:56:39Z claco $
use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);