#!/usr/bin/env bash

##
# DSL convenience string utility shortcut : snakifies all arguments.
#
# @example
#   make snake qsl--dkjq "'é(ç@à$è*'" sdl_kqjs dlqksj dq/ll
#   # Or :
#   asc/instance/snake.sh qsl--dkjq 'é(ç@à$è*' sdl_kqjs dlqksj dq/ll
#

. asc/bootstrap.sh

if ! type f_str_snake &>/dev/null; then
  # shellcheck disable=SC1091
  . asc/core/utils/str.opt-inc.sh
fi

f_str_snake "$@"

echo "$snake_val"
