# $Id: Base1.pm 1386 2006-08-26 01:46:16Z claco $
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
