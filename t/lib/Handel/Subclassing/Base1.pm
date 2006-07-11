# $Id: Base1.pm 1297 2006-07-07 22:37:05Z claco $
package Handel::Subclassing::Base1;
use strict;
use warnings;
use base qw/Handel::Base/;

__PACKAGE__->storage({
    schema_source => 'Base1',
    item_relationship => 'Base1',
    default_values => {id => 'Base1'}
});

1;
