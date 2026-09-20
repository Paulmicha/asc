#!/usr/bin/env bash

##
# Re-generates (local) remote instances definitions.
#
# @see data/asc/cache/entities/remote_instance/${REMOTE_ID}.sh
#
# @example
#   make local-setup-remotes
#   # Or :
#   asc/extensions/remote/local/setup_remotes.sh
#

. asc/bootstrap.sh

f_remote_instances_setup
