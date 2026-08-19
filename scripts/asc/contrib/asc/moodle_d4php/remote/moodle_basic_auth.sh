#!/usr/bin/env bash

##
# Reads the Docker4Druapl Http Basic Auth crendentials from given remote.
#
# @param 1 [optional] String : the remote instance ID. Defaults to 'dev'.
#
# @example
#   # From a remote instance identified by 'dev' :
#   make remote-moodle-basic-auth
#   # Or :
#   asc/extensions/moodle_d4php/remote/moodle_basic_auth.sh
#
#   # Specify target remote instance :
#   make remote-moodle-basic-auth 'stage'
#   # Or :
#   asc/extensions/moodle_d4php/remote/moodle_basic_auth.sh 'stage'
#

a_remote_id="$1"

if [[ -z "$a_remote_id" ]]; then
  a_remote_id='dev'
fi

asc/extensions/remote/remote/exec.sh "$a_remote_id" \
  asc/instance/registry/get.sh 'moodle_basic_auth_creds'
