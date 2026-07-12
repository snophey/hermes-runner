#!/usr/bin/env bash
set -euo pipefail

if [ -z "${ALLOWED_KEYS:-}" ]; then
  echo "ERROR: ALLOWED_KEYS environment variable is not set" >&2
  exit 1
fi

echo "Setting up SSH keys for hermes user..."
mkdir -p /home/hermes/.ssh
echo "$ALLOWED_KEYS" > /home/hermes/.ssh/authorized_keys
chmod 600 /home/hermes/.ssh/authorized_keys
chmod go-w /home/hermes/.ssh
chown -R hermes:hermes /home/hermes/.ssh
echo "SSH keys configured successfully."

SSHD_PORT="${SSH_PORT:-22}"
echo "Starting sshd on port ${SSHD_PORT}..."

exec /usr/sbin/sshd -D -p "$SSHD_PORT"
