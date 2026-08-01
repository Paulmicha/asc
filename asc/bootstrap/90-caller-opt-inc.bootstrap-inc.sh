#!/usr/bin/env bash

##
# Lazy-load optional includes for the bootstrap caller.
#
# Conventions (both optional; load order = shared then specific):
#   <subject_dir>/<subject>.opt-inc.sh   — all actions in that subject
#   <subject_dir>/<action>.opt-inc.sh    — that action only
#
# Eager includes remain $subject/$subject.inc.sh via ASC_INC (phase 60).
#
# Expects bootstrap_caller to be set by asc/bootstrap.sh (path of the script
# that sourced bootstrap). Empty / unset ⇒ no-op (interactive bootstrap).
#
# Sourced only from asc/bootstrap.sh (always, outside ASC_BS_FLAG).
#
# @see asc/bootstrap.sh
#

if [[ -z "${bootstrap_caller:-}" ]]; then
  return 0 2>/dev/null || true
else
  bootstrap_caller_dir="${bootstrap_caller%/*}"
  bootstrap_subject="${bootstrap_caller_dir##*/}"
  bootstrap_action="${bootstrap_caller##*/}"
  bootstrap_action="${bootstrap_action%.sh}"

  bootstrap_subject_opt="${bootstrap_caller_dir}/${bootstrap_subject}.opt-inc.sh"
  bootstrap_action_opt="${bootstrap_caller_dir}/${bootstrap_action}.opt-inc.sh"

  # Source named opt-incs (override-aware). Same loop shape as phase 60 /
  # today's ASC_INC body — operand 'continue' is valid only inside this for.
  # Deduplicate when subject + action resolve to the same path.
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
