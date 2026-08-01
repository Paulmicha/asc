#!/usr/bin/env bash

##
# Re-generates (local) remote instances definitions.
#
# @see data/asc/remote-instances/${REMOTE_ID}.sh
#
# @example
#   make local-setup-remotes
#   # Or :
#   asc/extensions/remote/local/setup_remotes.sh
#

. asc/bootstrap.sh

f_remote_instances_setup
