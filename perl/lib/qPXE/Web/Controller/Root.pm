package qPXE::Web::Controller::Root;

=head1 NAME

qPXE::Web::Controller::Root

=head1 DESCRIPTION

C<qPXE::Web::Controller::Root> is the C<Catalyst::Controller> class
representing the root namespace of the qPXE web application.

=cut

use qPXE::Moose;
use strict;
use warnings;

BEGIN { extends qw ( Catalyst::Controller ) };

# Control the root namespace
__PACKAGE__->config ( namespace => "" );

# Handle non-existent pages
sub default : Path {
  my $self = shift;
  my $c = shift;

  # Generate 404 "not found" response
  $c->response->status ( "404" );
  $c->response->content_type ( "text/plain" );
  $c->response->body ( "Page not found" );
}

__PACKAGE__->meta->make_immutable();

1;
