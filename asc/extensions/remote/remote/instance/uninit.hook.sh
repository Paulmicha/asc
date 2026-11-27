#!/usr/bin/env bash

##
# Implements hook -s 'instance' -a 'uninit'.
#
# Cleans up generated remote instance definitions.
# @see asc/instance/uninit.sh
#
# @example
#   make uninit
#   # Or :
#   asc/instance/uninit.sh
#

# @see asc/extensions/remote/remote.inc.sh
f_remote_purge_instances
