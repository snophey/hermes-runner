#!/usr/bin/env bash
set -euo pipefail

if [ -z "${ALLOWED_KEYS:-}" ]; then
  echo "ERROR: ALLOWED_KEYS environment variable is not set" >&2
  exit 1
fi

BUILD_HOME="/opt/hermes"
RUNTIME_HOME="/home/hermes"

echo "Setting up home directory at ${RUNTIME_HOME}..."

# If /home/hermes is empty (fresh volume mount), copy from build-time home
if [ -z "$(ls -A "${RUNTIME_HOME}" 2>/dev/null)" ]; then
  echo "Fresh volume mount detected — copying build-time home contents..."
  cp -a "${BUILD_HOME}/." "${RUNTIME_HOME}/"
  chown -R hermes:hermes "${RUNTIME_HOME}"
  echo "Home directory populated from build-time image."
else
  echo "Existing home directory at ${RUNTIME_HOME}, skipping copy."
fi

# Update user home directory to /home/hermes
usermod -d "${RUNTIME_HOME}" hermes

echo "SSH keys configured..."
mkdir -p "${RUNTIME_HOME}/.ssh"
echo "$ALLOWED_KEYS" > "${RUNTIME_HOME}/.ssh/authorized_keys"
chmod 600 "${RUNTIME_HOME}/.ssh/authorized_keys"
chmod go-w "${RUNTIME_HOME}/.ssh"
chown -R hermes:hermes "${RUNTIME_HOME}/.ssh"
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
  echo "SSH host keys already exist, fixing permissions..."
  chmod 600 "$SSH_HOST_KEYS_DIR/ssh_host_ed25519_key"
  chmod 600 "$SSH_HOST_KEYS_DIR/ssh_host_ecdsa_key"
  chmod 600 "$SSH_HOST_KEYS_DIR/ssh_host_rsa_key"
  echo "SSH host key permissions fixed."
fi

SSHD_PORT="${SSH_PORT:-22}"
echo "Starting sshd on port ${SSHD_PORT}..."

exec /usr/sbin/sshd -D -p "$SSHD_PORT"
