#!/usr/bin/env bash

##
# Downloads traefik logs from a remote 'dev' type instance.
#
# @param 1 [optional] String : the remote instance ID. Defaults to 'prod'.
#
# @example
#   # From 'prod' :
#   make remote-traefik-logs-fetch
#   # Or :
#   asc/extensions/remote_traefik/remote/traefik_logs_fetch.sh
#
#   # Specify target remote instance :
#   make remote-traefik-logs-fetch 'stage'
#   # Or :
#   asc/extensions/remote_traefik/remote/traefik_logs_fetch.sh 'stage'
#

. asc/bootstrap.sh

a_remote_id="$1"

if [[ -z "$a_remote_id" ]]; then
  a_remote_id='prod'
fi

f_remote_check_id "$a_remote_id"

if [[ ! -d "data/logs/remote/$a_remote_id" ]]; then
  mkdir -p "data/logs/remote/$a_remote_id"
fi

datestamp="$(date +"%Y-%m-%d.%H-%M-%S")"

f_remote_download "$a_remote_id" \
  "data/logs/traefik.log" \
  "data/logs/remote/$a_remote_id/${datestamp}.traefik.log"
