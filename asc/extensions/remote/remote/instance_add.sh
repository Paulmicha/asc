#!/usr/bin/env bash

##
# ASC remote instance add action.
#
# @example
#   make remote-instance-add \
#     'my_short_id' \
#     'remote.instance.example.com' \
#     'stage' \
#     'my_ssh_user' \
#     '/path/to/remote/instance/docroot'
#   # Or :
#   asc/extensions/remote/remote/instance_add.sh \
#     'my_short_id' \
#     'remote.instance.example.com' \
#     'stage' \
#     'my_ssh_user' \
#     '/path/to/remote/instance/docroot'
#

. asc/bootstrap.sh
u_remote_instance_add "$@"
