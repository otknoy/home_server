FROM debian:bullseye

RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y nsd dnsutils

COPY nsd.conf /etc/nsd/nsd.conf
COPY otknoy.com.zone /etc/nsd/zone/otknoy.com.zone

RUN nsd-checkconf /etc/nsd/nsd.conf

ENTRYPOINT ["/usr/sbin/nsd", "-d"]
