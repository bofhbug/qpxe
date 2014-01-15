package qPXE::Screenshot;

=head1 NAME

qPXE::Screenshot - A screenshot of a machine within the virtual test laboratory

=head1 SYNOPSIS

=cut

use qPXE::Moose;
use qPXE::Machine;
use qPXE::Error::Screenshot;
use File::Temp;
use Sys::Virt;
use Fcntl qw ( :seek );
use IPC::Run3;
use XML::LibXML;
use TryCatch;
use strict;
use warnings;

=head1 ATTRIBUTES

=over

=item C<machine>

The <qPXE::Machine> object representing the machine from which the
screenshot was taken.

=cut

has "machine" => (
  is => "ro",
  isa => "qPXE::Machine",
  required => 1,
);

=item C<screen>

The screen number from which the screenshot was taken.  Defaults to 0.

=cut

has "screen" => (
  is => "ro",
  isa => "Int",
  required => 1,
  default => 0,
);

=item C<stream>

The C<Sys::Virt::Stream> object used to receive the screenshot data.

=cut

has "stream" => (
  is => "ro",
  isa => "Sys::Virt::Stream",
  lazy => 1,
  builder => "_build_stream",
  init_arg => undef,
);

method _build_stream () {
  return $self->machine->lab->vmm->new_stream();
}

=item C<tempfile>

The C<File::Temp> object representing the temporary file created to
hold the screenshot data.

=cut

has "tempfile" => (
  is => "ro",
  isa => "File::Temp",
  lazy => 1,
  builder => "_build_tempfile",
  init_arg => undef,
);

method _build_tempfile () {

  # Create temporary file
  my $tempfile = File::Temp->new();

  # Read data from stream into file
  $self->stream->recv_all (
    sub {
      ( my $stream, my $data, my $count ) = @_;
      return $tempfile->syswrite ( $data, $count );
    } );
  $self->stream->finish();

  # Reset to start of file
  $tempfile->seek ( 0, SEEK_SET );

  return $tempfile;
}

=back

=head1 METHOD

=over

=item C<< barcode() >>

Extract any barcode(s) from the screenshot.  Returns the first barcode
in scalar context, or a list of all barcodes in list context.

=cut

method barcode () {

  # Run zbarimg to extract any barcodes.  There are more native Perl
  # ways to do this, but none that are generally packaged as RPMs.
  my $xmlstring;
  my $errmsg;
  run3 ( [ "zbarimg", "--quiet", "--xml", $self->tempfile->filename ],
	 \undef, \$xmlstring, \$errmsg );
  throw qPXE::Error::Screenshot::ZBarError ( errmsg => $errmsg )
      if $errmsg;

  # Check that we have some valid XML output
  my $xml = XML::LibXML->load_xml ( string => $xmlstring );
  my $xpc = XML::LibXML::XPathContext->new();
  $xpc->registerNs ( "z", "http://zbar.sourceforge.net/2008/barcode" );
  throw qPXE::Error::Screenshot::ZBarInvalidOutput ( output => $xmlstring )
      unless $xpc->exists ( "/z:barcodes/z:source", $xml );

  # Extract barcode values
  my @nodes = $xpc->findnodes ( "/z:barcodes/z:source/z:index/z:symbol/z:data",
				$xml );
  my @data = map { $_->to_literal } @nodes;
  return ( wantarray ? @data : $data[0] );
}

method BUILD ( HashRef $args ) {

  # Take screenshot
  my $mimetype = $self->machine->domain->screenshot ( $self->stream,
						      $self->screen );

  # libvirt-perl v1.0.0 and earlier have an error which causes
  # $mimetype to always be undef, and also fails to throw an exception
  # if the screenshot cannot be taken (because e.g. the domain is not
  # running).  Hack around this by attempting to read 0 bytes from the
  # stream (which will throw an exception if the stream is not
  # expecting the screenshot data), catching the stream exception, and
  # forcibly triggering the original "domain not running" exception by
  # attempting to read 0 bytes from the domain's memory space.
  #
  if ( ! defined $mimetype ) {
    try {
      # Check if stream is alive
      $self->stream->recv ( my $data, 0 );
    } catch {
      # Trigger originally-expected exception
      $self->machine->domain->memory_peek
	  ( 0, 0, Sys::Virt::Domain::MEMORY_PHYSICAL );
      # Should never reach this point
      throw qPXE::Error ( message => "Unexpected libvirt bug" );
    }
  }
}

method DEMOLISH ( Bool $in_global_destruction ) {

  # Abort stream, if applicable
  try {
    $self->stream->abort();
  } catch ( $err ) {
    # Ignore errors
  }
}

=back

=cut

__PACKAGE__->meta->make_immutable();

1;
