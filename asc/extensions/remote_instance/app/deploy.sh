#!/usr/bin/env bash

##
# Deploys current application instance.
#
# The "app deploy" action triggers by default the "app update" action on given
# remote instance.
#
# @see asc/app/update.sh
#
# @example
#   # Deploy target defaults to the 'prod' remote instance.
#   make app-deploy
#   # Or :
#   asc/extensions/remote_asc/app/deploy.sh
#
#   # Deploy to the 'dev' remote instance.
#   make app-deploy 'dev'
#   # Or :
#   asc/extensions/remote_asc/app/deploy.sh 'dev'
#

a_remote_id="$1"

if [[ -z "$a_remote_id" ]]; then
  a_remote_id='prod'
fi

f_remote_check_id "$remote_id"

asc/extensions/remote_asc/remote/exec.sh "$a_remote_id" \
  'asc/app/update.sh'
