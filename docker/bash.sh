#!/bin/bash
export NODE_ID=$(docker info -f '{{.Swarm.NodeID}}')
if [ -z "$NODE_ID" ]; then
    bash -c "clear && docker exec -it docker_partyman_1 bash"
else
    bash -c "clear && docker exec -ti partyman_partyman.1.$(docker service ps -f 'name=partyman_partyman.1' partyman_partyman -q --no-trunc | head -n1) bash"
fi
