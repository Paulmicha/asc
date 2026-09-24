#!/usr/bin/env bash

##
# (over)Writes Shell aliases map to ASC entry points (ASC_HOST_SHELL_ALIASES).
#
# TODO [wip] must write once the one line where generated aliases are sourced :
#
# @see data/asc/aliases.sh
# @see data/asc/aliases.bash.sh
# @see data/asc/aliases.dash.sh
#
# @example
#   make host-shell-write-aliases '.bashrc'
#   make host-shell-write-aliases '.profile'
#   # Or :
#   asc/host/shell/write_aliases.sh '.bashrc'
#   asc/host/shell/write_aliases.sh '.profile'
#

p_shell_plug="$1"

# TODO
