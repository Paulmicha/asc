#!/usr/bin/env bash

##
# Bootstrap phase: trigger the bootstrap hook.
#
# Sourced only from asc/bootstrap.sh (inside ASC_BS_FLAG).
#
# @see asc/bootstrap.sh
#

# Allow extensions to implement custom additional env. variables.
hook -s 'asc' -a 'bootstrap' -v 'STACK_VERSION PROVISION_USING'
