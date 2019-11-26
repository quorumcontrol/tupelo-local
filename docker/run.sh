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

dockerCompose="docker-compose -f ./docker-compose.yml -p $project"

if [[ "$TUPELO_BUILD_PATH" != "" ]]; then
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