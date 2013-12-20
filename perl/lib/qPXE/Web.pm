package qPXE::Web;

=head1 NAME

qPXE::Web

=head1 DESCRIPTION

C<qPXE::Web> is the C<Catalyst> class representing the qPXE web
application.

=cut

use qPXE::Moose;
use Catalyst qw ( Static::Simple );
use strict;
use warnings;

extends qw ( Catalyst );

# Avoid complaints from MooseX::StrictConstructor
has "name" => ( is => "ro" );
has "home" => ( is => "ro" );
has "root" => ( is => "ro" );
has "static" => ( is => "ro" );

__PACKAGE__->config (

  # Application name
  name => "qPXE",

  # Web root
  root => $ENV{CATALYST_HOME},

  # Directories containing static content
  static => { dirs => [ qw ( static ) ] },
);

__PACKAGE__->setup();

__PACKAGE__->meta->make_immutable();

1;
