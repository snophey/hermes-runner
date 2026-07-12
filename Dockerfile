FROM ubuntu:26.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing openssh-server && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/hermes -s /bin/bash hermes

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
