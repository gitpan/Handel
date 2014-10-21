# $Id: DBI.pm 478 2005-03-22 00:50:54Z claco $
package Handel::DBI;
use strict;
use warnings;

BEGIN {
    use base 'Class::DBI';
    use Handel::ConfigReader;
    use Handel::Exception;
    use Handel::L10N qw(translate);
};

my $cfg = Handel::ConfigReader->new();
my $db_driver  = $cfg->{'HandelDBIDriver'}   || $cfg->{'db_driver'};
my $db_host    = $cfg->{'HandelDBIHost'}     || $cfg->{'db_host'};
my $db_port    = $cfg->{'HandelDBIPort'}     || $cfg->{'db_port'};
my $db_name    = $cfg->{'HandelDBIName'}     || $cfg->{'db_name'};
my $db_user    = $cfg->{'HandelDBIUser'}     || $cfg->{'db_user'};
my $db_pass    = $cfg->{'HandelDBIPassword'} || $cfg->{'db_pass'};
my $datasource = "dbi:$db_driver:dbname=$db_name";

if ($db_host) {
    $datasource .= ";host=$db_host";
};

if ($db_port) {
    $datasource .= ";port=$db_port";
};

__PACKAGE__->connection($datasource, $db_user, $db_pass);

sub _croak {
    my ($self, $message, %info) = @_;
    my $method = $info{method} || '';

    if ($method eq 'validate_column_values') {
        my $data = $info{data};
        throw Handel::Exception::Constraint(
            -details =>
            join(' ' . translate('has invalid value') . ', ', keys %$data)
        );
    } elsif ($method eq 'create') {
        my $details;

        if ($message =~ /insert new.*column\s+(.*)\s+is not unique/) {
            $details = translate("[_1] value already exists", $1);
        } else {
            $details = $message;
        };
        throw Handel::Exception::Constraint(-details => $details );
    } else {
        throw Handel::Exception(-text => $message);
    };

    return;
};

sub accessor_name {
    my ($class, $column) = @_;

    $column =~ s/^(price)$/_$1/;

    return $column;
}

sub has_wildcard {
    my $filter = shift;

    for (values %{$filter}) {
        return 1 if $_ =~ /\%/;
    };

    return undef;
};

sub uuid {
    my $uuidstring = '';

    if (eval{require UUID}) {
        my $uuid;
        UUID::generate($uuid);
        UUID::unparse($uuid, $uuidstring);
    } elsif (eval{require Data::UUID}) {
        my $ug = Data::UUID->new;
        my $uuid = $ug->create;
        $uuidstring = $ug->to_string($uuid);
    } elsif (eval{
            # for some reason 'no warnings' won't squelch
            # the 'too late for INIT' warning in Win32::API::Type
            local $^W = 0;
            require Win32::Guidgen;
        }) {
        $uuidstring = Win32::Guidgen::create();
    } elsif (eval{require Win32API::GUID}) {
        $uuidstring = Win32API::GUID::CreateGuid();
    } else {
        throw Handel::Exception(
            -text => 'Required modules not found',
            -details => 'UUID/Data::UUID'
        );
    };

    $uuidstring =~ s/^{//;
    $uuidstring =~ s/}$//;

    return uc($uuidstring);
};

1;
__END__

=head1 NAME

Handel::DBI - Base DBI class used by cart/order objects

=head1 SYNOPSIS

    use Handel::DBI;

    my $newid = Handel::DBI::uuid;
    my $newid = Handel::DBI->uuid;
    my $newid = Handel::Cart->uuid;
    my $newid = Handel::Cart::Item->uuid;
    ..etc...

=head1 DESCRIPTION

This is the main base class for Handel objects that access the database. There
shouldn't be any reason to use this module directly for now.

=head1 FUNCTIONS

=head2 uuid

Returns a guid/uuid using the first available uuid generation module.
The support modules are C<UUID>, C<Data::UUID>, C<Win32::Guidgen>, and
C<Win32API::GUID>.

    use Handel::DBI;

    my $newid = Handel::DBI::uuid;
    my $uuid  = Handel::DBI->uuid;

Since C<Handel::Cart> and C<Handel::Cart::Item> are subclasses of
C<Handel::DBI>, C<uuid> is available within those modules as a method/function
as well:

    use Handel::Cart;

    my $newid = Handel::Cart->uuid;

=head2 has_wildcard

Inspects the supplied search filter to determine whether it contains wildcard
searching. Returns 1 if the filter contains SQL wildcards, otherwise it returns
C<undef>.

    has_wildcard({sku => '12%'});  # 1
    has_wildcard((sku => '123'));  # undef

This is used by C<Handel::Cart-E<gt>items> and
C<Handel::Cart::load> to determine which L<Class::DBI> methods to call (search
vs. search_like).

=head1 CONFIGURATION

Starting in version C<0.16>, the DBI configuration variables have been changed.
The old variables are now considered depricated and will be removed in the
future.

These can either be set in C<ENV>, or using PerlSetVar in C<httpd.conf>.
IF you are already using C<ENV> variables and want to use them within Apache
instead of duplicating that config using C<PerlSetVar>, you can tell mod_perl
to pass that configuration in by using C<PerlPassEnv>.

At some point, this needs to be reworked into a more generic config loader so
we can use C<ENV>, httpd.conf directives, or config files, LDAP, etc.

C<Handel::DBI> constructs its connection string using the following variables:

=head2 HandelDBIDriver

The name of the DBD driver. Defaults to C<mysql>.

=head2 HandelDBIHost

The name of the database server. Defaults to C<localhost>.

=head2 HandelDBIPort

The port of the database server. Defaults to C<3306>.

=head2 HandelDBIName

The name of the database. Defaults to C<commerce>.

=head2 HandelDBIUser

The user name used to connect to the server. Defaults to C<commerce>.

=head2 HandelDBIPassword

The password used to connect to the server. Defaults to C<commerce>.

=head1 SEE ALSO

L<UUID>, L<Data::UUID>, L<Win32::Guidgen>, L<Win32API::GUID>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
