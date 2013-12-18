package qPXE::XMPP;

=head1 NAME

qPXE::XMPP - An instance of an XMPP server

=head1 SYNOPSIS

    use qPXE::Lab;

    my $lab = qPXE::Lab->new ( uri => "qemu:///system" );
    my $machine = $lab->machine ( "cartman" );
    my $xmpp = $cartman->xmpp;


=cut

use Moose;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;
use MooseX::MarkAsMethods autoclean => 1;
use Net::XMPP;
use Net::XMPP::PubSub qw ( XMPP_PUBSUB_NS XMPP_PUBSUB_OWNER_NS );
use Data::UUID;
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
  $jid->SetJID ( userid => "anonymous", server => $self->machine->hostname,
		 resource => lc Data::UUID->new()->create_str() );
  return $jid;
}

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

  $client->SetCallBacks ( send => sub { print "TX ".join ( ",", @_ )."\n" },
			  receive => sub { print "RX ".join ( ",", @_ )."\n" });

  # Connect to server
  $client->Connect ( hostname => $self->machine->hostname )
      or croak "Could not connect to ".$self->machine->hostname.": $!";

  # Authenticate
  my @result = $client->AuthSend ( username => $self->jid->GetUserID(),
				   resource => $self->jid->GetResource(),
				   password => "" );
  croak "XMPP authorization failed: ".$result[0]." - ".$result[1]
      unless $result[0] eq "ok";

  return $client;
}

=back

=head1 METHODS

=over

=item C<< subscribe ( $test ) >>

Subscribe to the results for the specified test, which must be a
C<qPXE::Test> object.

=cut

method subscribe ( qPXE::Test $test ) {

  # Create test UUID node
  my $iq = Net::XMPP::IQ->new();
  my $pubsub = $iq->NewChild ( XMPP_PUBSUB_NS );
  $iq->SetType ( "set" );
  $iq->SetTo ( $self->pubsub_jid );
  $pubsub->SetCreateNode ( $test->uuid );
  $pubsub->SetConfigure();
  $iq = $self->client->SendAndReceiveWithID ( $iq )
      or croak "No reply to XMPP node creation";
  croak "Could not create XMPP node: ".$iq->GetErrorCode()
      if $iq->GetType() eq "error";  

  # Subscribe to test UUID node
  $iq = Net::XMPP::IQ->new();
  $pubsub = $iq->NewChild ( XMPP_PUBSUB_NS );
  $iq->SetType ( "set" );
  $iq->SetTo ( $self->pubsub_jid );
  $pubsub->SetSubscribeNode ( $test->uuid );
  $pubsub->SetSubscribeJID ( $self->jid );
  $iq = $self->client->SendAndReceiveWithID ( $iq )
      or croak "No reply to XMPP node subscription";
  croak "Could not subscribe to XMPP node: ".$iq->GetErrorCode()
      if $iq->GetType() eq "error";
}

=item C<< subscribe ( $test ) >>

Unsubscribe from the results for the specified test, which must be a
C<qPXE::Test> object.

=cut

method unsubscribe ( qPXE::Test $test ) {

  # Unsubscribe from test UUID node
  my $iq = Net::XMPP::IQ->new();
  my $pubsub = $iq->NewChild ( XMPP_PUBSUB_NS );
  $iq->SetType ( "set" );
  $iq->SetTo ( $self->pubsub_jid );
  $pubsub->SetUnsubscribeNode ( $test->uuid );
  $pubsub->SetUnsubscribeJID ( $self->jid );
  $iq = $self->client->SendAndReceiveWithID ( $iq )
      or croak "No reply to XMPP node unsubscription";
  croak "Could not unsubscribe from XMPP node: ".$iq->GetErrorCode()
      if $iq->GetType() eq "error";

  # Delete test UUID node
  $iq = Net::XMPP::IQ->new();
  $pubsub = $iq->NewChild ( XMPP_PUBSUB_OWNER_NS );
  $iq->SetType ( "set" );
  $iq->SetTo ( $self->pubsub_jid );
  $pubsub->SetDeleteNode ( $test->uuid );
  $iq = $self->client->SendAndReceiveWithID ( $iq )
      or croak "No reply to XMPP node deletion";
  croak "Could not delete XMPP node: ".$iq->GetErrorCode()
      if $iq->GetType() eq "error";  
}

=back

=cut

__PACKAGE__->meta->make_immutable();

1;
