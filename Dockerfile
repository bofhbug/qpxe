FROM alpine

# based on https://github.com/scottw/alpine-perl and https://github.com/lhost/alpine-perl

# RUN apk update && apk upgrade && apk add curl tar make gcc build-base wget gnupg
RUN apk update && apk upgrade && apk add curl wget make gcc build-base gnupg perl perl-dev
# RUN apk update && apk upgrade && apk add curl make gcc build-base wget gnupg perl perl-dev perl-module-install perl-file-remove perl-yaml-tiny perl-carp-clan perl-class-load perl-data-uuid perl-ipc-run3 perl-moox-types-mooselike perl-moose perl-net-openssh perl-test-exception perl-test-pod perl-xml-libxml perl-term-readkey yaml perl-yaml perl-utils perl-error perl-git git-perl perl-common-sense

RUN apk update && apk upgrade && apk add perl-dev perl-module-install perl-file-remove \
perl-yaml-tiny perl-carp-clan perl-class-load perl-data-uuid perl-ipc-run3 perl-moox-types-mooselike \
perl-moose perl-net-openssh perl-test-exception perl-test-pod perl-xml-libxml perl-term-readkey \
gnupg yaml perl-yaml perl-utils perl-error perl-git git-perl perl-common-sense


#RUN curl -LO https://raw.githubusercontent.com/miyagawa/cpanminus/master/cpanm \
#    && chmod +x cpanm \
#    && ./cpanm App::cpanminus \
#    && rm -fr ./cpanm /root/.cpanm
RUN apk update && apk upgrade && apk add perl-app-cpanminus perl-digest-sha1 && cpanm App::cpanminus && rm -fr ./cpanm /root/.cpanm

ENV PERL_CPANM_OPT --verbose --mirror https://cpan.metacpan.org --mirror-only
####RUN cpanm Digest::SHA Module::Signature && rm -rf ~/.cpanm

ENV PERL_CPANM_OPT --verbose --mirror http://cpan.metacpan.org --mirror-only
ENV PERL_CPANM_OPT $PERL_CPANM_OPT --verify
#RUN cpanm Digest::SHA Module::Signature Test::Most Test::Doctest LWP::UserAgent \
#    Email::MIME XML::Simple \
#    && rm -rf ~/.cpanm
RUN cpanm Digest::SHA Module::Signature \
    && rm -fr ./cpanm /root/.cpanm

RUN cpanm inc::Module::Install Catalyst MooseX::MarkAsMethods MooseX::Method::Signatures MooseX::StrictConstructor Net::SFTP Net::SSH::Perl Net::XMPP Sys::Virt TryCatch
    && rm -fr ./cpanm /root/.cpanm

RUN ls -latr .
COPY . /qpxe
RUN ls -latrR /qpxe
RUN cd /qpxe/perl && perl Makefile.PL

WORKDIR /
