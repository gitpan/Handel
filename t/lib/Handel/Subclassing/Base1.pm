# $Id: /local/Handel/trunk/t/lib/Handel/Subclassing/Base1.pm 1638 2007-06-24T15:35:46.298350Z claco  $
package Handel::Subclassing::Base1;
use strict;
use warnings;
use base qw/Handel::Base/;

__PACKAGE__->storage_class('Handel::Storage::DBIC');
__PACKAGE__->storage({
    schema_source => 'Base1',
    item_relationship => 'Base1',
    default_values => {id => 'Base1'}
});

1;
