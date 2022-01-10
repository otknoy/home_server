FROM python:3.9.9-slim-bullseye

RUN apt-get update && apt-get install -y tini
RUN pip install wsgidav==4.0.0 cheroot python-pam
RUN mkdir -p /var/wsgidav-root

ENV USER=user
ENV PASSWORD=password

COPY ./start_wsgidav.sh /usr/local/bin
RUN chmod 775 /usr/local/bin/start_wsgidav.sh

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/start_wsgidav.sh"]
