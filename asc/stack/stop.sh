#!/usr/bin/env bash

##
# Stops required services.
#
# @requires asc/stack/setup.sh (must have already been run at least once).
#
# Run as root or sudo.
#
# Usage :
# $ . asc/stack/stop.sh
#

. asc/env/load.sh

# Execute the "stop" script corresponding to provisioning method.
# TODO use hook instead
# @see asc/utilities/hook.sh
script="$(u_provisioning_get_script 'stack' 'stop')"
if [[ -f "$script" ]]; then
  . "$script"
fi


# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
