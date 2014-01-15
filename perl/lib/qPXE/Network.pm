package qPXE::Network;

=head1 NAME

qPXE::Network - A network within the virtual test laboratory

=head1 SYNOPSIS

    use qPXE::Lab;

    my $lab = qPXE::Lab->new ( uri => "qemu:///system" );
    my $network = $lab->network ( "primary" );

=cut

use qPXE::Moose;
use XML::LibXML;
use strict;
use warnings;

=head1 ATTRIBUTES

=over

=item C<lab>

The C<qPXE::Lab> object representing the virtual test laboratory
containing the network.

=cut

has "lab" => (
  is => "ro",
  isa => "qPXE::Lab",
  required => 1,
);

=item C<network>

The C<Sys::Virt::Network> object representing the network.

=cut

has "network" => (
  is => "ro",
  isa => "Sys::Virt::Network",
  required => 1,
);

=item C<name>

The name of the network.

=cut

has "name" => (
  is => "ro",
  isa => "Str",
  lazy => 1,
  builder => "_build_name",
  init_arg => undef,
);

method _build_name () {
  return $self->network->get_name();
}

=item C<xml>

The C<XML::LibXML::Document> object representing the network's
configuration.

=cut

has "xml" => (
  is => "ro",
  isa => "XML::LibXML::Document",
  lazy => 1,
  builder => "_build_xml",
  init_arg => undef,
);

method _build_xml () {
  my $xmlstring = $self->network->get_xml_description();
  return XML::LibXML->load_xml ( string => $xmlstring );
}

=back

=cut

__PACKAGE__->meta->make_immutable();

1;
