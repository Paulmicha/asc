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
if [[ ! "$p_id" =~ ^[a-zA-Z0-9_]+$ ]]; then
  echo "Error in $BASH_SOURCE: invalid remote ID '$p_id'." >&2
  exit 1
fi

conf="data/instance/remote/${p_id}.sh"

if [[ -e "$conf" || -L "$conf" ]]; then
  if [[ ! -f "$conf" || -L "$conf" ]] || ! grep -Fxq '# ASC generated remote instance' "$conf"; then
    echo "Error in $BASH_SOURCE: unowned remote definition '$conf'." >&2
    exit 1
  fi

  rm "$conf" || exit $?
fi

rm -f data/instance/remote_ids.sh || exit $?
