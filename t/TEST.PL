#!perl
# $Id: /local/CPAN/Handel/trunk/t/TEST.PL 1916 2007-06-24T15:35:46.298350Z claco  $
use strict;
use warnings FATAL => 'all';
use lib qw(lib);

use Apache::TestRunPerl ();

Apache::TestRunPerl->new->run(@ARGV);