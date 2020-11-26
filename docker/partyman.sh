#!/bin/bash
if (( $# == 0 )); then
    echo "usage: partyman.sh help"
    exit
elif (( $# > 0 )); then
    if [ -z "$NODE_ID" ]; then
        docker-compose exec partyman /root/partyman/partyman $@
    else
        bash -c "docker exec -it partyman_partyman.1.${NODE_ID} /root/partyman/partyman $@"
    fi
fi

