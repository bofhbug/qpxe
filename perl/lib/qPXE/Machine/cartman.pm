package qPXE::Machine::cartman;

use qPXE::Moose;
use strict;
use warnings;

extends qw ( qPXE::Machine );
with qw ( qPXE::Role::SSH qPXE::Role::XMPP qPXE::Role::Dhcpd );

__PACKAGE__->meta->make_immutable();

1;
