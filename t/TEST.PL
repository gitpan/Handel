#!perl
# $Id: TEST.PL 1915 2007-06-24 15:35:46Z claco $
use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);