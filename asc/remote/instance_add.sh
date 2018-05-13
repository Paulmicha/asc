#!/usr/bin/env bash

##
# ASC remote instance add action.
#
# @example
#   asc/remote/instance_add.sh \
#     'my_short_id' \
#     'remote.instance.example.com' \
#     'stage' \
#     'my_ssh_user' \
#     '/path/to/remote/instance/docroot'
#

. asc/bootstrap.sh
u_remote_instance_add "$@"
