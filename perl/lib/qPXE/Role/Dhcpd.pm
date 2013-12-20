package qPXE::Role::Dhcpd;

=head1 NAME

qPXE::Role::Dhcpd - A machine implementing a DHCP server using ISC DHCPD

=head1 SYNOPSIS

=cut

use qPXE::Moose::Role;
use qPXE::Dhcpd;
use strict;
use warnings;

=head1 ATTRIBUTES

=over

=item C<dhcpd>

The C<qPXE::Dhcpd> object representing the DHCPD instance.

=cut

has "dhcpd" => (
  is => "ro",
  isa => "qPXE::Dhcpd",
  lazy => 1,
  builder => "_build_dhcpd",
  init_arg => undef,
);

method _build_dhcpd () {
  return qPXE::Dhcpd->new ( machine => $self );
}

=back

=cut

1;
