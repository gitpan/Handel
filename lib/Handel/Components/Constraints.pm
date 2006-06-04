package Handel::Components::Constraints;
use strict;
use warnings;
use Handel::Exception;
use Handel::L10N qw/translate/;
use base qw/DBIx::Class Class::Data::Accessor/;

__PACKAGE__->mk_classaccessor('constraints');

sub check_constraints {
    my $self = shift;
    my $constraints = $self->constraints;

    return 1 if !scalar keys(%{$constraints});

    my %data = $self->get_columns();
    my $source = $self->result_source;
    my @failed;

    foreach my $field (keys %{$constraints}) {
        my $value = $data{$field};
        my @subs = @{$constraints->{$field} || []};

        foreach my $sub (@subs) {
            if (!$sub->($value, $source, $field, \%data)) {
                push @failed, $field;
            };
        };
    };

    if (scalar @failed) {
        $self->throw_exception(
            Handel::Exception::Constraint->new(-details => join(', ', @failed))
        );
    } else {
        $self->set_columns(\%data);
        return 1;
    };
};

sub insert {
    my $self = shift;
    $self->check_constraints;
    $self->next::method(@_);
};

sub update {
    my $self = shift;
    $self->check_constraints;
    $self->next::method(@_);
};

1;
__END__

=head1 NAME

Handel::Components::Constraints - Column constraints for schemas

=head1 SYNOPSIS

    package MySchema::Table;
    use strict;
    use warnings;
    use base /DBIx::Class/;

    __PACKAGE__->load_components('+Handel::Component::Constraints');
    __PACKAGE__->add_constraint('myconstraint', 'foocolumn' => \&mysub);

    1;

=head1 DESCRIPTION

Handel::Components::Constraints is a simple way to validate column data during
inserts/updates using subroutines. It mostly acts as a compatibility layer
for C<add_constraint> used in Class::DBI.

There is no real reason to load this component into your schema table classes
directly. If you add constraints using Handel::Storage->add_constraint, this
component will be loaded into the appropriate schema source class automatically.

=head1 METHODS

=head2 add_constraint($name, $column, \&sub)

Adds a constraint for the specified column.

Note: Always use the real column name in the database, not the accessor alias
for the column.

=head2 check_constraints

This loops through all of the configured constraints, calling the specified
\&sub. Each sub will receive the following arguments:

    sub mysub {
        my ($value, $source, $column, \%data) = @_;

        if ($value) {
            return 1;
        } else {
            return 0;
        };
    };

=over

=item value

The value of the column to be checked.

=item source

The source storage object for the row being updated/inserted.

=item column

The name of the column being checked.

=item data

A hash reference containing all of the columns and their values. Changing and
values in the hash will also change the value interested/updated in the
database.

=back

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
