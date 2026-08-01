#!/usr/bin/env bash

##
# (Re)sets filesystem permissions.
#
# @see f_instance_set_permissions() in asc/instance/instance.inc.sh
# @see asc/instance/fs_perms_set.hook.sh
#
# @example
#   make fix-perms
#   # Or :
#   asc/instance/fix_perms.sh
#

. asc/bootstrap.sh

f_instance_set_permissions
