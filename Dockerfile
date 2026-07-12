FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing openssh-server curl python3 python3-dev python3-pip python3-venv build-essential ca-certificates zip unzip git gh && \
    rm -rf /var/lib/apt/lists/*

# Create user with a build-time home at /opt/hermes (immutable image layer)
RUN useradd -m -d /opt/hermes -s /bin/bash hermes

USER hermes

# Install everything into the build-time home dir
RUN curl -s "https://get.sdkman.io" | bash && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash && \
    curl https://install.duckdb.org | DUCKDB_VERSION=1.4.5 sh && \
    echo 'export PATH="/opt/hermes/.duckdb/cli/1.4.5":$PATH' >> /opt/hermes/.bashrc

RUN /opt/hermes/.nvm/nvm.sh install 24 && /opt/hermes/.nvm/nvm.sh npm install -g opencode-ai

RUN mkdir /opt/hermes/.config

RUN python3 -m venv /opt/hermes/.venv && \
    /opt/hermes/.venv/bin/pip install s3cmd

RUN echo 'source /opt/hermes/.venv/bin/activate' >> /opt/hermes/.bashrc

USER root

# Pre-create the SSH dir (will be copied to /home/hermes at runtime)
RUN mkdir -p /opt/hermes/.ssh && \
    chmod 700 /opt/hermes/.ssh && \
    chown hermes:hermes /opt/hermes/.ssh

# SSH config
RUN mkdir -p /etc/ssh/sshd_config.d && \
    echo "PasswordAuthentication no" > /etc/ssh/sshd_config.d/no_password.conf && \
    echo "AllowUsers hermes" > /etc/ssh/sshd_config.d/only_hermes.conf && \
    echo "HostKey /etc/ssh/ssh_host_keys/ssh_host_ed25519_key" >> /etc/ssh/sshd_config.d/only_hermes.conf && \
    echo "HostKey /etc/ssh/ssh_host_keys/ssh_host_ecdsa_key" >> /etc/ssh/sshd_config.d/only_hermes.conf && \
    echo "HostKey /etc/ssh/ssh_host_keys/ssh_host_rsa_key" >> /etc/ssh/sshd_config.d/only_hermes.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]
