package qPXE::Role::SSH;

=head1 NAME

qPXE::Role::SSH - A machine accessible via SSH

=head1 SYNOPSIS

    package qPXE::Machine::foo;
    use Moose;
    extends qw ( qPXE::Machine );
    with qw ( qPXE::Role::SSH );

    use qPXE::Lab;
    my $lab = qPXE::Lab->new ( uri => "qemu:///system" );
    my $machine = $lab->machine ( "foo" );

    $machine->upload ( "passwd", "/etc/passwd" );

    $machine->ssh->cmd ( "/sbin/poweroff" );

=cut

use Moose::Role;
use MooseX::Method::Signatures;
use MooseX::MarkAsMethods autoclean => 1;
use Net::SSH::Perl;
use Net::SFTP;
use Net::SFTP::Constants qw ( SSH2_FX_OK SSH2_FX_NO_SUCH_FILE );
use Carp;
use strict;
use warnings;

requires qw ( hostname );

=head1 ATTRIBUTES

=over

=cut

has "_sshuser" => (
  is => "ro",
  isa => "Str",
  lazy => 1,
  default => "root",
  init_arg => undef,
);

has "_sshargs" => (
  is => "ro",
  isa => "HashRef",
  lazy => 1,
  default => sub { return { compression => 0, # compression is broken
			    interactive => 0,
			    protocol => "2,1" } },
  init_arg => undef,
);

=item C<ssh>

The C<Net::SSH::Perl> object providing access to the machine via SSH.

=cut

has "ssh" => (
  is => "ro",
  isa => "Net::SSH::Perl",
  lazy => 1,
  builder => "_build_ssh",
  init_arg => undef,
);

method _build_ssh () {
  my $ssh = Net::SSH::Perl->new ( $self->hostname, %{$self->_sshargs} );
  $ssh->login ( $self->_sshuser );
  return $ssh;
}

=item C<sftp>

The C<Net::SFTP> object providing access to the machine via SFTP.

=cut

has "sftp" => (
  is => "ro",
  isa => "Net::SFTP",
  lazy => 1,
  builder => "_build_sftp",
  init_arg => undef,
);

method _build_sftp () {

  # There seems to be no way to ask Net::SFTP to use an existing
  # Net::SSH::Perl connection; we have to let it create a second
  # connection.
  #
  return Net::SFTP->new ( $self->hostname, user => $self->_sshuser,
			  warn => 0, ssh_args => $self->_sshargs );
}

=back

=head1 METHODS

=over

=item C<< upload ( $localfile, $remotefile ) >>

Upload the local file C<$localfile> as the remote file C<$remotefile>.
If C<$localfile> is undefined, then the remote file will be deleted.

=cut

method upload ( Str | FileHandle | Undef $localfile, Str $remotefile ) {

  if ( defined $localfile ) {
    $self->sftp->put ( $localfile, $remotefile )
	or croak ( "Could not upload ".$remotefile.": ".
		   [ $self->sftp->status ]->[1] );
  } else {
    my $status = $self->sftp->do_remove ( $remotefile );
    croak ( "Could not remove ".$remotefile.": ".[ $self->sftp->status ]->[1] )
	unless ( $status == SSH2_FX_OK ) || ( $status == SSH2_FX_NO_SUCH_FILE );
  }
}

=back

=cut

1;
