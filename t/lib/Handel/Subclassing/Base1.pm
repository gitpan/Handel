# $Id: Base1.pm 1915 2007-06-24 15:35:46Z claco $
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
