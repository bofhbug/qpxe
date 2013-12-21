package qPXE::Test;

=head1 NAME

qPXE::Test - A test case

=head1 SYNOPSIS


=cut

use qPXE::Moose;
use Data::UUID;
use strict;
use warnings;

=head1 ATTRIBUTES

=over

=item C<lab>

The C<qPXE::Lab> object representing the virtual test laboratory
in which the test is running.

=cut

has "lab" => (
  is => "ro",
  isa => "qPXE::Lab",
  required => 1,
  weak_ref => 1,
);

=item C<uuid_bin>

The test UUID, as a raw binary value.

=cut

has "_uuidobj" => (
  is => "ro",
  isa => "Data::UUID",
  lazy => 1,
  builder => "_build_uuidobj",
  init_arg => undef,
);

method _build_uuidobj {
  return Data::UUID->new();
}

has "uuid_bin" => (
  is => "ro",
  isa => "Str",
  lazy => 1,
  builder => "_build_uuid_bin",
  init_arg => undef,
);

method _build_uuid_bin () {
  return $self->_uuidobj->create();
}

=item C<uuid>

The test UUID, in the canonical text format
(e.g. "4364b87e-6784-11e3-ba6c-1a2d4ead6367").

=cut

has "uuid" => (
  is => "ro",
  isa => "Str",
  lazy => 1,
  builder => "_build_uuid",
  init_arg => undef,
);

method _build_uuid () {
  return lc $self->_uuidobj->to_string ( $self->uuid_bin );
}

=item C<uuid_colons>

The test UUID, as a colon-separated byte sequence suitable for
inclusion within C<dhcpd.conf>
(e.g. "43:64:b8:7e:67:84:11:e3:ba:6c:1a:2d:4e:ad:63:67").

=cut

has "uuid_colons" => (
  is => "ro",
  isa => "Str",
  lazy => 1,
  builder => "_build_uuid_colons",
  init_arg => undef,
);

method _build_uuid_colons () {

  # We can't just use unpack("C16",$self->uuid_bin) since Data::UUID
  # treats UUIDs as little-endian, while iPXE (in conformance with the
  # RFCs) treats them as network-endian.

  my $uuid_colons = lc $self->_uuidobj->to_hexstring ( $self->uuid_bin );
  $uuid_colons =~ s/^0x//;
  $uuid_colons =~ s/(..)(?=.)/$1:/g;
  return $uuid_colons;
}

=back

=cut

__PACKAGE__->meta->make_immutable();

1;
