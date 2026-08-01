#!/usr/bin/env bash

##
# Report systemd --user loop instances (registry + is-active).
#
# @example
#   make loop-status
#   make loop-status e:blueprint-generate
#

. asc/bootstrap.sh

f_loop_monitor_enabled() {
  case "${ASC_MONITORING:-1}" in 0|false|FALSE|off|OFF) return 1 ;; esac
  case "${ASC_LOOP_MONITOR:-1}" in 0|false|FALSE|off|OFF) return 1 ;; esac
  return 0
}

f_loop_monitor_one() {
  local a_id="$1"
  local reg="data/asc/loop/${a_id}.sh"
  local unit=''
  local state=''

  if [[ ! -f "$reg" ]]; then
    echo "loop-monitor: no registry for '$a_id'"
    return 1
  fi

  # shellcheck disable=SC1090
  . "$reg"
  unit="${ASC_LOOP_UNIT:-}"
  if [[ -z "$unit" ]]; then
    echo "loop-monitor: empty unit for '$a_id'"
    return 1
  fi

  state="$(systemctl --user is-active "$unit" 2>/dev/null || echo unknown)"
  printf '%-40s %-12s %s\n' "$a_id" "$state" "$unit"
}

f_loop_monitor_default() {
  local a_filter="${1:-}"
  local f
  local id

  if ! f_loop_monitor_enabled; then
    echo "loop-monitor: skipped (ASC_MONITORING / ASC_LOOP_MONITOR off)."
    return 0
  fi

  if [[ -n "$a_filter" ]]; then
    a_filter="${a_filter#e:}"
    f_loop_monitor_one "$a_filter"
    return $?
  fi

  if [[ ! -d data/asc/loop ]]; then
    echo "loop-monitor: no registry dir."
    return 0
  fi

  printf '%-40s %-12s %s\n' 'INSTANCE' 'STATE' 'UNIT'
  shopt -s nullglob
  for f in data/asc/loop/*.sh; do
    id="${f##*/}"
    id="${id%.sh}"
    f_loop_monitor_one "$id"
  done
  shopt -u nullglob
}

f_loop_monitor_default "$@"
