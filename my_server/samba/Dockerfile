FROM alpine:3.16.2

RUN apk add --no-cache samba tini

ENV USER=user
ENV PASSWORD=password

COPY ./smb.conf /etc/samba/
COPY ./start_samba.sh /usr/local/bin
RUN chmod 775 /usr/local/bin/start_samba.sh

EXPOSE 139 445

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/start_samba.sh"]
