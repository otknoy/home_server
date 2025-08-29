#!/bin/sh
set -e

if [ -z "${USER}" ] || [ -z "${PASSWORD}" ]; then
  echo "ERROR: The USER and PASSWORD environment variables must be set." >&2
  exit 1
fi

echo "Configuring Samba for user: ${USER}"

# Create user if they don't exist
if ! id -u "${USER}" > /dev/null 2>&1; then
    echo "Creating system user ${USER}"
    useradd --no-create-home --shell /usr/sbin/nologin "${USER}"
fi

# Add user to Samba
echo "Adding Samba user ${USER}"
echo -e "${PASSWORD}\n${PASSWORD}" | pdbedit -a -u "${USER}"

echo "Starting Samba services..."
# Start nmbd in the background
nmbd -D

# Start smbd in the foreground. Tini will act as PID 1 and reap it correctly.
# The -F flag is crucial for running in containers without a process manager like systemd.
exec smbd -F --no-process-group
