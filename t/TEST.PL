#!perl
# $Id: TEST.PL 63 2005-01-10 02:21:45Z claco $
use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);