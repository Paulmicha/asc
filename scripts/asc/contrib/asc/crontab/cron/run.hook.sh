#!/usr/bin/env bash

##
# Implements hook -s 'cron' -a 'run'
#
# Default cron runner: honor ASC_CRON_* exports, apply wrap/lock, execute.
# @see asc/extensions/cron/cron/run.sh
#

if ! f_crontab_entry_load "$p_entry"; then
  # Attempt regenerate once if missing.
  f_crontab_settings_setup || true
  if ! f_crontab_entry_load "$p_entry"; then
    echo >&2 "Error: no generated cron definition for '$p_entry'."
    echo >&2 'Add a $ext/$subject/$action.$preset.cron.yml beside the entry script, then reinit.'
    exit 1
  fi
fi

if [[ "${ASC_CRON_ENABLED}" != 'true' ]]; then
  echo "Cron entry '$p_entry' is disabled; skipping."
  exit 0
fi


f_crontab_run_default() {
  local cmd
  local lock_mode="${ASC_CRON_LOCK:-skip}"
  local entry="${ASC_CRON_ENTRY:-}"
  local yml="data/threads/${entry}.yml"
  local run_id="${ASC_CRON_RUN:-}"
  local interval="${ASC_CRON_SUBMINUTE:-}"
  local runs=1
  local run_index=0

  # Thread-monitor style extras (optional).
  case "${ASC_CRON_MONITOR_MARK_STALE:-}" in true|TRUE|1)
    if [[ -f "$yml" ]] && f_thread_yml_load "$entry"; then
      if [[ "$thread_status" == 'running' ]] && ! kill -0 "$thread_pid" 2>/dev/null; then
        f_thread_yml_mark_stale
        echo "Marked stale: $entry (PID $thread_pid)"
      fi
    fi
  esac

  case "$run_id" in thread-monitor)
    case "${ASC_MONITORING:-1}" in 0|false|FALSE|off|OFF)
      echo "Cron thread-monitor: skipped (ASC_MONITORING=0)."
      return 0
      ;;
    esac
    case "${ASC_HOST_THREAD_MONITOR:-1}" in 0|false|FALSE|off|OFF)
      echo "Cron thread-monitor: skipped (ASC_HOST_THREAD_MONITOR=0)."
      return 0
      ;;
    esac
    hook_ms 'dry-run' -s 'thread' -a 'monitor' \
      -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'
    if [[ -n "${most_specific_match:-}" && -f "$most_specific_match" ]]; then
      # shellcheck disable=SC1090
      . "$most_specific_match"
    else
      echo >&2 "Error: no thread/monitor hook found."
      return 1
    fi
    return $?
    ;;
  esac

  # Pile-up: skip if thread still running.
  case "$lock_mode" in skip)
    if [[ -n "$entry" && -f "$yml" ]] && f_thread_yml_load "$entry"; then
      if [[ "$thread_status" == 'running' ]] && kill -0 "$thread_pid" 2>/dev/null; then
        echo "Cron skip: '$entry' already running (PID $thread_pid)."
        return 0
      fi
    fi
    ;;
  esac

  export ASC_WRAP_RETRY_MAX="${ASC_CRON_RETRY_MAX:-0}"
  export ASC_WRAP_RETRY_DELAY="${ASC_CRON_RETRY_DELAY:-10s}"
  export ASC_WRAP_NONINTERACTIVE=1
  export GIT_TERMINAL_PROMPT=0

  cmd="${ASC_CRON_CMD:-}"
  if [[ -z "$cmd" ]]; then
    echo >&2 "Error: ASC_CRON_CMD empty for entry '$entry'."
    return 1
  fi

  echo "Cron run: $cmd"

  # Empty or whole-minute values run once per crontab tick. A shorter interval
  # that divides 60 repeats inside that tick.
  if [[ "$interval" =~ ^[0-9]+$ ]] && [[ "$interval" -gt 0 ]] && [[ "$interval" -lt 60 ]] && [[ $((60 % interval)) -eq 0 ]]; then
    runs=$((60 / interval))
  fi

  while [[ "$run_index" -lt "$runs" ]]; do
    if [[ "$run_index" -gt 0 ]]; then
      sleep "$interval" || return $?
    fi

    eval "$cmd" || return $?
    run_index=$((run_index + 1))
  done
}

f_crontab_run_default
