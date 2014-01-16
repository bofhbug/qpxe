package qPXE::Error::QRCode;

=head1 NAME

qPXE::Error::QRCode - qPXE screenshot exceptions

=head1 SYNOPSIS

    use qPXE::Error::QRCode;

=head1 SUBCLASSES

=cut

use qPXE::Moose;
extends "qPXE::Error";
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

=head2 C<qPXE::Error::QRCode::QREncodeError>

C<qrencode> exited with a failure, or produced output on C<stderr>.

=head3 ATTRIBUTES

=over 

=item C<status>

Exit status from C<qrencode>.

=item C<errmsg>

Output produced by C<qrencode> on C<stderr>.

=back

=cut

package qPXE::Error::QRCode::QREncodeError;
use qPXE::Moose;
extends "qPXE::Error::QRCode";
has "+message" => (
  lazy => 1,
  builder => "_build_message"
);
has "status" => (
  is => "ro",
  isa => "Int",
  required => 1,
);
has "errmsg" => (
  is => "ro",
  isa => "Maybe[Str]",
  required => 1,
);
method _build_message () {
  return ( "qrencode failed (exit ".$self->status."): ".
	   ( $self->errmsg || "(no output)" ) );
}
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

1;
