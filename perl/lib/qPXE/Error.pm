package qPXE::Error;

=head1 NAME

qPXE::Error - Base class for qPXE exceptions

=head1 SYNOPSIS

    use qPXE::Error;

    qPXE::Error->throw ( "Something bad happened" );

=cut

use qPXE::Moose;

extends "Throwable::Error";

# StackTrace::Auto prevents inlined constructors
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

1;
