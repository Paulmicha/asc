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
# Expects _asc_bs_caller to be set by asc/bootstrap.sh (path of the script
# that sourced bootstrap). Empty / unset ⇒ no-op (interactive bootstrap).
#
# Sourced only from asc/bootstrap.sh (always, outside ASC_BS_FLAG).
#
# @see asc/bootstrap.sh
#

if [[ -z "${_asc_bs_caller:-}" ]]; then
  return 0 2>/dev/null || true
else
  _asc_bs_caller_dir="${_asc_bs_caller%/*}"
  _asc_bs_subject="${_asc_bs_caller_dir##*/}"
  _asc_bs_action="${_asc_bs_caller##*/}"
  _asc_bs_action="${_asc_bs_action%.sh}"

  _asc_bs_subject_opt="${_asc_bs_caller_dir}/${_asc_bs_subject}.opt-inc.sh"
  _asc_bs_action_opt="${_asc_bs_caller_dir}/${_asc_bs_action}.opt-inc.sh"

  # Source named opt-incs (override-aware). Same loop shape as phase 60 /
  # today's ASC_INC body — operand 'continue' is valid only inside this for.
  # Deduplicate when subject + action resolve to the same path.
  _asc_bs_opt_candidates=("$_asc_bs_subject_opt")
  if [[ "$_asc_bs_action_opt" != "$_asc_bs_subject_opt" ]]; then
    _asc_bs_opt_candidates+=("$_asc_bs_action_opt")
  fi

  for file in "${_asc_bs_opt_candidates[@]}"; do
    [[ -f "$file" ]] || continue
    u_autoload_override "$file" 'continue'
    if [[ -n "${inc_override_evaled_code:-}" ]]; then
      eval "$inc_override_evaled_code"
    fi
    if [[ -f "$file" ]]; then
      . "$file"
    fi
  done

  unset _asc_bs_caller_dir _asc_bs_subject _asc_bs_action \
    _asc_bs_subject_opt _asc_bs_action_opt _asc_bs_opt_candidates file
fi
