# $Id: Handel.pm 1579 2006-11-12 21:47:22Z claco $
package Module::Starter::Handel;
use strict;
use warnings;

BEGIN {
    use base qw/Module::Starter::Simple/;
    use File::Spec::Functions qw/catfile catdir/;
    use File::Path qw/mkpath/;
    use FileHandle;
};

=head1 NAME

Module::Starter::Handel - Module::Starter module for Handel

=head1 SYNOPSIS

    module-starter --class=Module::Starter::Handel --module=MyProject --author="Me" --email="me@example.com" --verbose
    
    Created MyProject
    Created MyProject\lib\MyProject
    Created MyProject\lib\MyProject\Cart.pm
    Created MyProject\lib\MyProject\Cart
    Created MyProject\lib\MyProject\Cart\Item.pm
    Created MyProject\lib\MyProject\Storage
    Created MyProject\lib\MyProject\Storage\Cart.pm
    Created MyProject\lib\MyProject\Storage\Cart
    Created MyProject\lib\MyProject\Storage\Cart\Item.pm
    Created MyProject\lib\MyProject\Order.pm
    Created MyProject\lib\MyProject\Order
    Created MyProject\lib\MyProject\Order\Item.pm
    Created MyProject\lib\MyProject\Storage\Order.pm
    Created MyProject\lib\MyProject\Storage\Order
    Created MyProject\lib\MyProject\Storage\Order\Item.pm
    Created MyProject\lib\MyProject\Checkout.pm
    Created MyProject\t
    Created MyProject\t\pod-coverage.t
    Created MyProject\t\pod.t
    Created MyProject\t\boilerplate.t
    Created MyProject\t\00-load.t
    Created MyProject\.cvsignore
    Created MyProject\Makefile.PL
    Created MyProject\MANIFEST
    Created MyProject\script\myproject_setup.pl
    Created starter directories and files

=head1 DESCRIPTION

Module::Starter::Handel is a Module::Starter class that helps generate a basic framework for Handel based
projects.

=head1 METHODS

=head2 create_distro

See L<Module::Starter::Simple/create_distro>.

=cut

sub create_distro {
    my $class = shift;
    my %options = @_;
    my $modules = $options{'modules'};
    my $base    = $modules->[0] || 'MyProject';
    my $setup_pl = lc($base) . '_setup.pl';
       $setup_pl =~ s/::/_/;

    $options{'__base_name'} = $base;
    $options{'__setup_pl'}  = $setup_pl;

    $options{'modules'} = [
        $base,
        "$base\:\:Cart",
        "$base\:\:Cart::Item",
        "$base\:\:Storage::Cart",
        "$base\:\:Storage::Cart::Item",
        "$base\:\:Order",
        "$base\:\:Order::Item",
        "$base\:\:Storage::Order",
        "$base\:\:Storage::Order::Item",
        "$base\:\:Checkout"
    ];

    if (!$options{'distro'}) {
        $options{'distro'} = $base;
    };

    if ($options{'dir'}) {
        $options{'basedir'} = $options{'dir'};
    } else {
        $options{'basedir'} = $options{'distro'};
    };
    $options{'scriptsdir'} = catdir($options{'basedir'}, 'script');
    $options{'datadir'} = catdir($options{'basedir'}, 'data');
    $options{'setup.pl'} = catfile($options{'scriptsdir'}, $setup_pl);

    $class->SUPER::create_distro(%options);

    mkpath($options{'scriptsdir'});
    mkpath($options{'datadir'});
    
    my $setup = $class->_get_file('setup');
    $setup =~ s/\[% app %\]/$base/g;
    FileHandle->new('>' . $options{'setup.pl'})->print($setup);
    print "Created " . $options{'setup.pl'}, "\n";
};

=head2 module_guts

See L<Module::Starter::Simple/module_guts>.

=cut

sub module_guts {
    my ($self, $name) = @_;
    my $base = $self->{'__base_name'};
    my $short = $name;
    $short =~ s/^$base\:\://;
    $short =~ s/^$base//;
    $short ||= 'main';

    ## cheat and use tt tags....will convert later...maybe
    my $contents = $self->_get_file($short) || '';
    $contents =~ s/\[% app %\]/$base/g;
    $contents =~ s/\[% module %\]/$name/g;

    return $contents
};

=head2 t_guts

See L<Module::Starter::Simple/t_guts>.

=cut

