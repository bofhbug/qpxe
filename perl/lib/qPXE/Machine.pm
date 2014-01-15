package qPXE::Machine;

=head1 NAME

qPXE::Machine - A machine within the virtual test laboratory

=head1 SYNOPSIS

    use qPXE::Lab;

    my $lab = qPXE::Lab->new ( uri => "qemu:///system" );
    my $machine = $lab->machine ( "butters" );

    # Power on machine
    $machine->domain->create();

=cut

use qPXE::Moose;
use qPXE::Network;
use XML::LibXML;
use strict;
use warnings;

=head1 ATTRIBUTES

=over

=item C<lab>

The C<qPXE::Lab> object representing the virtual test laboratory
containing the machine.

=cut

has "lab" => (
  is => "ro",
  isa => "qPXE::Lab",
  required => 1,
);

=item C<domain>

The C<Sys::Virt::Domain> object representing the machine.

=cut

has "domain" => (
  is => "ro",
  isa => "Sys::Virt::Domain",
  required => 1,
);

=item C<name>

The name of the machine.

=cut

has "name" => (
  is => "ro",
  isa => "Str",
  lazy => 1,
  builder => "_build_name",
  init_arg => undef,
);

method _build_name () {
  return $self->domain->get_name();
}

=item C<hostname>

The hostname to be used for network access to the machine.

=cut

has "hostname" => (
  is => "ro",
  isa => "Str",
  lazy => 1,
  builder => "_build_hostname",
  init_arg => undef,
);

method _build_hostname () {
  return $self->lab->hostname ( $self );
}

=item C<xml>

The C<XML::LibXML::Document> object representing the machine's
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
  my $xmlstring = $self->domain->get_xml_description();
  return XML::LibXML->load_xml ( string => $xmlstring );
}

=back

=head1 METHODS

=over

=item C<< mac ( $network ) >>

Retrieve the MAC address of the interface connected to the specified
network (which can be a C<qPXE::Network> object or a network name), or
C<undef> if no interface is connected to the specified network.

=cut

method mac ( qPXE::Network | Str $network ) {

  # Allow calling with either a network object or a network name, and
  # ensure that the network exists within the laboratory.
  $network = $self->lab->network ( $network ) unless blessed ( $network );

  # Find MAC address from matching interface definition, if any
  return $self->xml->findvalue ( '/domain/devices/interface'.
				 '[source/@network=\''.$network->name.'\']'.
				 '/mac/@address' );
}

=back

=cut

__PACKAGE__->meta->make_immutable();

1;
