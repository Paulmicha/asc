#!/usr/bin/env bash

##
# Convenience "instance init" wrapper for default 'make' task.
#
# It is necessary to convert arguments syntax when (ab)using make the way we do.
# This "entry point" script implements a custom named arguments conversion
# syntax to "forward" them as needed - i.e. replaces '-a' by 'a:'.
#
# @see asc/instance/init.sh
# @see Makefile
# @see asc/instance/hook.make.sh
#
# @example
#   asc/instance/init.make.sh \
#     t:dev \
#     h:local \
#     p:ansible \
#     d:dev.asc.com \
#     a:dist/web \
#     g:git@my-git-origin.org:my-git-account/asc.git \
#     i:dist \
#     y:
#

formatted_args=" $@"

# Transform this script's arguments to the named arguments format expected by
# u_instance_init().
args_to_convert='o a g i t d h p c y r'
for a2c in $args_to_convert; do
  formatted_args="${formatted_args//" ${a2c}:"/" -${a2c} "}"
done

eval ". asc/instance/init.sh $formatted_args"
