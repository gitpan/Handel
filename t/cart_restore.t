#!perl -wT
# $Id: cart_restore.t 4 2004-12-28 03:01:15Z claco $
use Test::More;

BEGIN {
    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'SQLite not installed';
    } else {
        plan tests => 4;
    };

    use_ok('Handel::Cart');
    use_ok('Handel::Exception', ':try');
};


## test for Handel::Exception::Argument where first param is not a hashref
## or Handle::Cart subclass
{
    try {
        Handel::Cart->restore(id => '1234');
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};


## test for Handel::Exception::Argument where first param is not a hashref
## or Handle::Cart::Item subclass
{
    try {
        my $fakeitem = bless {}, 'FakeItem';
        Handel::Cart->restore($fakeitem);
    } catch Handel::Exception::Argument with {
        pass;
    } otherwise {
        fail;
    };
};
