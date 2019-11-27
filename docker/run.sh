#!/bin/bash

# using the same docker-compose project name allows these containers to be cleaned up
# with the parent by using `docker-compose down --remove-orphans -v`
project=$(docker inspect $(hostname) | jq -r ".[0].Config.Labels[\"com.docker.compose.project\"]")
net=$(docker inspect $(hostname) | jq -r ".[0].NetworkSettings.Networks[\"${project}_default\"].NetworkID")
volume=$(docker inspect $(hostname) | jq -r ".[0].Mounts[] | select(.Type == \"volume\" and .Destination == \"/tupelo-local\") | .Name")

export TUPELO_VERSION=${TUPELO_VERSION:-master}
export TUPELO_BUILD_PATH=${TUPELO_BUILD_PATH:-}
export COMMUNITY_VERSION=${COMMUNITY_VERSION:-$TUPELO_VERSION}
export NETWORK_NAME=$net
export VOLUME_NAME=$volume

dockerCompose="docker-compose -p $project -f ./docker-compose.yml"

# docker-compose 1.24.1 and 1.25.0 behave differently when both `build` and `image` are specified
# according to the docs, we should be able to have both in the same docker-compose.yml and
# "non buildable" services would fallback to pulling an image (aka when `TUPELO_BUILD_PATH` is empty)
# that is the behavior in in 1.24.1, but not in 1.25.0 currently. So for now, using a separate override
# docker-compose.tupelobuild.yml with the build commands. This may change in the future and can revert to
# a single docker-compose.yml with both the build and image attributes
#
# see https://github.com/docker/compose/pull/7039 and https://github.com/docker/compose/pull/7052
if [[ "$TUPELO_BUILD_PATH" != "" ]]; then
  dockerCompose+=" -f ./docker-compose.tupelobuild.yml"
  $dockerCompose build
fi

# This runs in background, waits for the 3 tupelo nodes to print out "started signer host",
# at which point it will touch a file on the shared volume so `wait-for-tupelo.sh` can trigger
trackStart() {
  started=0
  while [ "$started" -lt "3" ]; do
    started=$($dockerCompose logs | grep "started signer host" | sort | uniq | wc -l)
    sleep 0.5
  done
  touch /tupelo-local/started
}
trackStart &

exec $dockerCompose up