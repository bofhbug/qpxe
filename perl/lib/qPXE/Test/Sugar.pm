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

use Moose ();
use MooseX::StrictConstructor ();
use MooseX::Method::Signatures;
use MooseX::MarkAsMethods autoclean => 1;
use Moose::Exporter;
use strict;
use warnings;

Moose::Exporter->setup_import_methods (
  with_meta => [ 'has_machine', 'has_dut' ],
  also => [ 'Moose', 'MooseX::StrictConstructor' ],
);

sub init_meta {
  my $class = shift;
  my %params = @_;
  my $for_class = $params{for_class};

  Moose->init_meta ( @_ );
  MooseX::Method::Signatures->setup_for ( $for_class, {} );
  MooseX::MarkAsMethods->import ( { into => $for_class }, autoclean => 1 );
}

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
    my $builder = "_build_".$machine;

    $meta->add_method ( $builder => method () {
      return $self->lab->machine ( $machine );
    } );

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

  foreach my $dut ( @duts ) {
    my $builder = "_build_".$dut;

    $meta->add_method ( $builder => method () {
      # Ensure DUT starts out powered off
      my $machine = $self->lab->machine ( $dut );
      $machine->domain->destroy() if $machine->domain->is_active();
      return $machine;
    } );

    $meta->add_attribute ( $dut => ( is => "ro",
				     isa => "qPXE::Machine",
				     lazy => 1,
				     builder => $builder,
				     init_arg => undef ) );
  }
}

=back

=cut

1;
