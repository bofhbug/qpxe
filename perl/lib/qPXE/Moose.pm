package qPXE::Moose;

=head1 NAME

qPXE::Moose - Moose house style for qPXE

=head1 SYNOPSIS

    use qPXE::Moose;

=cut

use Moose ();
use MooseX::StrictConstructor ();
use MooseX::Method::Signatures;
use MooseX::MarkAsMethods autoclean => 1;
use Moose::Exporter;
use strict;
use warnings;

Moose::Exporter->setup_import_methods (
  also => [ "Moose", "MooseX::StrictConstructor" ],
);

sub init_meta {
  my $class = shift;
  my %params = @_;
  my $for_class = $params{for_class};

  Moose->init_meta ( @_ );
  MooseX::Method::Signatures->setup_for ( $for_class, {} );
  MooseX::MarkAsMethods->import ( { into => $for_class }, autoclean => 1 );
}

1;
