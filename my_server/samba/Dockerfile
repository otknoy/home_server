FROM alpine:3.11.3

RUN apk add --no-cache samba

ENV user=otknoy
ENV passwd=passon

RUN adduser -D ${user}
RUN echo -e ${passwd}'\n'${passwd} | pdbedit -a -u ${user} 

COPY ./smb.conf /etc/samba/
COPY ./start_samba.sh /usr/local/bin
RUN chmod 775 /usr/local/bin/start_samba.sh

EXPOSE 139 445

ENTRYPOINT [ "/bin/ash" ]
CMD [ "/usr/local/bin/start_samba.sh" ]
