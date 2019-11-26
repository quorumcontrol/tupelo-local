FROM debian:stretch-slim
LABEL maintainer="dev@quorumcontrol.com"

RUN apt-get update && \
    apt-get install -y jq && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=library/docker:latest /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker/compose:1.25.0-debian /usr/local/bin/docker-compose /usr/bin/docker-compose

# This creates a volume that can be mounted into users' containers and
# contains toml config files, helper scripts, and a docker-compose
VOLUME /tupelo-local
COPY ./docker/ /tupelo-local

WORKDIR /tupelo-local

ENTRYPOINT [ "/tupelo-local/run.sh" ]