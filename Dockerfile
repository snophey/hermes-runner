FROM ubuntu:26.04

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata && \
    apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing openssh-server curl python3 python3-dev build-essential zip unzip && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/hermes -s /bin/bash hermes

USER hermes
RUN curl -s "https://get.sdkman.io" | bash && \
    bash -c "source /home/hermes/.sdkman/bin/sdkman-init.sh && sdk selfupdate" && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.5/install.sh | bash

USER root

RUN mkdir -p /home/hermes/.ssh && \
    chmod 700 /home/hermes/.ssh && \
    chown hermes:hermes /home/hermes/.ssh

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

RUN echo "PasswordAuthentication no" > /etc/ssh/sshd_config.d/no_password.conf && \
    echo "AllowUsers hermes" > /etc/ssh/sshd_config.d/only_hermes.conf

EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]
