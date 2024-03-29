FROM ubuntu:22.04

ARG MINECRAFT_UID=1000
ARG MINECRAFT_GID=1000

ENV MINECRAFT_VERSION=1.19.51.01

WORKDIR /data

RUN groupadd -g $MINECRAFT_GID minecraft \
    && useradd -m -s /bin/bash -u $MINECRAFT_UID -g $MINECRAFT_GID minecraft \
    && chown minecraft:minecraft /data

RUN apt-get update \
    && apt-get install -y curl netcat screen tzdata unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
COPY console start.sh /usr/local/bin/

EXPOSE 19132/udp

USER minecraft

CMD ["start.sh"]

HEALTHCHECK --interval=5s --start-period=5s CMD nc -uz 127.0.0.1 19132
