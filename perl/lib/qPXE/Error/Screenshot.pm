package qPXE::Error::Screenshot;

=head1 NAME

qPXE::Error::Screenshot - qPXE screenshot exceptions

=head1 SYNOPSIS

    use qPXE::Error::Screenshot;

    qPXE::Error::Screenshot::

=head1 SUBCLASSES

=cut

use qPXE::Moose;
extends "qPXE::Error";
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

=head2 C<qPXE::Error::Screenshot::ZBarError>

C<zbarimg> produced output on C<stderr>.

=head3 ATTRIBUTES

=over 

=item C<errmsg>

Output produced by C<zbarimg> on C<stderr>.

=back

=cut

package qPXE::Error::Screenshot::ZBarError;
use qPXE::Moose;
extends "qPXE::Error::Screenshot";
has "+message" => (
  lazy => 1,
  builder => "_build_message"
);
has "errmsg" => (
  is => "ro",
  isa => "Str",
  required => 1,
);
method _build_message () {
  return "zbarimg failed: ".$self->errmsg;
}
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

=head2 C<qPXE::Error::Screenshot::ZBarInvalidOutput>

C<zbarimg> produced invalid XML output.

=head3 ATTRIBUTES

=over 

=item C<output>

Output produced by C<zbarimg>.

=back

=cut

package qPXE::Error::Screenshot::ZBarInvalidOutput;
use qPXE::Moose;
extends "qPXE::Error::Screenshot";
has "+message" => (
  lazy => 1,
  builder => "_build_message"
);
has "output" => (
  is => "ro",
  isa => "Str",
  required => 1,
);
method _build_message () {
  return "zbarimg produced invalid XML:\n".$self->output;
}
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

1;
