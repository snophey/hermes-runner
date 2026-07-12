FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing openssh-server curl python3 python3-dev python3-pip python3-venv build-essential ca-certificates zip unzip && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/hermes -s /bin/bash hermes

USER hermes
RUN curl -s "https://get.sdkman.io" | bash && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash && \
    curl https://install.duckdb.org | DUCKDB_VERSION=1.4.5 sh && \
    echo 'export PATH="/home/hermes/.duckdb/cli/1.4.5":$PATH' >> /home/hermes/.bashrc

RUN python3 -m venv /home/hermes/.venv && \
    /home/hermes/.venv/bin/pip install s3cmd

RUN echo 'source /home/hermes/.venv/bin/activate' >> /home/hermes/.bashrc

USER root

RUN mkdir -p /home/hermes/.ssh && \
    chmod 700 /home/hermes/.ssh && \
    chown hermes:hermes /home/hermes/.ssh

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

RUN echo "PasswordAuthentication no" > /etc/ssh/sshd_config.d/no_password.conf && \
    echo "AllowUsers hermes" > /etc/ssh/sshd_config.d/only_hermes.conf && \
    echo "HostKey /etc/ssh/ssh_host_keys/ssh_host_ed25519_key" >> /etc/ssh/sshd_config.d/only_hermes.conf && \
    echo "HostKey /etc/ssh/ssh_host_keys/ssh_host_ecdsa_key" >> /etc/ssh/sshd_config.d/only_hermes.conf && \
    echo "HostKey /etc/ssh/ssh_host_keys/ssh_host_rsa_key" >> /etc/ssh/sshd_config.d/only_hermes.conf

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]
