package Net::XMPP::PubSub;

use Net::XMPP;
use namespace::autoclean;
use strict;
use warnings;

use parent qw ( Exporter );
our %EXPORT_TAGS = (
  ns => [ qw ( XMPP_PUBSUB_NS XMPP_PUBSUB_OWNER_NS XMPP_PUBSUB_EVENT_NS ) ],
);
our @EXPORT_OK = map { @$_ } values %EXPORT_TAGS;

use constant XMPP_PUBSUB_NS => "http://jabber.org/protocol/pubsub";
use constant XMPP_PUBSUB_OWNER_NS => "http://jabber.org/protocol/pubsub#owner";
use constant XMPP_PUBSUB_EVENT_NS => "http://jabber.org/protocol/pubsub#event";

Net::XMPP::Protocol->AddNamespace (
  ns => "__netxmpp__:iq:pubsub:publish:item",
  tag => "item",
  xpath => {
    ID => { type => "scalar", path => '@id' },    
    Raw => { type => "raw" },
  } );

Net::XMPP::Protocol->AddNamespace (
  ns => "__netxmpp__:iq:pubsub:publish",
  tag => "publish",
  xpath => {
    Node => { type => "scalar", path => '@node' },
    Item => { type => "child", path => 'item',
	      child => { ns => "__netxmpp__:iq:pubsub:publish:item" },
	      calls => [ qw ( Add Get Defined ) ] },
  } );

Net::XMPP::Protocol->AddNamespace (
  ns => "__netxmpp__:iq:pubsub:configure:x:field",
  tag => "field",
  xpath => {
    Var => { type => "scalar", path => '@var' },
    Value => { type => "scalar", path => 'value/text()' },
  } );

Net::XMPP::Protocol->AddNamespace (
  ns => "jabber:x:data",
  tag => "x",
  xpath => {
    Type => { type => "scalar", path => '@type' },
    Field => { type => "child", path => 'field',
	       child => { ns => "__netxmpp__:iq:pubsub:configure:x:field" },
	       calls => [ qw ( Add Get Defined ) ] },
  } );

Net::XMPP::Protocol->AddNamespace (
  ns => "__netxmpp__:iq:pubsub:configure",
  tag => "configure",
  xpath => {
    Node => { type => "scalar", path => '@node' },
    X => { type => "child", path => 'x',
	   child => { ns => "jabber:x:data" },
	   calls => [ qw ( Add Get Defined ) ] },
  } );

Net::XMPP::Protocol->AddNamespace (
  ns => XMPP_PUBSUB_NS,
  tag => "pubsub",
  xpath => {
    CreateNode => { type => "scalar", path => 'create/@node' },
    Configure => { type => "child", path => 'configure',
		   child => { ns => "__netxmpp__:iq:pubsub:configure" },
		   calls => [ qw ( Add Get Defined ) ] },
    SubscribeNode => { type => "scalar", path => 'subscribe/@node' },
    SubscribeJID => { type => "jid", path => 'subscribe/@jid' },
    UnsubscribeNode => { type => "scalar", path => 'unsubscribe/@node' },
    UnsubscribeJID => { type => "jid", path => 'unsubscribe/@jid' },
    Publish => { type => "child", path => 'publish',
		 child => { ns => "__netxmpp__:iq:pubsub:publish" },
		 calls => [ qw ( Add Get Defined ) ] },
  } );

Net::XMPP::Protocol->AddNamespace (
  ns => XMPP_PUBSUB_OWNER_NS,
  tag => "pubsub",
  xpath => {
    DeleteNode => { type => "scalar", path => 'delete/@node' },
  } );

Net::XMPP::Protocol->AddNamespace (
  ns => "__netxmpp__:message:pubsub:items",
  tag => "items",
  xpath => {
    Node => { type => "scalar", path => '@node' },
    Item => { type => "child", path => 'item',
	      child => { ns => "__netxmpp__:iq:pubsub:publish:item" },
	      calls => [ qw ( Add Get Defined ) ] },
  } );

Net::XMPP::Protocol->AddNamespace (
  ns => XMPP_PUBSUB_EVENT_NS,
  tag => "event",
  xpath => {
    Items => { type => "child", path => 'items',
	       child => { ns => "__netxmpp__:message:pubsub:items" },
	       calls => [ qw ( Add Get Defined ) ] },
  } );

1;
