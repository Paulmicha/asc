#!/usr/bin/env bash

##
# (Re)sets filesystem permissions.
#
# @see u_instance_set_permissions() in asc/instance/instance.inc.sh
# @see asc/instance/fs_perms_set.hook.sh
#
# @example
#   make fix_perms
#   # Or :
#   asc/instance/fix_perms.sh
#

. asc/bootstrap.sh

u_instance_set_permissions
