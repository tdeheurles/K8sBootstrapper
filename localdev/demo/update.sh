#!/usr/bin/env bash
set -euo pipefail

# Build the docker image with the same name
# This is to simplify a useless versioning
docker build -t hellodocker .

kubectl delete pod --selector="com.docker.project=tutorial"