sub t_guts {
    my ($self, @modules) = @_;

    my $tests = scalar @modules;
    my $basic = <<"EOM";
#!perl -wT
use strict;
use warnings;
use Test::More tests => $tests;

BEGIN {
EOM

    foreach (@modules) {
        $basic .= "    use_ok('$_');\n";
    };
    $basic .= "};\n";


    return (
        'basic.t'        => $basic,
        'pod_syntax.t'   => $self->_get_file('pod_syntax'),
        'pod_spelling.t' => $self->_get_file('pod_spelling'),
        'pod_coverage.t' => $self->_get_file('pod_coverage'),
    );
};

=head2 MANIFEST_guts

=cut

sub MANIFEST_guts {
    my $self = shift;
    my $manifest = $self->SUPER::MANIFEST_guts(@_);

    $manifest .= 'script/' . $self->{'__setup_pl'};

    return $manifest;
};

## shamelessly ripped from Catalyst::Helper
## no critic (RequireInitializationForLocalVars, ProhibitPunctuationVars, ProhibitStringyEval)
my %cache;
sub _get_file {
    my ($self, $file) = @_;
    my $class = ref $self;
    if (!$class) {
        $class = $self;
    };
    if (!$cache{$class}) {
        local $/;
        $cache{$class} = eval "package $class; <DATA>";
    };
    my $data = $cache{$class};
    my @files = split /^__(.+)__\r?\n/m, $data;
    shift @files;
    while (@files) {
        my ( $name, $content ) = splice @files, 0, 2;
        return $content if $name eq $file;
    };

    return;
};

=head1 SEE ALSO

L<Module::Starter>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

=cut

1;
__DATA__

=begin pod_to_ignore

__main__
package [% module %];
use strict;
use warnings;
our $VERSION = '0.01';

1;
__Cart__
package [% module %];
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Cart/;
};

__PACKAGE__->storage_class('[% app %]::Storage::Cart');
__PACKAGE__->item_class('[% module %]::Item');
__PACKAGE__->create_accessors;

1;
__Cart::Item__
package [% module %];
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Cart::Item/;
};

__PACKAGE__->storage_class('[% app %]::Storage::Cart::Item');
__PACKAGE__->create_accessors;

1;
__Storage::Cart__
package [% module %];
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Storage::DBIC::Cart/;
};

__PACKAGE__->item_storage_class('[% app %]::Storage::Cart::Item');

1;
__Storage::Cart::Item__
package [% module %];
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Storage::DBIC::Cart::Item/;
};

1;
__Order__
package [% module %];
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Order/;
};

__PACKAGE__->storage_class('[% app %]::Storage::Order');
__PACKAGE__->item_class('[% module %]::Item');
__PACKAGE__->cart_class('[% app %]::Cart');
__PACKAGE__->checkout_class('[% app %]::Checkout');
__PACKAGE__->create_accessors;

1;
__Order::Item__
package [% module %];
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Order::Item/;
};

__PACKAGE__->storage_class('[% app %]::Storage::Order::Item');
__PACKAGE__->create_accessors;

1;
__Storage::Order__
package [% module %];
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Storage::DBIC::Order/;
};

__PACKAGE__->item_storage_class('[% app %]::Storage::Order::Item');

1;
__Storage::Order::Item__
package [% module %];
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Storage::DBIC::Order::Item/;
};

1;
__Checkout__
package [% module %];
use strict;
use warnings;

BEGIN {
    use base qw/Handel::Checkout/;
};

__PACKAGE__->order_class('[% app %]::Order');

1;
__pod_syntax__
#!perl -wT
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

    eval 'use Test::Pod 1.00';
    plan skip_all => 'Test::Pod 1.00 not installed' if $@;
};

all_pod_files_ok();
__pod_spelling__
#!perl -w
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

    eval 'use Test::Spelling 0.11';
    plan skip_all => 'Test::Spelling 0.11 not installed' if $@;
};

set_spell_cmd('aspell list');

# Add your stopworkds to __DATA__ and uncomment the next line
# add_stopwords(<DATA>);

all_pod_files_spelling_ok();
__pod_coverage__
#!perl -wT
use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};

    eval 'use Test::Pod::Coverage 1.04';
    plan skip_all => 'Test::Pod::Coverage 1.04' if $@;

    eval 'use Pod::Coverage 0.14';
    plan skip_all => 'Pod::Coverage 0.14 not installed' if $@;
};

all_pod_coverage_ok();
__setup__
#!perl -w
use strict;
use warnings;

=head1 NAME

setup - installs Handel schema into the specified database

=cut

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../lib";
    use [% app %]::Storage::Cart;
    use [% app %]::Storage::Order;
    use Getopt::Long;
    use Pod::Usage;
    use File::Spec::Functions qw/catfile/;
};

my ($dsn, $user, $pass);

GetOptions(
    "dsn=s"  => \$dsn,
    "user=s" => \$user,
    "pass=s" => \$pass,
    default  => sub {$dsn ||= 'dbi:SQLite:dbname=' . catfile("$FindBin::Bin/../data", 'handel.db')},
    help     => sub {pod2usage(1);},
) or pod2usage(2);

die 'No dsn specified!' unless $dsn;

[% app %]::Storage::Cart->new({
    connection_info => [$dsn, $user, $pass]
})->schema_instance->deploy;

[% app %]::Storage::Order->new({
    connection_info => [$dsn, $user, $pass]
})->schema_instance->deploy;

print "Installed/created database schema\n";

=head1 SYNOPSIS

setup [options]

Options:

    --dsn      Create the default schema in the specified dsn
    --user     The database user name
    --pass     The database users password
    --default  Create the default database in data/handel.db
    --help     Show this message

Example:

    perl scripts/setup.pl --default
    perl scripts/setup.pl --dsn=dbi:mysql:dbname=handel:host=localhost

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

=cut

__END__
