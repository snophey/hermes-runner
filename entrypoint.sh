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

SSH_HOST_KEYS_DIR="/etc/ssh/ssh_host_keys"
mkdir -p "$SSH_HOST_KEYS_DIR"

if [ -z "$(ls -A "$SSH_HOST_KEYS_DIR" 2>/dev/null)" ]; then
  echo "Generating SSH host keys..."
  ssh-keygen -t ed25519 -f "$SSH_HOST_KEYS_DIR/ssh_host_ed25519_key" -N ""
  ssh-keygen -t ecdsa -f "$SSH_HOST_KEYS_DIR/ssh_host_ecdsa_key" -N ""
  ssh-keygen -t rsa -f "$SSH_HOST_KEYS_DIR/ssh_host_rsa_key" -N ""
  echo "SSH host keys generated successfully."
else
  echo "SSH host keys already exist, skipping generation."
fi

SSHD_PORT="${SSH_PORT:-22}"
echo "Starting sshd on port ${SSHD_PORT}..."

exec /usr/sbin/sshd -D -p "$SSHD_PORT"
