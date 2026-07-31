#!/usr/bin/env bash

##
# ASC remote instance destroy action.
#
# This will :
# - stop all running services on given remote instance host
# - destroy associated Docker volumes and networks
# - physically remove everything inside PROJECT_DOCROOT of given remote instance
#
# @example
#   make remote-destroy 'my_short_id'
#   # Or :
#   asc/extensions/remote_asc/remote/destroy.sh 'my_short_id'
#

. asc/bootstrap.sh

p_remote_id="$1"

u_remote_check_id "$p_remote_id"

asc/extensions/remote_asc/remote/exec.sh "$p_remote_id" \
  'asc/instance/destroy.sh && find . -delete'
