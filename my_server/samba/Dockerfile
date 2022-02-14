FROM alpine:3.15.0

ENV SAMBA_VERSION 4.15.5-r0

RUN apk add --no-cache samba=${SAMBA_VERSION} tini

ENV USER=user
ENV PASSWORD=password

COPY ./smb.conf /etc/samba/
COPY ./start_samba.sh /usr/local/bin
RUN chmod 775 /usr/local/bin/start_samba.sh

EXPOSE 139 445

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/start_samba.sh"]
