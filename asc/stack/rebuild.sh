#!/usr/bin/env bash

##
# Rebuilds required services.
#
# @requires asc/stack/setup.sh (must have already been run at least once).
#
# Run as root or sudo.
#
# Usage :
# $ . asc/stack/rebuild.sh
#

. asc/env/load.sh

. asc/stack/stop.sh

# Execute the "rebuild" script corresponding to provisioning method.
# TODO use hook instead
# @see asc/utilities/hook.sh
script="$(u_provisioning_get_script 'stack' 'rebuild')"
if [[ -f "$script" ]]; then
  . "$script"
fi

. asc/stack/start.sh

# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
