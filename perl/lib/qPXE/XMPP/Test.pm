package qPXE::XMPP::Test;

=head1 NAME

qPXE::XMPP::Test -

=head1 SYNOPSIS


=cut

use qPXE::Moose;
use strict;
use warnings;

has "uuid" => (
  is => "ro",
  isa => "Str",
  required => 1,
);

has "xmpp" => (
  is => "ro",
  isa => "qPXE::XMPP",
  required => 1,
);

method subscribe () {
  $self->xmpp->subscribe ( $self->uuid );
}

method wait ( Str $id, Int $timeout ) {
  return $self->xmpp->wait ( $self->uuid, $id, $timeout );
}

method unsubscribe () {
  $self->xmpp->unsubscribe ( $self->uuid );
}

method BUILD ( HashRef $args ) {

  # Subscribe to test results
  $self->subscribe();
}

method DEMOLISH ( Bool $in_global_destruction ) {

  # Unsubscribe from test results
  $self->unsubscribe();
}

__PACKAGE__->meta->make_immutable();

1;
