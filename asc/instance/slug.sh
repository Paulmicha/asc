#!/usr/bin/env bash

##
# DSL convenience string utility shortcut : slugifies all arguments.
#
# @example
#   make slug qsl--dkjq "'é(ç@à$è*'" sdl_kqjs dlqksj dq/ll
#   # Or :
#   asc/instance/slug.sh qsl--dkjq 'é(ç@à$è*' sdl_kqjs dlqksj dq/ll
#

. asc/bootstrap.sh

f_str_slug "$@"

echo "$slug_val"
