package Handel::Components::Validation;
use strict;
use warnings;
use Scalar::Util qw/blessed/;
use base qw/DBIx::Class::Validation/;

sub validate {
    my $self = shift;
    my %data = $self->get_columns();
    my $module = $self->validation_module();
    my $profile = $self->validation_profile();
    my $result = $module->check(\%data => $profile);
    if (blessed $result && $result->success) {
        $self->set_columns(\%data);
        return $result;
    } else {
        $self->throw_exception($result);
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
        profile => { ... },
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

Validates the current row using the specified validation module.

=head1 SEE ALSO

L<DBIx::Class::Validation>, L<FormValidator::Simple>

=head1 AUTHOR

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
