#!/bin/bash

docker-tags() {
    arr=("$@")

    for item in "${arr[@]}";
    do
        tokenUri="https://auth.docker.io/token"
        data=("service=registry.docker.io" "scope=repository:$item:pull")
        token="$(curl --silent --get --data-urlencode ${data[0]} --data-urlencode ${data[1]} $tokenUri | jq --raw-output '.token')"
        listUri="https://registry-1.docker.io/v2/$item/tags/list"
        authz="Authorization: Bearer $token"
        result="$(curl --silent --get -H "Accept: application/json" -H "Authorization: Bearer $token" $listUri | jq --raw-output '.')"
        echo $result
    done
}

if [ -z "$1" ]
  then
    echo "Error!"
    echo ""
    echo "Usage: ./docker-build-push.sh TAG"
    echo
    docker-tags "ludx/partyman" | jq --raw-output '.[]'

    exit 1
fi
TAG=$1
docker build -t partyman:latest -t docker.io/ludx/partyman:latest -t docker.io/ludx/partyman:$TAG .
docker push docker.io/ludx/partyman:$TAG
docker push docker.io/ludx/partyman:latest
