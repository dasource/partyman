#!/bin/bash
set -e

IFS=$'\n'
while read -r var;do
    export "$var"
done < <(grep -Ev '^#|^$' .env)

export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')

docker node update --label-add $STACK_NAME.partyman=true "$NODE_ID"

sed -i "s/traefik-public/$TRAEFIK_NETWORK/" partyman.yml
docker stack deploy -c partyman.yml $STACK_NAME

echo "You should now be able to access: https://partyman.$UI_DOMAIN"
