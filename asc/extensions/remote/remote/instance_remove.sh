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
p_id="$1"
p_id=${p_id//[^a-zA-Z0-9_\-\.]/}

conf="data/asc/remote-instances/${p_id}.sh"

if [[ -f "$conf" ]]; then
  rm "$conf"
fi
