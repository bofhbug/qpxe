FROM perl:5.30.0-threaded

COPY . /usr/src/qpxe
WORKDIR /usr/src/qpxe/web
CMD [ "perl", "./qpxe-web" ]
