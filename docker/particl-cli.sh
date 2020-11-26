#!/bin/bash
if (( $# == 0 )); then
    echo "usage: particl-cli.sh help"
    exit
elif (( $# > 0 )); then
    docker-compose exec partyman /root/particlcore/particl-cli $@
fi

