package qPXE::Test;

=head1 NAME

qPXE::Test - A test case

=head1 SYNOPSIS


=cut

use Moose;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;
use MooseX::MarkAsMethods autoclean => 1;
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

has _uuidobj => (
  is => "ro",
  isa => "Data::UUID",
  lazy => 1,
  builder => "_build_uuidobj",
  init_arg => undef,
);

method _build_uuidobj {
  return Data::UUID->new();
}

has uuid_bin => (
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

has uuid => (
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
(e.g. "7e:b8:64:43:84:67:e3:11:ba:6c:1a:2d:4e:ad:63:76")

=cut

has uuid_colons => (
  is => "ro",
  isa => "Str",
  lazy => 1,
  builder => "_build_uuid_colons",
  init_arg => undef,
);

method _build_uuid_colons () {
  return join ( ":", ( map { sprintf "%02x", $_ }
		       unpack ( "C16", $self->uuid_bin ) ) );
}

=back

=cut

__PACKAGE__->meta->make_immutable();

1;
