#!/bin/bash

##
# ASC-related utility functions.
#
# This file is dynamically loaded.
# @see asc/bash_utils.sh
#

##
# [debug] Triggers ASC_ACTIONS by ASC_SUBJECTS + ASC_HOOK_TYPES.
#
# TODO fragment hooks in a predictable manner (function name convention) ?
# e.g. ${ASC_SUBJECTS}[_${ASC_HOOK_TYPES}]_${ASC_ACTIONS}() { ... }
#
# @requires the following globals in calling scope (main shell) :
# - $ASC_SUBJECTS
# - $ASC_ACTIONS
# - $ASC_HOOK_TYPES
#
# @example
#   u_asc_trigger
#
u_asc_trigger() {
  local subject
  local action
  local hook_type

  for subject in $ASC_SUBJECTS; do
    for action in $ASC_ACTIONS; do
      u_hook "$subject" "$action"
      for hook_type in $ASC_HOOK_TYPES; do
        u_hook "$subject" "$action" "$hook_type"
      done
    done
  done
}

##
# [wip] TODO wrap action calls by subject for "free" extensibility ?
#
# Idea: wrap all calls to ${ASC_SUBJECTS}[_${ASC_HOOK_TYPES}]_${ASC_ACTIONS} to
# avoid having to manually implement u_autoload_complement() or
# u_autoload_override() or u_hook() + u_hook_${ASC_SUBJECTS} every time we need
# those includes.
#
# This could theoretically allow self-contained "presets" (bunch of includes
# loosely bundled in a single dir) by temporarily prefixing current (main)
# shell's relative file path.
#
# u_asc_preset_wrapper() {
# }
