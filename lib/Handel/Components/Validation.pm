package Handel::Components::Validation;
use strict;
use warnings;
use Scalar::Util qw/blessed/;
use base qw/DBIx::Class::Validation/;

sub validate {
    my $self = shift;
    # evil hackery because of not having load_components C3 recalcs
    # to get to a local throw_exception
    my $result;

    eval {
        $result = $self->next::method(@_);
    };
    if ($@) {
        if (blessed $@) {
            $self->throw_exception(
                Handel::Exception::Validation->new(-results => $@)
            );
        } else {
            $self->throw_exception(
                Handel::Exception::Validation->new(-details => $@)
            );
        };

    } else {
        return $result;
    };
};

1;
__END__

=head1 NAME

Handel::Components::Validation - Column validation for schemas

=head1 SYNOPSIS

    package MySchema::Table;
    use strict;
    use warnings;
    use base /DBIx::Class/;

    __PACKAGE__->load_components('+Handel::Component::Validation');
    __PACKAGE__->validation(
        module => 'FormValidator::Simple',
        profile => [ ... ],
        auto => 1,
    );

    1;

=head1 DESCRIPTION

Handel::Components::Validation is a customized version of
L<DBIx::Class::Validation> for use in cart/order schemas.

There is no real reason to load this component into your schema table classes
directly. If you set a profile using Handel::Storage->validation_profile, this
component will be loaded into the appropriate schema source class automatically.

=head1 METHODS

=head2 validate

Validates the current row using the specified validation module. If validation
fails, a L<Handel::Exception::Validation|Handel::Exception::Validation> will be
thrown containing the the result object returned from the validation module.

=head1 SEE ALSO

L<DBIx::Class::Validation>, L<FormValidator::Simple>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
