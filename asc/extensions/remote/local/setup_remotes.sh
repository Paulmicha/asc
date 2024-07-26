#!/usr/bin/env bash

##
# Re-generates (local) remote instances definitions.
#
# @see scripts/asc/local/remote-instances/${REMOTE_ID}.sh
#
# @example
#   make local-setup-remotes
#   # Or :
#   asc/extensions/remote/local/setup_remotes.sh
#

. asc/bootstrap.sh

u_remote_instances_setup
