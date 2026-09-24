#!/usr/bin/env bash

##
# (over)Writes Shell hooks to use ASC hooks.
#
# TODO [wip] must write once the one line where generated aliases are sourced :
#
# @see data/asc/aliases.sh
# @see data/asc/aliases.bash.sh
# @see data/asc/aliases.dash.sh
#
# @example
#   make host-shell-write-hooks '.bashrc'
#   make host-shell-write-hooks '.profile'
#   # Or :
#   asc/host/shell/write_hooks.sh '.bashrc'
#   asc/host/shell/write_hooks.sh '.profile'
#

p_shell_plug="$1"

# TODO
