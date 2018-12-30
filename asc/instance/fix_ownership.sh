#!/usr/bin/env bash

##
# (Re)sets filesystem ownership.
#
# @see u_instance_set_ownership() in asc/instance/instance.inc.sh
# @see asc/instance/fs_ownership_set.hook.sh
#
# @example
#   sudo make fix_ownership
#   # Or :
#   sudo asc/instance/fix_ownership.sh
#

. asc/bootstrap.sh

u_instance_set_ownership
