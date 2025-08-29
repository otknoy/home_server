# Builder stage for Tini
FROM rockylinux:9.3-minimal as builder

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

# Final stage
FROM rockylinux:9.3-minimal

# Install Samba and clean up
RUN microdnf -y update && \
    microdnf -y install samba && \
    microdnf clean all

# Copy Tini from the builder stage
COPY --from=builder /tini /tini

# Copy Samba configuration and startup script
COPY ./smb.conf /etc/samba/smb.conf
COPY ./start_samba.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/start_samba.sh

# Expose Samba ports
EXPOSE 139 445

# Add a healthcheck to verify Samba is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD smbclient -L localhost -U% -N || exit 1

# Set the entrypoint
ENTRYPOINT ["/tini", "--", "/usr/local/bin/start_samba.sh"]
