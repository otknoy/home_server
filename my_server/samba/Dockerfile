FROM alpine:3.13.2

RUN apk add --no-cache samba tini

ENV user=otknoy
ENV passwd=passon

RUN adduser -D ${user}
RUN echo -e ${passwd}'\n'${passwd} | pdbedit -a -u ${user} 

COPY ./smb.conf /etc/samba/
COPY ./start_samba.sh /usr/local/bin
RUN chmod 775 /usr/local/bin/start_samba.sh

EXPOSE 139 445

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/start_samba.sh"]
