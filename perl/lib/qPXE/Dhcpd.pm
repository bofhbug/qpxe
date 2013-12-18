package qPXE::Dhcpd;

=head1 NAME

qPXE::Dhcpd - An instance of ISC DHCPD

=head1 SYNOPSIS

    use qPXE::Lab;

    my $lab = qPXE::Lab->new ( uri => "qemu:///system" );
    my $machine = $lab->machine ( "cartman" );
    my $dhcpd = $cartman->dhcpd;

    $dhcpd->reserve ( "butters", [
      "hardware ethernet 52:54:00:12:34:56;",
      "filename \"pxelinux.0\";",
    ] );

=cut

use Moose;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;
use MooseX::MarkAsMethods autoclean => 1;
use File::Temp;
use Carp;
use strict;
use warnings;

=head1 ATTRIBUTES

=over

=item C<machine>

The <qPXE::Machine> object representing the machine running DHCPD.

=cut

has "machine" => (
  is => "ro",
  isa => "qPXE::Machine",
  required => 1,
  weak_ref => 1,
);

=back

=head1 METHODS

=over

=item C<< reserve ( $host, $config ) >>

Create a reservation for the specified C<$host>, containing the raw
configuration data C<$config> (which can be a single string or an
array of strings).

=cut

method _reservation_filename ( Str $host ) {
  return "/etc/dhcpd.d/".$host.".conf";
}

method reserve ( Str $host, Str | ArrayRef[Str] $config ) {

  # Construct reservation fragment
  my $reservation = "host ".$host. " {";
  if ( ref $config ) {
    $reservation .= join ( "", map { "\n\t".$_ } @$config );
  } else {
    $reservation .= "\n\t".$config;
  }
  $reservation .= "\n};\n";

  # Generate temporary file containing the reservation
  my $tempfile = File::Temp->new();
  $tempfile->print ( $reservation );
  $tempfile->flush();

  # Copy reservation fragment to server
  $self->machine->upload ( $tempfile, $self->_reservation_filename ( $host ) );

  # Reload DHCPD configuration
  $self->reload();
}

=item C<< release ( $host ) >>

Delete the reservation (if any) for the specified C<$host>.

=cut

method release ( Str $host ) {

  # Remove reservation fragment
  $self->machine->upload ( undef, $self->_reservation_filename ( $host ) );

  # Reload DHCPD configuration
  $self->reload();
}

=item C<< reload() >>

Reload the DHCPD configuration.

=cut

method reload () {

  # Use qpxe-dhcpd script to regenerate /etc/dhcpd.d.conf and restart DHCPD
  ( my $out, my $err, my $rc ) =
      $self->machine->ssh->cmd ( "/usr/sbin/qpxe-dhcpd" );
  die "Could not reload DHCPD configuration: $rc\n" if $rc;
}

=back

=cut

__PACKAGE__->meta->make_immutable();

1;
