#!/usr/bin/env bash

##
# Deploy stack update to remote instance.
#
# @example
#   # Deploy target defaults to the 'prod' remote instance.
#   make stack-deploy
#   # Or :
#   asc/extensions/remote_asc/stack/deploy.sh
#
#   # Deploy to the 'dev' remote instance.
#   make stack-deploy 'dev'
#   # Or :
#   asc/extensions/remote_asc/stack/deploy.sh 'dev'
#

a_remote_id="$1"

if [[ -z "$a_remote_id" ]]; then
  a_remote_id='prod'
fi

asc/extensions/remote_asc/remote/exec.sh "$a_remote_id" \
  'git pull && asc/instance/reinit.sh'
