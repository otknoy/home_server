FROM rockylinux/rockylinux:10.2-minimal

RUN microdnf -y update && microdnf -y install samba

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

COPY ./start_samba.sh /usr/local/bin
RUN chmod 775 /usr/local/bin/start_samba.sh

EXPOSE 139 445

ENTRYPOINT ["/tini", "--", "/usr/local/bin/start_samba.sh"]
