FROM perl:5.30.0-threaded

ENV PERL_CPANM_OPT --verbose --mirror http://cpan.metacpan.org --mirror-only
ENV PERL_CPANM_OPT $PERL_CPANM_OPT --verify
RUN cpanm App::cpanminus

COPY . /usr/src/qpxe
RUN cd /usr/src/qpxe/perl && cpanm --installdeps .
#RUN cd /usr/src/qpxe/web && cpanm --installdeps .

WORKDIR /usr/src/qpxe/web
CMD [ "perl", "./qpxe-web" ]
