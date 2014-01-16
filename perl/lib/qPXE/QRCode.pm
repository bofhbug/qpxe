package qPXE::QRCode;

=head1 NAME

qPXE::QRCode - a QR code to be displayed on a test machine

=head1 SYNOPSIS

    use qPXE::QRCode;

    my $qrcode = qPXE::QRCode->new ( "hello world" );
    print "PNG generated as ".$qrcode->png->filename;

=cut

use qPXE::Moose;
use qPXE::Error::QRCode;
use File::Temp;
use Fcntl qw ( :seek );
use IPC::Run3;
use strict;
use warnings;

=head1 ATTRIBUTES

=over

=item C<string>

The string embedded within the QR code.

=cut

has "string" => (
  is => "ro",
  isa => "Str",
  required => 1,
);

=item C<png>

The C<File::Temp> object containing the generated PNG image.

=cut

has "png" => (
  is => "ro",
  isa => "File::Temp",
  lazy => 1,
  builder => "_build_png",
  init_arg => undef,
);

method _build_png () {
  return $self->_build_tempfile ( "PNG", ".png" );
}

method _build_tempfile ( Str $type, Str $suffix ) {

  # Create temporary file
  my $tempfile = File::Temp->new ( SUFFIX => $suffix );

  # Run qrencode to generate code.  There are more native Perl ways to
  # do this, but none that are generally packaged as RPMs.
  my $errmsg;
  run3 ( [ "qrencode", "-o", "-", "-t", $type ], \$self->string,
	 $tempfile, \$errmsg );
  throw qPXE::Error::QRCode::QREncodeError ( status => $?, errmsg => $errmsg )
      if $? || $errmsg;

  # Reset to start of file
  $tempfile->seek ( 0, SEEK_SET );

  return $tempfile;
}

=back

=cut

around BUILDARGS => sub {
  my $orig = shift;
  my $class = shift;

  # Allow for single-argument constructor
  if ( ( @_ == 1 ) && ( ! ref $_[0] ) ) {
    return $class->$orig ( string => $_[0] );
  } else {
    return $class->$orig ( @_ );
  }
};

__PACKAGE__->meta->make_immutable();

1;
