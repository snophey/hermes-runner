FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing openssh-server curl python3 python3-dev python3-pip python3-venv build-essential ca-certificates zip unzip git gh && \
    rm -rf /var/lib/apt/lists/*

# Create user with a build-time home at /opt/hermes (immutable image layer)
RUN useradd -m -d /opt/hermes -s /bin/bash hermes

USER root

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
