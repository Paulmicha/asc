#!/usr/bin/env bash

##
# Bootstraps ASC.
#
# Loads all env vars and Bash functions in the current shell scope.
#
# TODO [wip] evaluate how to improve the "lazy sourcing" (opt-inc) part.
#
# @example
#   . asc/bootstrap.sh
#

# Make sure the heavy bootstrap runs only once in current shell scope.
if [[ $ASC_BS_FLAG -ne 1 ]]; then
  ASC_BS_FLAG=1

  # Enable alias expansion in non-interactive shells.
  # NB: aliases are not expanded when the shell is not interactive, unless the
  # expand_aliases shell option is set using shopt.
  # See https://unix.stackexchange.com/a/1498
  shopt -s expand_aliases

  # Include ASC core utilities (always; do not concatenate these into active.sh).
  . asc/utils/core_utils.inc.sh
  . asc/asc/core.inc.sh
  . asc/asc/global.inc.sh
  . asc/asc/hook.inc.sh
  . asc/asc/autoload.inc.sh
  . asc/yml/yml.inc.sh

  # If instance init was run at least once, automatically load locally generated
  # global env vars.
  # This can be opted-out by setting the flag ASC_BS_SKIP_GLOBALS to 1.
  # @see asc/instance/init.sh
  if [[ $ASC_BS_SKIP_GLOBALS -ne 1 ]]; then
    if [[ -f data/asc/global.vars.sh ]]; then
      . data/asc/global.vars.sh
    fi
  fi

  # Bare vs warm is this stamp check, not a second bootstrap file.
  # Warm: core/active.sh exists and data/asc/cache/core/stamp matches discovery
  # inputs (instance identity + ignore/dir mtimes) → source primitives.
  # Cold / mismatch: f_asc_extend, rewrite active.sh + stamp, wipe hook lookup.
  # v1: pre_bootstrap / alias / bootstrap still run on both paths.
  f_asc_primitives_cache_ensure

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

  # Load additional includes (including extensions').
  if [[ -n "$ASC_INC" ]]; then
    for file in $ASC_INC; do
      # Any additional include may be overridden.
      f_autoload_override "$file" 'continue'
      if [[ -n "$inc_override_evaled_code" ]]; then
        eval "$inc_override_evaled_code"
      fi
      if [[ -f "$file" ]]; then
        . "$file"
      fi
    done
  fi

  # Allow extensions to implement custom additional env. variables.
  hook -s 'asc' -a 'bootstrap' -v 'STACK_VERSION PROVISION_USING'
fi

# Always: lazy-load optional includes for the bootstrap caller (subject + action).
bootstrap_caller=''

if [[ ${#BASH_SOURCE[@]} -gt 1 && -n "${BASH_SOURCE[1]}" ]]; then
  # BASH_SOURCE[0] is this file (bootstrap.sh); [1] is the real caller.
  bootstrap_caller="${BASH_SOURCE[1]}"
  bootstrap_caller_dir="${bootstrap_caller%/*}"
  bootstrap_subject="${bootstrap_caller_dir##*/}"
  bootstrap_action="${bootstrap_caller##*/}"
  bootstrap_action="${bootstrap_action%.sh}"
  bootstrap_subject_opt="${bootstrap_caller_dir}/${bootstrap_subject}.opt-inc.sh"
  bootstrap_action_opt="${bootstrap_caller_dir}/${bootstrap_action}.opt-inc.sh"

  # Source named opt-incs (override-aware). Deduplicate when subject + action
  # resolve to the same path.
  bootstrap_opt_candidates_arr=("$bootstrap_subject_opt")
  if [[ "$bootstrap_action_opt" != "$bootstrap_subject_opt" ]]; then
    bootstrap_opt_candidates_arr+=("$bootstrap_action_opt")
  fi

  for file in "${bootstrap_opt_candidates_arr[@]}"; do
    [[ -f "$file" ]] || continue

    f_autoload_override "$file" 'continue'

    if [[ -n "${inc_override_evaled_code:-}" ]]; then
      eval "$inc_override_evaled_code"
    fi

    if [[ -f "$file" ]]; then
      . "$file"
    fi
  done

  unset bootstrap_caller_dir bootstrap_subject bootstrap_action \
    bootstrap_subject_opt bootstrap_action_opt bootstrap_opt_candidates_arr file
fi

unset bootstrap_caller
