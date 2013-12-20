package qPXE::Test::Sugar;

=head1 NAME

qPXE::Test::Sugar - Syntactic sugar for constructing test cases

=head1 SYNOPSIS

    use qPXE::Test::Sugar;
    extends qw ( qPXE::Test );
    has_machine qw ( cartman );
    has_dut qw ( butters );

    method execute () {
      $self->butters->domain->create();
    }

=cut

use qPXE::Moose ();
use MooseX::Method::Signatures;
use MooseX::MarkAsMethods autoclean => 1;
use Moose::Exporter;
use Carp;
use strict;
use warnings;

Moose::Exporter->setup_import_methods (
  with_meta => [ "has_machine", "has_dut", "has_xmpp" ],
  also => [ "qPXE::Moose" ],
);

=head1 EXPORTED FUNCTIONS

=over

=item C<< has_machine ( @machines ) >>

Creates attributes for each machine named in C<@machines>, providing a
shortcut for C<< $self->lab->machine($machine) >>.

=cut

sub has_machine {
  my $meta = shift;
  my @machines = @_;

  foreach my $machine ( @machines ) {

    # Sanity check
    if ( my $attribute = $meta->find_attribute_by_name ( $machine ) ) {
      confess "Attribute ".$machine." already exists and is not a machine"
	  unless ( $attribute->type_constraint &&
		   $attribute->type_constraint->is_a_type_of ("qPXE::Machine"));
    }

    # Create builder
    my $builder = "_build_".$machine;
    $meta->add_method ( $builder => method () {
      return $self->lab->machine ( $machine );
    } );

    # Create attribute
    $meta->add_attribute ( $machine => ( is => "ro",
					 isa => "qPXE::Machine",
					 lazy => 1,
					 builder => $builder,
					 init_arg => undef ) );
  }
}

=item C<< has_dut ( @duts ) >>

Creates attributes for each machine named in C<@duts>, as with
C<has_machine()>.  Each machine is forced into an initial power-off
state.

=cut

sub has_dut {
  my $meta = shift;
  my @duts = @_;

  # Create attribute for machine
  has_machine ( $meta, @duts );

  foreach my $dut ( @duts ) {

    # Modify builder
    $meta->add_around_method_modifier (
      $meta->find_attribute_by_name ( $dut )->builder, sub {
	my $orig = shift;
	my $self = shift;
	my $machine = $self->$orig ( @_ );

	# Force machine into initial power-off state
	$machine->domain->destroy() if $machine->domain->is_active();

	return $machine;
      } );
  }
}

sub has_xmpp {
  my $meta = shift;
  my $xmpp = shift;

  # Create attribute for machine
  has_machine ( $meta, $xmpp );

  # Create "xmpp" builder
  my $builder = "_build_xmpp";
  $meta->add_method ( $builder => method () {
    return $self->$xmpp->xmpp;
  } );

  # Create "xmpp" attribute
  $meta->add_attribute ( "xmpp" => ( is => "ro",
				     isa => "qPXE::XMPP",
				     lazy => 1,
				     builder => $builder,
				     init_arg => undef ) );

  # Create "subscribe" method
  $meta->add_method ( "subscribe" => method () {
    $self->xmpp->subscribe ( $self->uuid );
  } );

  # Create "wait" method
  $meta->add_method ( "wait" => method ( Str $id, Int $timeout ) {
    return $self->xmpp->wait ( $self->uuid, $id, $timeout );
  } );

  # Create "unsubscribe" method
  $meta->add_method ( "unsubscribe" => method () {
    $self->xmpp->unsubscribe ( $self->uuid );
  } );
}

=back

=cut

1;
