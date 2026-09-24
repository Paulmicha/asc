#!/usr/bin/env bash

##
# (over)Writes Shell hooks to use ASC hooks.
#
# When executed as a script, bootstraps ASC then writes.
# When sourced, only defines f_shell_write_hooks().
#
# @see f_instance_init() in asc/instance/instance.inc.sh
# @see https://shell-scm.com/docs/shellhooks
#
# @example
#   make host-shell-write-hooks '.bashrc'
#   make host-shell-write-hooks '.profile'
#   # Or :
#   asc/host/shell/write_hooks.sh '.bashrc'
#   asc/host/shell/write_hooks.sh '.profile'
#

p_shell_plug="$1"
