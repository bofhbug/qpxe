package qPXE::Lab;

=head1 NAME

qPXE::Lab - The virtual test laboratory

=head1 SYNOPSIS

    use qPXE::Lab;

    my $lab = qPXE::Lab->new ( uri => "qemu:///system" );
    my $machine = $lab->machine ( "butters" );

=cut

use Moose;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;
use MooseX::MarkAsMethods autoclean => 1;
use Class::Load qw ( :all );
use Sys::Virt;
use qPXE::Machine;
use qPXE::Network;
use strict;
use warnings;

=head1 ATTRIBUTES

=over

=item C<uri>

URI of the virtual machine monitor, as used by C<< Sys::Virt->new() >>.

=cut

has uri => (
  is => "ro",
  isa => "Str",
  required => 1,
);

=item C<vmm>

The C<Sys::Virt> object representing the virtual machine monitor.

=cut

has vmm => (
  is => "ro",
  isa => "Sys::Virt",
  lazy => 1,
  builder => "_build_vmm",
  init_arg => undef,
);

method _build_vmm () {
  return Sys::Virt->new ( uri => $self->uri );
}

=item C<domainname>

The DNS domain name used for constructing hostnames via the
C<hostname()> method.

=cut

has domainname => (
  is => "ro",
  isa => "Maybe[Str]",
  required => 1,
  default => undef,
);

=back

=head1 METHODS

=over

=item C<< machine ( $name ) >>

Obtain a C<qPXE::Machine> object representing the machine named
C<$name>.

If the machine-specific subclass C<< qPXE::Machine::C<$name> >>
exists, the returned object will automatically be created with that
subclass.

=cut

method machine ( Str $name ) {

  # Look for an optional machine-specific class
  my $baseclass = "qPXE::Machine";
  my $subclass = $baseclass."::".$name;
  my $class = ( load_optional_class ( $subclass ) ?
		$subclass : $baseclass );

  # Construct machine
  return $class->new (
    lab => $self,
    domain => $self->vmm->get_domain_by_name ( $name ),
  );
}

=item C<< network ( $name ) >>

Obtain a C<qPXE::Network> object representing the network named
C<$name>.

=cut

method network ( Str $name ) {
  return qPXE::Network->new (
    lab => $self,
    network => $self->vmm->get_network_by_name ( $name ),
  );
}

=item C<< hostname ( $machine ) >>

Construct a hostname which can be used for direct access to the
specified machine (which can be a C<qPXE::Machine> object or a machine
name).

=cut

method hostname ( qPXE::Machine | Str $machine ) {

  # Allow calling with either a machine object or a machine name, and
  # ensure that the machine exists within the laboratory.
  $machine = $self->machine ( $machine ) unless blessed ( $machine );

  return ( $self->domainname ?
	   $machine->name.".".$self->domainname : $machine->name );
}

=back

=cut

__PACKAGE__->meta->make_immutable();

1;
