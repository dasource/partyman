#!/bin/bash

PARTYMAN_PATH=~/partyman
PARTICL_PATH=~/particlcore
HTML_PATH=$PARTYMAN_PATH/webserver/public_html

"$PARTYMAN_PATH"/partyman status > "$HTML_PATH"/partyman-status.tmp
"$PARTYMAN_PATH"/partyman stakingnode stats >> "$HTML_PATH"/partyman-status.tmp
"$PARTICL_PATH"/particl-cli getwalletinfo | grep watchonly >> "$HTML_PATH"/partyman-status.tmp
