#!/bin/sh

# This script provides a simple wait then execute behavior
# It is mounted in the tupelo-local volume for use in other containers

while [ ! -f /tupelo-local/started ]; do sleep 1; done

exec $@