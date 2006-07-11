#!perl -wT
# $Id: base_storage.t 1310 2006-07-09 04:01:49Z claco $
use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 14;

BEGIN {
    require_ok('Handel::Subclassing::Base1');
    require_ok('Handel::Subclassing::Base2');
    require_ok('Handel::Subclassing::Base3');
};


{
    ## make sure clone happens, and that they really are copies
    ok(Handel::Subclassing::Base1->has_storage);
    ok(!Handel::Subclassing::Base2->has_storage);

    is_deeply(Handel::Subclassing::Base1->storage, {
        schema_source => 'Base1',
        item_relationship => 'Base1',
        default_values => {id => 'Base1'}
    });
    
    is_deeply(
        Handel::Subclassing::Base2->storage,
        Handel::Subclassing::Base1->storage
    );
    
    is_deeply(Handel::Subclassing::Base2->storage, {
        schema_source => 'Base1',
        item_relationship => 'Base1',
        default_values => {id => 'Base1'}
    });
    
    Handel::Subclassing::Base2->storage({
        schema_source => 'Base2',
        item_relationship => 'Base2',
        default_values => {id => 'Base2'}
    });
    
    is_deeply(Handel::Subclassing::Base1->storage, {
        schema_source => 'Base1',
        item_relationship => 'Base1',
        default_values => {id => 'Base1'}
    });

    is_deeply(Handel::Subclassing::Base2->storage, {
        schema_source => 'Base2',
        item_relationship => 'Base2',
        default_values => {id => 'Base2'}
    });
    
    ok(Handel::Subclassing::Base2->has_storage);
    
    ## make sure we get a copy when storage_class differs from super
    ok(!Handel::Subclassing::Base3->has_storage);
    is_deeply(Handel::Subclassing::Base3->storage, Handel::Subclassing::Storage->new);
    isa_ok(Handel::Subclassing::Base3->storage, 'Handel::Subclassing::Storage');
};
