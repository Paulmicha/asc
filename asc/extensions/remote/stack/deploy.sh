#!/usr/bin/env bash

##
# Deploy stack update to remote instance.
#
# @example
#   # Deploy target defaults to the 'prod' remote instance.
#   make stack-deploy
#   # Or :
#   asc/extensions/remote/stack/deploy.sh
#
#   # Deploy to the 'dev' remote instance.
#   make stack-deploy 'dev'
#   # Or :
#   asc/extensions/remote/stack/deploy.sh 'dev'
#

p_remote_id="$1"

if [[ -z "$p_remote_id" ]]; then
  p_remote_id='prod'
fi

# TODO (wip) Detect containers that may need to be rebuilt ?
# Turn this into an abstract entry point ?
asc/extensions/remote/remote/exec.sh "$p_remote_id" \
  'git pull && asc/instance/reinit.sh && asc/instance/restart.sh'
