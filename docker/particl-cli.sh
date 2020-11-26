#!/bin/bash
if (( $# == 0 )); then
    echo "usage: particl-cli.sh help"
    exit
elif (( $# > 0 )); then
    if [ -z "$NODE_ID" ]; then
        docker-compose exec partyman /root/particlcore/particl-cli $@
    else
        bash -c "docker exec -it partyman_partyman.1.${NODE_ID} /root/particlcore/particl-cli $@"
    fi
fi

