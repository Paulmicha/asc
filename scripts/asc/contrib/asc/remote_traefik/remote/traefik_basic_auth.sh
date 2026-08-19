#!/usr/bin/env bash

##
# Reads the Traefik dashboard Http Basic Auth crendentials from given remote.
#
# @param 1 [optional] String : the remote instance ID. Defaults to 'prod'.
#
# @example
#   # From 'prod' :
#   make remote-traefik-basic-auth
#   # Or :
#   asc/extensions/remote_traefik/remote/traefik_basic_auth.sh
#
#   # Specify target remote instance :
#   make remote-traefik-basic-auth 'stage'
#   # Or :
#   asc/extensions/remote_traefik/remote/traefik_basic_auth.sh 'stage'
#

a_remote_id="$1"

if [[ -z "$a_remote_id" ]]; then
  a_remote_id='prod'
fi

f_remote_check_id "$a_remote_id"

asc/extensions/remote/remote/exec.sh "$a_remote_id" \
  asc/instance/registry/get.sh 'traefik_dashboard_creds'
