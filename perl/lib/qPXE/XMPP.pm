package qPXE::XMPP;

=head1 NAME

qPXE::XMPP - An instance of an XMPP server

=head1 SYNOPSIS

    use qPXE::Lab;

    my $lab = qPXE::Lab->new ( uri => "qemu:///system" );
    my $machine = $lab->machine ( "cartman" );
    my $xmpp = $cartman->xmpp;


=cut

use qPXE::Moose;
use qPXE::Error::XMPP;
use Net::XMPP;
use Net::XMPP::PubSub qw ( :ns );
use XML::LibXML;
use Data::UUID;
use File::Basename;
use strict;
use warnings;

# Enable debug traces
use constant DEBUG_TX_RX => 0;

=head1 ATTRIBUTES

=over

=item C<machine>

The <qPXE::Machine> object representing the machine running the XMPP
server.

=cut

has "machine" => (
  is => "ro",
  isa => "qPXE::Machine",
  required => 1,
  weak_ref => 1,
);

=item C<jid>

The C<Net::XMPP::JID> object representing the Jabber ID used by the
C<client>.

=cut

has "jid" => (
  is => "ro",
  isa => "Net::XMPP::JID",
  lazy => 1,
  builder => "_build_jid",
  init_arg => undef,
);

method _build_jid () {
  my $jid = Net::XMPP::JID->new();
  $jid->SetJID ( userid => basename ( $0 ), server => $self->machine->hostname,
		 resource => lc Data::UUID->new()->create_str() );
  return $jid;
}

=item C<pubsub_jid>

The C<Net::XMPP::JID> object representing the Jabber ID of the pubsub
node.

=cut

has "pubsub_jid" => (
  is => "ro",
  isa => "Net::XMPP::JID",
  lazy => 1,
  builder => "_build_pubsub_jid",
  init_arg => undef,
);

method _build_pubsub_jid () {
  my $jid = Net::XMPP::JID->new();
  $jid->SetJID ( server => "pubsub.".$self->machine->hostname );
  return $jid;
}

=item C<client>

The C<Net::XMPP::Client> object representing the connection to the
XMPP server.

=cut

has "client" => (
  is => "ro",
  isa => "Net::XMPP::Client",
  lazy => 1,
  builder => "_build_client",
  init_arg => undef,
);

method _build_client () {

  # Create XMPP client
  my $client = Net::XMPP::Client->new();
  if ( DEBUG_TX_RX ) {
    $client->SetCallBacks ( send => sub { shift; print "TX ".shift."\n" },
			    receive => sub { shift; print "RX ".shift."\n" } );
  }

  # Connect to server
  $client->Connect ( hostname => $self->machine->hostname )
      or throw qPXE::Error::XMPP::CannotConnect();

  # Authenticate
  my @result = $client->AuthSend ( username => $self->jid->GetUserID(),
				   resource => $self->jid->GetResource(),
				   password => "" );
  throw qPXE::Error::XMPP::Unauthorized ( detail => $result[1] )
      unless $result[0] eq "ok";

  return $client;
}

=back

=head1 METHODS

=over

=item C<< subscribe ( $node ) >>

Create and subscribe to the specified C<$node>.

=cut

method subscribe ( Str $node ) {

  # Create test UUID node
  my $request = Net::XMPP::IQ->new();
  my $pubsub = $request->NewChild ( XMPP_PUBSUB_NS );
  $request->SetType ( "set" );
  $request->SetTo ( $self->pubsub_jid );
  $pubsub->SetCreateNode ( $node );
  my $configure = $pubsub->AddConfigure();
  my $x = $configure->AddX();
  $x->SetType ( "submit" );
  my $field = $x->AddField();
  $field->SetVar ( "pubsub#publish_model" );
  $field->SetValue ( "open" );
  my $response = $self->client->SendAndReceiveWithID ( $request )
      or throw qPXE::Error::XMPP::IQMissing ( request => $request );
  throw qPXE::Error::XMPP::IQ ( response => $response )
      if $response->GetType() eq "error";  

  # Subscribe to test UUID node
  $request = Net::XMPP::IQ->new();
  $pubsub = $request->NewChild ( XMPP_PUBSUB_NS );
  $request->SetType ( "set" );
  $request->SetTo ( $self->pubsub_jid );
  $pubsub->SetSubscribeNode ( $node );
  $pubsub->SetSubscribeJID ( $self->jid );
  $response = $self->client->SendAndReceiveWithID ( $request )
      or throw qPXE::Error::XMPP::IQMissing ( request => $request );
  throw qPXE::Error::XMPP::IQ ( response => $response )
      if $response->GetType() eq "error";  
}

