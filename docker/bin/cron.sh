#!/bin/bash
"${PARTYMAN_DIR}"/partyman status > "${HTML_PATH}"/partyman-status.tmp
"${PARTYMAN_DIR}"/partyman stakingnode stats >> "${HTML_PATH}"/partyman-status.tmp
"${PARTICL_DIR}"/particl-cli getwalletinfo | grep watchonly >> "${HTML_PATH}"/partyman-status.tmp
echo $(printf '%s %s\n' "$(date)") updated partyman status...
