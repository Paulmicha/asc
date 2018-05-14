#!/usr/bin/env bash

##
# ASC instance init action.
#
# TODO [wip] document arguments.
# @see u_instance_init()
#
# @example
#   asc/instance/init.sh
#

# This action can be (re)launched after local instance was already initialized,
# and in this case, we cannot have 'readonly' variables automatically loaded
# during ASC bootstrap -> so we use that var as a flag to avoid it.
# @see asc/bootstrap.sh
ASC_BS_SKIP_GLOBALS=1

. asc/bootstrap.sh

u_instance_init "$@"