=item C<< wait ( $node, $id, $timeout ) >>

Wait up to C<$timeout> seconds for an event notification from the
specified C<$node> with the specified C<$id>, returning the payload
(or throwing an exception if a suitable event notification is not
received).

=cut

method wait ( Str $node, Str $id, Int $timeout ) {

  # Wait for a message to be received
  my $message;
  $self->client->SetCallBacks ( message => sub { shift; $message = shift } );
  defined ( $self->client->Process ( $timeout ) )
      or throw qPXE::Error::XMPP::Disconnected();
  $self->client->SetCallBacks ( message => undef );
  throw qPXE::Error::XMPP::Timeout() unless $message;

  # Extract event
  my $event = $message->GetChild ( XMPP_PUBSUB_EVENT_NS )
      or throw qPXE::Error::XMPP::Unexpected();

  # Extract items and verify node
  my $items = $event->GetItems()
      or throw qPXE::Error::XMPP::Unexpected();
  throw qPXE::Error::XMPP::Unexpected() unless $items->DefinedNode();
  throw qPXE::Error::XMPP::Unexpected ( node => $items->GetNode() )
      unless $items->GetNode() eq $node;

  # Extract item and verify ID
  my $item = $items->GetItem()
      or throw qPXE::Error::XMPP::Unexpected ( node => $node );
  my $raw = $item->GetRaw()
      or throw qPXE::Error::XMPP::Unexpected ( node => $node );
  my $payload = XML::LibXML->load_xml ( string => $raw );
  throw qPXE::Error::XMPP::Unexpected ( node => $node, payload => $payload )
      unless $item->DefinedID();
  throw qPXE::Error::XMPP::Unexpected ( node => $node,
					id => $item->GetID(),
					payload => $payload )
      unless $item->GetID() eq $id;

  return $payload;
}


=item C<< unsubscribe ( $node ) >>

Unsubscribe from and delete the specified C<$node>.

=cut

method unsubscribe ( Str $node ) {

  # Unsubscribe from test UUID node
  my $request = Net::XMPP::IQ->new();
  my $pubsub = $request->NewChild ( XMPP_PUBSUB_NS );
  $request->SetType ( "set" );
  $request->SetTo ( $self->pubsub_jid );
  $pubsub->SetUnsubscribeNode ( $node );
  $pubsub->SetUnsubscribeJID ( $self->jid );
  my $response = $self->client->SendAndReceiveWithID ( $request )
      or throw qPXE::Error::XMPP::IQMissing ( request => $request );
  throw qPXE::Error::XMPP::IQ ( response => $response )
      if $response->GetType() eq "error";  

  # Delete test UUID node
  $request = Net::XMPP::IQ->new();
  $pubsub = $request->NewChild ( XMPP_PUBSUB_OWNER_NS );
  $request->SetType ( "set" );
  $request->SetTo ( $self->pubsub_jid );
  $pubsub->SetDeleteNode ( $node );
  $response = $self->client->SendAndReceiveWithID ( $request )
      or throw qPXE::Error::XMPP::IQMissing ( request => $request );
  throw qPXE::Error::XMPP::IQ ( response => $response )
      if $response->GetType() eq "error";  
}

=back

=cut

__PACKAGE__->meta->make_immutable();

1;
