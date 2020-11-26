#!/bin/bash
if (( $# == 0 )); then
    echo "usage: partyman.sh help"
    exit
elif (( $# == 1 )); then
    docker-compose exec partyman /root/partyman/partyman $@ --quiet
fi

