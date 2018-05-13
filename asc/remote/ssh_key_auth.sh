#!/usr/bin/env bash

##
# ASC remote ssh key auth action.
#
# @example
#   asc/remote/ssh_key_auth.sh 'my_short_id'
#

. asc/bootstrap.sh
u_remote_authorize_ssh_key "$@"
