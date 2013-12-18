package qPXE::Test::BasicDhcpHttp;

use qPXE::Test::Sugar;
extends qw ( qPXE::Test );
has_machine qw ( cartman );
has_dut qw ( butters );

method execute () {

  # Create DHCP reservation
  $self->cartman->dhcpd->reserve (
    $self->butters->name,
    [ "hardware ethernet ".$self->butters->mac ( "primary" ).";",
      "filename \"http://cartman/boot/demo.ipxe\";",
      "option ipxe.testid ".$self->uuid_colons.";" ] );

  # Start DUT
  $self->butters->domain->create();
  
}

__PACKAGE__->meta->make_immutable();

1;
