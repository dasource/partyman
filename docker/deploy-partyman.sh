#!/bin/bash
set -e

function export_envs() {
  local envFile=${1:-.env}
  while IFS='=' read -r key temp || [ -n "$key" ]; do
    local isComment='^[[:space:]]*#'
    local isBlank='^[[:space:]]*$'
    [[ $key =~ $isComment ]] && continue
    [[ $key =~ $isBlank ]] && continue
    value=$(eval echo "$temp")
    eval export "$key='$value'";
  done < $envFile
}

export_envs
export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')

docker node update --label-add ${STACK_NAME}.partyman=true "${NODE_ID}"

sed -i "s/traefik-public/${TRAEFIK_NETWORK}/" partyman.yml
docker stack deploy -c partyman.yml ${STACK_NAME}

echo "You should now be able to access: https://partyman.${UI_DOMAIN}"

