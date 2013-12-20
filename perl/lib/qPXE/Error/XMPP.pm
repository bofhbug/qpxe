package qPXE::Error::XMPP;

=head1 NAME

qPXE::Error::XMPP - qPXE XMPP exceptions

=head1 SYNOPSIS

    use qPXE::Error::XMPP;

    qPXE::Error::XMPP::Timeout->throw();

=head1 SUBCLASSES

=cut

use qPXE::Moose;
extends "qPXE::Error";
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

=head2 C<qPXE::Error::XMPP::CannotConnect>

Cannot connect to XMPP server.

=head3 ATTRIBUTES

=over 

=item C<detail>

Detailed reason for connection failure.

=back

=cut

package qPXE::Error::XMPP::CannotConnect;
use qPXE::Moose;
extends "qPXE::Error::XMPP";
has "+message" => (
  lazy => 1,
  builder => "_build_message"
);
has "detail" => (
  is => "ro",
  isa => "Str",
  required => 1,
  default => sub { $! },
);
method _build_message () {
  return "Cannot connect to XMPP server: ".$self->detail;
}
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

=head2 C<qPXE::Error::XMPP::Unauthorized>

XMPP authorization failed.

=head3 ATTRIBUTES

=over 

=item C<detail>

Detailed reason for authorization failure.

=back

=cut

package qPXE::Error::XMPP::Unauthorized;
use qPXE::Moose;
extends "qPXE::Error::XMPP";
has "+message" => (
  lazy => 1,
  builder => "_build_message"
);
has "detail" => (
  is => "ro",
  isa => "Str",
  required => 1,
);
method _build_message () {
  return "XMPP authorization failed: ".$self->detail;
}
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

=head2 C<qPXE::Error::XMPP::Disconnected>

Disconnected from XMPP server.

=cut

package qPXE::Error::XMPP::Disconnected;
use qPXE::Moose;
extends "qPXE::Error::XMPP";
has "+message" => ( default => "Disconnected from XMPP server" );
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

=head2 C<qPXE::Error::XMPP::Timeout>

Timed out while waiting for XMPP server.

=cut

package qPXE::Error::XMPP::Timeout;
use qPXE::Moose;
extends "qPXE::Error::XMPP";
has "+message" => ( default => "Timed out waiting for XMPP message" );
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

=head2 C<qPXE::Error::XMPP::IQMissing>

No response to XMPP InfoQuery.

=head3 ATTRIBUTES

=over

=item C<request>

The C<Net::XMPP::IQ> object representing the IQ request.

=back

=cut

package qPXE::Error::XMPP::IQMissing;
use qPXE::Moose;
extends "qPXE::Error::XMPP";
has "+message" => (
  lazy => 1,
  builder => "_build_message"
);
has "request" => (
  is => "ro",
  isa => "Net::XMPP::IQ",
  required => 1,
);
method _build_message () {
  return "No response to XMPP InfoQuery:\n".$self->request->GetXML();
}
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

=head2 C<qPXE::Error::XMPP::IQ>

XMPP InfoQuery failed.

=head3 ATTRIBUTES

=over

=item C<response>

The C<Net::XMPP::IQ> object representing the IQ response.

=back

=cut

package qPXE::Error::XMPP::IQ;
use qPXE::Moose;
extends "qPXE::Error::XMPP";
has "+message" => (
  lazy => 1,
  builder => "_build_message"
);
has "response" => (
  is => "ro",
  isa => "Net::XMPP::IQ",
  required => 1,
);
method _build_message () {
  return ( "XMPP InfoQuery failed: ".$self->response->GetErrorCode()."\n".
	   $self->response->GetXML() );
}
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

=head2 C<qPXE::Error::XMPP::Unexpected>

Unexpected XMPP event message.

=head3 ATTRIBUTES

=over

=item C<node> (optional)

Node ID.

=item C<id> (optional)

Item ID.

=item C<payload> (optional)

Item payload, as an C<XML::LibXML::Document> object.

=back

=cut

package qPXE::Error::XMPP::Unexpected;
use qPXE::Moose;
extends "qPXE::Error::XMPP";
has "+message" => (
  lazy => 1,
  builder => "_build_message"
);
has "node" => (
  is => "ro",
  isa => "Str",
  predicate => "has_node",
);
has "id" => (
  is => "ro",
  isa => "Str",
  predicate => "has_id",
);
has "payload" => (
  is => "ro",
  isa => "XML::LibXML::Document",
  predicate => "has_payload",
);
method _build_message () {
  my $message = "Unexpected XMPP message";
  $message .= " for node \"".$self->node."\"" if $self->has_node;
  $message .= " with ID \"".$self->id."\"" if $self->has_id;
  $message .= ":\n".$self->payload->serialize() if $self->has_payload;
  return $message;
}
__PACKAGE__->meta->make_immutable ( inline_constructor => 0 );

1;
