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

# Update user home directory to /home/hermes (must be done before su - hermes)
usermod -d "${RUNTIME_HOME}" hermes

if [ -z "$(ls -A "${RUNTIME_HOME}/.sdkman" 2>/dev/null)" ] || \
   [ -z "$(ls -A "${RUNTIME_HOME}/.nvm" 2>/dev/null)" ] || \
   [ -z "$(ls -A "${RUNTIME_HOME}/.duckdb" 2>/dev/null)" ] || \
   [ -z "$(ls -A "${RUNTIME_HOME}/.venv" 2>/dev/null)" ]; then
  echo "Setting up hermes user tools as hermes..."
  su - hermes -c 'bash -s' <<'SETUP_SCRIPT'
  # SDKMAN
  if [ ! -d "/home/hermes/.sdkman" ]; then
    echo "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash
  else
    echo "SDKMAN already installed."
  fi

  # NVM
  if [ ! -d "/home/hermes/.nvm" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash
  else
    echo "NVM already installed."
  fi

  # DuckDB
  if [ ! -d "/home/hermes/.duckdb" ]; then
    echo "Installing DuckDB..."
    curl https://install.duckdb.org | DUCKDB_VERSION=1.4.5 sh
  else
    echo "DuckDB already installed."
  fi

  # Python venv + s3cmd
  if [ ! -d "/home/hermes/.venv" ]; then
    echo "Creating Python venv and installing s3cmd..."
    python3 -m venv /home/hermes/.venv
    /home/hermes/.venv/bin/pip install s3cmd
  else
    echo "Python venv already created."
  fi

  echo "User tools setup complete."
SETUP_SCRIPT
else
  echo "All hermes user tools already installed, skipping setup."
fi

echo "SSH keys configured..."
mkdir -p "${RUNTIME_HOME}/.ssh"
echo "$ALLOWED_KEYS" > "${RUNTIME_HOME}/.ssh/authorized_keys"
chmod 600 "${RUNTIME_HOME}/.ssh/authorized_keys"
chmod go-w "${RUNTIME_HOME}/.ssh"
chown -R hermes:hermes "${RUNTIME_HOME}/.ssh"
echo "SSH keys configured successfully."

if [ -n "${GITHUB_ACCESS_TOKEN:-}" ]; then
  echo "Logging in to GitHub..."
  echo "$GITHUB_ACCESS_TOKEN" | gh auth login --with-token
  gh auth setup-git
  echo "GitHub login successful."
else
  echo "WARNING: GITHUB_ACCESS_TOKEN is not set, skipping GitHub login."
fi

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
