# $Id: Schema.pm 1157 2006-05-19 22:00:35Z claco $
package Handel::Schema;
use strict;
use warnings;
use Handel::ConfigReader;
use base qw/DBIx::Class::Schema/;

sub connect {
    my ($self, $dsn, $user, $pass, $opts) = @_;
    my $cfg = Handel::ConfigReader->instance;

    $dsn         ||= $cfg->{'HandelDBIDSN'}      || $cfg->{'db_dsn'};
    $user        ||= $cfg->{'HandelDBIUser'}     || $cfg->{'db_user'};
    $pass        ||= $cfg->{'HandelDBIPassword'} || $cfg->{'db_pass'};
    $opts        ||= {AutoCommit => 1};

    my $db_driver  = $cfg->{'HandelDBIDriver'}   || $cfg->{'db_driver'};
    my $db_host    = $cfg->{'HandelDBIHost'}     || $cfg->{'db_host'};
    my $db_port    = $cfg->{'HandelDBIPort'}     || $cfg->{'db_port'};
    my $db_name    = $cfg->{'HandelDBIName'}     || $cfg->{'db_name'};
    my $datasource = $dsn || "dbi:$db_driver:dbname=$db_name";

    if ($db_host && !$dsn) {
        $datasource .= ";host=$db_host";
    };

    if ($db_port && !$dsn) {
        $datasource .= ";port=$db_port";
    };

    $dsn ||= $datasource;

    return $self->next::method($dsn, $user, $pass, $opts);
};

1;
__END__

=head1 NAME

Handel::Schema - Base class for cart/order schemas

=head1 SYNOPSIS

    package MySchema;
    use strict;
    use warnings;
    use base qw/Handel::Schema/;

    __PACKAGE__->load_classes(qw//, {'MySchema' => [qw/TableClass OtherTableClass/]});

=head1 DESCRIPTION

Handel::Schema is the base class for the cart/order schemas. If you want to
create your own cart or order schema, simply subclass Handel::Schema and load
your classes.

=head1 METHODS

=head2 connect([$dsn,. $user, $password, \%opts])

Establishes a connection to the database and returns a new schema instance. If
no connection information is supplied, the connection information will be read
from C<ENV> or ModPerl using the configuration options available in
L<Handel::ConfigReader>.

=head1 SEE ALSO

L<DBIx::Class::Schema>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
