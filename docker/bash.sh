#!/bin/bash
if [ -z "$NODE_ID" ]; then
    bash -c "clear && docker exec -it docker_partyman_1 bash"
else
    bash -c "clear && docker exec -it partyman_partyman.1.${NODE_ID} bash"
fi
