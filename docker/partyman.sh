#!/bin/bash
if (( $# == 0 )); then
    echo "usage: partyman.sh help"
    exit
elif (( $# > 0 )); then
    docker-compose exec partyman /root/partyman/partyman $@
fi

