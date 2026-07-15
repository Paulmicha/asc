#!/usr/bin/env bash

##
# Custom Make entry point to forward all arguments to remote drush calls.
#
# Requires the "remote" ASC extension to be enabled.
# @see asc/extensions/remote/remote/exec.sh
#
# @example
#   make remote-drush 'prod' st
#   make remote-drush 'prod' uli
#   make remote-drush 'prod' ev 'print "hello from Drupal php";'
#   # Or :
#   asc/extensions/drush/remote/drush.sh 'prod' st
#   asc/extensions/drush/remote/drush.sh 'prod' uli
#   asc/extensions/drush/remote/drush.sh 'prod' ev 'print "hello from Drupal php";'
#

. asc/bootstrap.sh

remote_id="$1"
u_remote_check_id "$remote_id"
shift

if [[ -z "$1" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: missing at least 1 argument (the remote drush command to exec) after arg 1 (the remote ID)." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

domain=''
u_remote_definition_get_key "$remote_id" 'domain'

if [[ -n "$domain" ]]; then
  u_remote_exec_wrapper "$remote_id" drush --uri="$domain" $@
else
  u_remote_exec_wrapper "$remote_id" drush $@
fi
