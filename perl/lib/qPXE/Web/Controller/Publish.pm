package qPXE::Web::Controller::Publish;

=head1 NAME

qPXE::Web::Controller::Publish

=head1 DESCRIPTION

C<qPXE::Web::Controller::Publish> is the C<Catalyst::Controller> class
representing the "/publish" namespace of the qPXE web application.

=head1 ATTRIBUTES

=over

=cut

use qPXE::Moose;
use qPXE::Error::XMPP;
use Net::XMPP;
use Net::XMPP::PubSub qw ( XMPP_PUBSUB_NS );
use XML::LibXML;
use File::Basename;
use TryCatch;
use strict;
use warnings;

BEGIN { extends qw ( Catalyst::Controller ) };

# Enable debug traces
use constant DEBUG_TX_RX => 0;

=item C<xmpp>

The C<Net::XMPP::Client> object representing the XMPP client.  The
client is connected afresh for each HTTP request, to avoid the
complexity of managing a long-lived connection across multiple requests.

=cut

has "xmpp" => (
  is => "ro",
  isa => "Net::XMPP::Client",
  lazy => 1,
  builder => "_build_xmpp",
);

method _build_xmpp () {

  # Create XMPP client
  my $xmpp = Net::XMPP::Client->new();
  if ( DEBUG_TX_RX ) {
    $xmpp->SetCallBacks ( send => sub { shift; print "TX ".shift."\n" },
			  receive => sub { shift; print "RX ".shift."\n" } );
  }
  return $xmpp;
}

=item C<default_xml>

The C<XML::LibXML::Document> object representing the default XML
document sent as the event payload if no payload is submitted via
HTTP.

=cut

has "default_xml" => (
  is => "ro",
  isa => "XML::LibXML::Document",
  lazy => 1,
  builder => "_build_default_xml",
);

method _build_default_xml () {
  return XML::LibXML->load_xml ( string => "<empty/>" );
}

=back

=head1 PAGES

=over

=item C<< /publish/<nodeid>/<itemid> >>

Publish a test result to the XMPP server.

=cut

sub index : Path : Args(2) {
  my $self = shift;
  my $c = shift;
  my $nodeid = shift;
  my $itemid = shift;

  # Extract XML data from request body or POST-submitted file, if present
  my $xmlfh;
  if ( $c->request->content_type eq "text/xml" ) {
    $xmlfh = $c->request->body->fh;
  } elsif ( my $upload = $c->request->upload ( "xml" ) ) {
    $xmlfh = $upload->fh;
  }
  my $xml = ( defined $xmlfh ? XML::LibXML->load_xml ( IO => $xmlfh ) :
	      $self->default_xml );

  # Determine XMPP hostname
  my $hostname = ( $ENV{QPXE_XMPP} || "localhost" );

  # Connect to XMPP server
  $self->xmpp->Connect ( hostname => $hostname )
      or throw qPXE::Error::XMPP::CannotConnect();
  my @result = $self->xmpp->AuthSend ( username => basename ( $0 ),
				       password => "" );
  throw qPXE::Error::XMPP::Unauthorized ( detail => $result[1] )
      unless $result[0] eq "ok";
  
  # Publish result
  my $request = Net::XMPP::IQ->new();
  my $pubsub = $request->NewChild ( XMPP_PUBSUB_NS );
  $request->SetType ( "set" );
  $request->SetTo ( "pubsub.".$hostname );
  my $publish = $pubsub->AddPublish();
  my $item = $publish->AddItem();
  $item->SetRaw ( $xml->documentElement->serialize() );
  $publish->SetNode ( $nodeid );
  $item->SetID ( $itemid );
  my $response = $self->xmpp->SendAndReceiveWithID ( $request )
      or throw qPXE::Error::XMPP::IQMissing ( request => $request );
  throw qPXE::Error::XMPP::IQ ( response => $response )
      if $response->GetType() eq "error";  

  # Disconnect from XMPP server
  $self->xmpp->Disconnect();
}

=back

=cut

__PACKAGE__->meta->make_immutable();

1;
