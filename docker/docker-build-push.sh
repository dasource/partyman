#!/bin/bash
if [ -z "$1" ]
  then
    echo "Error!"
    echo ""
    echo "Usage: ./docker-build-push.sh TAG"
    exit 1
fi
TAG=$1
docker build -t partyman:latest -t docker.io/ludx/partyman:latest -t docker.io/ludx/partyman:$TAG .
docker push docker.io/ludx/partyman:$TAG
docker push docker.io/ludx/partyman:latest
