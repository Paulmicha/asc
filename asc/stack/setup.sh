#!/usr/bin/env bash

##
# Installs host-level dependencies.
#
# @requires asc/stack/init.sh (must have already been run at least once).
#
# Run as root or sudo.
#
# Usage :
# $ . asc/stack/setup.sh
#

. asc/env/load.sh

# TODO use hook instead
# @see asc/utilities/hook.sh
. asc/provision/dependencies.sh


# Allow custom complements for this script.
u_autoload_get_complement "$BASH_SOURCE"
