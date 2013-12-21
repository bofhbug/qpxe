package qPXE::Test::BasicDhcpHttp;

use qPXE::Test::Sugar;
extends qw ( qPXE::Test );
has_machine qw ( cartman butters );
has_xmpp qw ( cartman );
has_dut qw ( butters );

method prepare () {

  # Create DHCP reservation
  $self->cartman->dhcpd->reserve (
    $self->butters->name,
    [ "hardware ethernet ".$self->butters->mac ( "primary" ).";",
      "filename \"http://cartman/boot/demo.ipxe\";",
      "option ipxe.testid ".$self->uuid_colons.";" ] );

}

method execute () {

  # Start DUT
  $self->butters->domain->create();

  # Wait for DUT to boot
  $self->wait ( "booted", 60 );

}

method cleanup () {

  # Shut down DUT
  $self->butters->domain->destroy();
}

__PACKAGE__->meta->make_immutable();

1;
