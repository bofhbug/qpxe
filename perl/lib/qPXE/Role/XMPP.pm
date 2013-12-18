package qPXE::Role::XMPP;

=head1 NAME

qPXE::Role::XMPP - A machine providing an XMPP server for monitoring tests

=head1 SYNOPSIS

    package qPXE::Machine::foo;
    use Moose;
    extends qw ( qPXE::Machine );
    with qw ( qPXE::Role::XMPP );

=cut

use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::MarkAsMethods autoclean => 1;
use qPXE::XMPP;
use strict;
use warnings;

requires qw ( hostname );

=head1 ATTRIBUTES

=over

=item C<xmpp>

The C<qPXE::XMPP> object representing the XMPP server.

=cut

has "xmpp" => (
  is => "ro",
  isa => "qPXE::XMPP",
  lazy => 1,
  builder => "_build_xmpp",
  init_arg => undef,
);

method _build_xmpp () {
  return qPXE::XMPP->new ( machine => $self );
}

=back

=cut

1;
