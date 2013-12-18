use inc::Module::Install;

name "qPXE";
license "perl";
all_from "lib/qPXE.pm";
build_requires "Test::More";
build_requires "Test::Exception";
build_requires "Test::Pod";
install_script "qpxe-dhcpd", "qpxe-demo";

requires "Carp";
requires "Carp::Clan";
requires "Moose";
requires "Moose::Util::TypeConstraints";
requires "MooseX::StrictConstructor";
requires "MooseX::Method::Signatures";
requires "MooseX::MarkAsMethods";
requires "Class::Load";
requires "Sys::Virt";
requires "XML::LibXML";
requires "Net::SSH::Perl";
requires "Net::SFTP";
requires "Data::UUID";

WriteAll;
