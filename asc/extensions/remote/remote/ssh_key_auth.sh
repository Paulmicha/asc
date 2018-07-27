#!/usr/bin/env bash

##
# ASC remote ssh key auth action.
#
# @example
#   make remote-ssh-key-auth 'my_short_id'
#   # Or :
#   asc/extensions/remote/remote/ssh_key_auth.sh 'my_short_id'
#

. asc/bootstrap.sh
u_remote_authorize_ssh_key "$@"
