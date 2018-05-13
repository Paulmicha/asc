#!/usr/bin/env bash

##
# ASC remote instance remove action.
#
# @example
#   asc/remote/instance_remove.sh 'my_short_id'
#

. asc/bootstrap.sh

# Basic sanitizing (removes characters not in . a-z A-Z 0-9 _ -).
p_id="$1"
p_id=${p_id//[^a-zA-Z0-9_\-\.]/}

conf="asc/remote/instances/${p_id}.sh"

