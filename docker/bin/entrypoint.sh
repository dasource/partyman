#!/bin/bash

PARTICL_CONF="${PARTICL_DATADIR}/particl.conf"
PATH=${PARTYMAN_DIR}/bin:${PARTICL_DIR}:${PATH}

mkdir -p ${PARTICL_DATADIR}

echo "debug=${DEBUG:-0}" > ${PARTICL_CONF}
echo "printtoconsole=${PRINTTOCONSOLE:-0}" >> ${PARTICL_CONF}
echo "debuglogfile=debug.log" >> ${PARTICL_CONF}

echo "" > ${PARTYMAN_DIR}/cron.log
echo "" > ${PARTICL_DATADIR}/debug.log

echo "PARTYMAN_DIR: ${PARTYMAN_DIR}"
echo "PARTICL_DIR: ${PARTICL_DIR}"
echo "PARTICL_DATADIR: ${PARTICL_DATADIR}"
echo "PARTICL_CONF: ${PARTICL_CONF}"
echo "HTML_PATH: ${HTML_PATH}"
echo "PATH: ${PATH}"
echo

more ${PARTICL_CONF}
echo

echo "starting cron jobs..."
declare -p | grep -Ev "BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID" > /container.env
crontab crontab
cron
echo

echo "starting webserver..."
echo "include_path = \".:./public_html:/usr/share/php\"" >> /etc/php/7.2/cli/php.ini
rm -rf webserver/hosts.allow
cd webserver
./webserver start
echo

echo "starting particld..."
echo

exec "${PARTICL_DIR}/particld"
