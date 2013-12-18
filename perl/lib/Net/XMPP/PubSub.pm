package Net::XMPP::PubSub;

use Net::XMPP;
use namespace::autoclean;
use strict;
use warnings;

use parent qw ( Exporter );
our @EXPORT_OK = qw ( XMPP_PUBSUB_NS XMPP_PUBSUB_OWNER_NS );

use constant XMPP_PUBSUB_NS => "http://jabber.org/protocol/pubsub";
use constant XMPP_PUBSUB_OWNER_NS => "http://jabber.org/protocol/pubsub#owner";

Net::XMPP::Protocol->AddNamespace (
  ns => XMPP_PUBSUB_NS,
  tag => "pubsub",
  xpath => {
    CreateNode => { type => "scalar", path => 'create/@node' },
    Configure => { type => "flag", path => 'configure' },
    SubscribeNode => { type => "scalar", path => 'subscribe/@node' },
    SubscribeJID => { type => "jid", path => 'subscribe/@jid' },
    UnsubscribeNode => { type => "scalar", path => 'unsubscribe/@node' },
    UnsubscribeJID => { type => "jid", path => 'unsubscribe/@jid' },
  } );

Net::XMPP::Protocol->AddNamespace (
  ns => XMPP_PUBSUB_OWNER_NS,
  tag => "pubsub",
  xpath => {
    DeleteNode => { type => "scalar", path => 'delete/@node' },
  } );

1;
