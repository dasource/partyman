#!/bin/bash
echo "Getting partyman status..."
"${PARTYMAN_DIR}"/partyman status > "${HTML_PATH}"/partyman-status.tmp || true
"${PARTYMAN_DIR}"/partyman stakingnode stats >> "${HTML_PATH}"/partyman-status.tmp || true
"${PARTICL_DIR}"/particl-cli getwalletinfo | grep watchonly >> "${HTML_PATH}"/partyman-status.tmp || true
