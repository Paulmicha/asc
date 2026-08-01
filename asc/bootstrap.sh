#!/usr/bin/env bash

##
# Bootstraps ASC.
#
# Thin orchestrator: sources numbered phase includes under asc/bootstrap/.
# Phases 10–70 run once per shell (ASC_BS_FLAG). Phase 90 (caller opt-inc)
# runs on every source so a second `. bootstrap` in an already-bootstrapped
# shell still loads the caller’s lazy helpers.
#
# Phase convention:
#   asc/bootstrap/*.bootstrap-inc.sh — core phases only (not on ASC_INC)
# Eager includes:   $subject/$subject.inc.sh (and $ext/$ext.inc.sh) → ASC_INC
# Lazy (phase 90):  $subject/$subject.opt-inc.sh then $subject/$action.opt-inc.sh
#
# @example
#   . asc/bootstrap.sh
#
# @see asc/bootstrap/
#

# Make sure the heavy bootstrap runs only once in current shell scope.
if [[ $ASC_BS_FLAG -ne 1 ]]; then
  ASC_BS_FLAG=1

  . asc/bootstrap/10-shell.bootstrap-inc.sh
  . asc/bootstrap/20-utilities.bootstrap-inc.sh
  . asc/bootstrap/30-globals.bootstrap-inc.sh
  . asc/bootstrap/40-primitives.bootstrap-inc.sh
  . asc/bootstrap/50-pre-hooks.bootstrap-inc.sh
  . asc/bootstrap/60-includes.bootstrap-inc.sh
  . asc/bootstrap/70-bootstrap-hook.bootstrap-inc.sh
fi

# Always: lazy-load optional includes for the bootstrap caller (subject + action).
_asc_bs_caller=''
if [[ ${#BASH_SOURCE[@]} -gt 1 && -n "${BASH_SOURCE[1]}" ]]; then
  # BASH_SOURCE[0] is this file (bootstrap.sh); [1] is the real caller.
  _asc_bs_caller="${BASH_SOURCE[1]}"
fi
. asc/bootstrap/90-caller-opt-inc.bootstrap-inc.sh
unset _asc_bs_caller
