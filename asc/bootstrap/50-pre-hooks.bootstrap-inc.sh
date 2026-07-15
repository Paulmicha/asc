#!/usr/bin/env bash

##
# Bootstrap phase: pre_bootstrap then alias hooks (before ASC_INC sources).
#
# Sourced only from asc/bootstrap.sh (inside ASC_BS_FLAG).
#
# @see asc/bootstrap.sh
#

# Because aliases are expanded when a function definition is read, *not* when
# the function is executed, we need to have the possibility to define aliases
# *before* the includes are sourced.
# And because aliases may depend on optionally preset variables, we trigger
# the "pre_bootstrap" hook before.
# To verify which files can be used (and will be sourced) when these hooks are
# triggered, use the following commands *in this order* :
# $ make hook-debug s:asc a:pre_bootstrap v:STACK_VERSION PROVISION_USING
# $ make hook-debug s:asc a:alias v:STACK_VERSION PROVISION_USING
# $ make hook-debug s:asc a:bootstrap v:STACK_VERSION PROVISION_USING
hook -s 'asc' -a 'pre_bootstrap' -v 'STACK_VERSION PROVISION_USING'
hook -s 'asc' -a 'alias' -v 'STACK_VERSION PROVISION_USING'
