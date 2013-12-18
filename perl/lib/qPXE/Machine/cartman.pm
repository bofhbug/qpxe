package qPXE::Machine::cartman;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Method::Signatures;
use MooseX::MarkAsMethods autoclean => 1;
use strict;
use warnings;

extends qw ( qPXE::Machine );
with qw ( qPXE::Role::SSH qPXE::Role::XMPP qPXE::Role::Dhcpd );

__PACKAGE__->meta->make_immutable();

1;
