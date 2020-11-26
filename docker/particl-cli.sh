#!/bin/bash
if (( $# == 0 )); then
    echo "usage: particl-cli.sh help"
    exit
elif (( $# > 0 )); then
    export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
    if [ -z "$NODE_ID" ]; then
        docker-compose exec partyman /root/particlcore/particl-cli $@
    else
        docker exec -ti partyman_partyman.1.$(docker service ps -f 'name=partyman_partyman.1' partyman_partyman -q --no-trunc | head -n1) /root/particlcore/particl-cli $@
    fi
fi

