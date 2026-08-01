#!/usr/bin/env bash

##
# ASC remote instance remove action.
#
# @example
#   make remote-instance-remove 'my_short_id'
#   # Or :
#   asc/extensions/remote/remote/instance_remove.sh 'my_short_id'
#

. asc/bootstrap.sh

# Basic sanitizing (removes characters not in . a-z A-Z 0-9 _ -).
a_id="$1"
a_id=${a_id//[^a-zA-Z0-9_\-\.]/}

conf="data/asc/remote-instances/${a_id}.sh"

if [[ -f "$conf" ]]; then
  rm "$conf"
fi
