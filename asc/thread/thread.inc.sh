#!/usr/bin/env bash

##
# Thread-related utility functions.
#
# Eager subject include (ASC_INC / bootstrap phase 60) — must stay *.inc.sh.
# Used by thread actions and cross-subject callers (log/wrap pile-up, cron
# hooks); *.opt-inc.sh would not load for those callers.
# @see asc/bootstrap.sh
# @see changelog/2026/07/16-asc-opt-inc-eager-audit.md
#
# Convention : functions names are all prefixed by "f".
#

##
# Captures a compact process ancestry as "pid:comm" strings.
#
# Outputs in calling scope :
# @var thread_tree_arr
#
# @param 1 String : starting PID.
# @param 2 [optional] Number : max depth (default 8).
#
f_thread_proc_tree() {
  local a_pid="$1"
  local a_max="${2:-8}"
  local cur="$a_pid"
  local depth=0
  local ppid
  local comm
  local stat_line

  thread_tree_arr=()

  while [[ -n "$cur" && "$cur" -gt 0 && $depth -lt $a_max ]]; do
    if [[ ! -r "/proc/$cur/stat" ]]; then
      break
    fi

    stat_line="$(</proc/$cur/stat)"
    # comm is in parentheses and may contain spaces; PPID is after the closing ).
    comm="${stat_line#*(}"
    comm="${comm%%)*}"
    # After ')': state ppid ...
    read -r _ ppid _ <<< "${stat_line##*)}"

    thread_tree_arr+=("${cur}:${comm}")

    if [[ -z "$ppid" || "$ppid" == "$cur" ]]; then
      break
    fi

    cur="$ppid"
    depth=$((depth + 1))
  done
}

##
# Writes (or overwrites) a thread lifecycle YAML file.
#
# Uses calling-scope / exported fields below when present, else empty string.
# Optional list : thread_tree_arr (array of "pid:comm").
#
# @param 1 String : make entry point name.
#
# Expected scalar sources (first match wins) :
#   ASC_THREAD_* exports, or thread_* locals, for :
#   entry owner uid euid run_as sudoing script args pid ppid started_ms status
#   exit_code ended_ms output attempt max_attempts lock_mode trigger needs_interactive
#
f_thread_yml_write() {
  local a_entry="$1"
  local a_yml
  local y_keys
  declare -A y_sc_dict=()

  a_yml="data/threads/${a_entry}.yml"
  mkdir -p data/threads

  y_sc_dict[entry]="${ASC_THREAD_ENTRY:-${thread_entry:-$a_entry}}"
  y_sc_dict[owner]="${ASC_THREAD_OWNER:-${thread_owner:-$(f_print_current_user)}}"
  y_sc_dict[uid]="${ASC_THREAD_UID:-${thread_uid:-$(id -u)}}"
  y_sc_dict[euid]="${ASC_THREAD_EUID:-${thread_euid:-${EUID:-$(id -u)}}}"
  y_sc_dict[run_as]="${ASC_THREAD_RUN_AS:-${thread_run_as:-$(id -un)}}"
  y_sc_dict[sudoing]="${ASC_THREAD_SUDOING:-${thread_sudoing:-false}}"
  y_sc_dict[script]="${ASC_THREAD_SCRIPT:-${thread_script:-}}"
  y_sc_dict[args]="${ASC_THREAD_ARGS:-${thread_args:-}}"
  y_sc_dict[pid]="${ASC_THREAD_PID:-${thread_pid:-}}"
  y_sc_dict[ppid]="${ASC_THREAD_PPID:-${thread_ppid:-}}"
  y_sc_dict[started_ms]="${ASC_THREAD_STARTED_MS:-${thread_started_ms:-}}"
  y_sc_dict[status]="${ASC_THREAD_STATUS:-${thread_status:-running}}"
  y_sc_dict[exit_code]="${ASC_THREAD_EXIT_CODE:-${thread_exit_code:-}}"
  y_sc_dict[ended_ms]="${ASC_THREAD_ENDED_MS:-${thread_ended_ms:-}}"
  y_sc_dict[output]="${ASC_THREAD_OUTPUT:-${thread_output:-}}"
  y_sc_dict[attempt]="${ASC_THREAD_ATTEMPT:-${thread_attempt:-}}"
  y_sc_dict[max_attempts]="${ASC_THREAD_MAX_ATTEMPTS:-${thread_max_attempts:-}}"
  y_sc_dict[lock_mode]="${ASC_THREAD_LOCK_MODE:-${thread_lock_mode:-skip}}"
  y_sc_dict[trigger]="${ASC_THREAD_TRIGGER:-${thread_trigger:-manual}}"
  y_sc_dict[needs_interactive]="${ASC_THREAD_NEEDS_INTERACTIVE:-${thread_needs_interactive:-false}}"

  y_keys=(
    entry owner uid euid run_as sudoing script args pid ppid started_ms status
    exit_code ended_ms output attempt max_attempts lock_mode trigger
    needs_interactive
  )

  if [[ ${#thread_tree_arr[@]} -eq 0 && -n "${ASC_THREAD_TREE:-}" ]]; then
    mapfile -t thread_tree_arr <<< "${ASC_THREAD_TREE}"
  fi

  if [[ ${#thread_tree_arr[@]} -gt 0 ]]; then
    f_yaml_write "$a_yml" y_sc_dict y_keys tree thread_tree_arr
  else
    f_yaml_write "$a_yml" y_sc_dict y_keys
  fi

  # Host sibling index (no-op when ASC_MONITORING / ASC_HOST_THREAD_MONITOR off).
  f_thread_host_publish "$a_entry"
}

##
# Loads a thread YAML record into thread_* variables (calling scope / shell).
#
# @param 1 String : make entry point name.
#
# @example
#   f_thread_yml_load 'transcribe-all'
#   echo "$thread_pid $thread_status"
#
f_thread_yml_load() {
  local a_entry="$1"
  local a_yml="data/threads/${a_entry}.yml"

  if [[ ! -f "$a_yml" ]]; then
    return 1
  fi

  # bash-yaml uses += for lists; clear before reload.
  unset thread_tree_arr

  eval "$(f_yaml_parse "$a_yml" 'thread_')"
  f_thread_yml_strip_quotes
}

##
# Marks a loaded thread record as stale and rewrites its YAML.
#
# Requires a prior successful f_thread_yml_load (thread_* vars set).
# Strips yaml-parser quote artifacts before rewrite.
#
f_thread_yml_mark_stale() {
  local a_entry="${thread_entry:-}"

  if [[ -z "$a_entry" ]]; then
    return 1
  fi

  f_thread_yml_strip_quotes

  thread_status='stale'
  ASC_THREAD_ENTRY="$thread_entry"
  ASC_THREAD_OWNER="$thread_owner"
  ASC_THREAD_UID="$thread_uid"
  ASC_THREAD_EUID="${thread_euid:-}"
  ASC_THREAD_RUN_AS="${thread_run_as:-}"
  ASC_THREAD_SUDOING="${thread_sudoing:-false}"
  ASC_THREAD_SCRIPT="$thread_script"
  ASC_THREAD_ARGS="$thread_args"
  ASC_THREAD_PID="$thread_pid"
  ASC_THREAD_PPID="$thread_ppid"
  ASC_THREAD_STARTED_MS="$thread_started_ms"
  ASC_THREAD_STATUS='stale'
  ASC_THREAD_EXIT_CODE="${thread_exit_code:-}"
  ASC_THREAD_ENDED_MS="${thread_ended_ms:-}"
  ASC_THREAD_OUTPUT="${thread_output:-}"
  ASC_THREAD_ATTEMPT="${thread_attempt:-}"
  ASC_THREAD_MAX_ATTEMPTS="${thread_max_attempts:-}"
  ASC_THREAD_LOCK_MODE="${thread_lock_mode:-skip}"
  ASC_THREAD_TRIGGER="${thread_trigger:-manual}"
  ASC_THREAD_NEEDS_INTERACTIVE="${thread_needs_interactive:-false}"

  if [[ ${#thread_tree_arr[@]} -gt 0 ]]; then
    ASC_THREAD_TREE="$(printf '%s\n' "${thread_tree_arr[@]}")"
  fi

  f_thread_yml_write "$a_entry"
}

##
# Strip surrounding quotes left on scalars by bash-yaml parse round-trips.
#
f_thread_yml_strip_quotes() {
  local v
  local k

  for k in entry owner uid euid run_as sudoing script args pid ppid started_ms \
    status exit_code ended_ms output attempt max_attempts lock_mode trigger \
    needs_interactive; do
    v="thread_${k}"
    if [[ -n "${!v:-}" ]]; then
      printf -v "$v" '%s' "${!v#\"}"
      printf -v "$v" '%s' "${!v%\"}"
    fi
  done

  if [[ ${#thread_tree_arr[@]} -gt 0 ]]; then
    local i
    for i in "${!thread_tree_arr[@]}"; do
      thread_tree_arr[$i]="${thread_tree_arr[$i]#\"}"
      thread_tree_arr[$i]="${thread_tree_arr[$i]%\"}"
    done
  fi
}

##
# EXIT trap for supervised thread jobs — writes final status to YAML.
#
# Relies on ASC_THREAD_* exports set by the supervisor before the wrapped
# script runs (same subshell). Does not reload YAML (avoids quote round-trips).
#
# @param 1 Number : exit code of the wrapped script.
#
f_thread_supervisor_exit() {
  local a_rc="$1"

  ASC_THREAD_STATUS='exited'
  ASC_THREAD_EXIT_CODE="$a_rc"
  ASC_THREAD_ENDED_MS="$(date +%Y-%m-%dT%H:%M:%S.%3N)"

  # Common "needs TTY / interactive input" signals.
  case "$a_rc" in
    75|126|130)
      ASC_THREAD_NEEDS_INTERACTIVE='true'
      ;;
  esac

  if [[ -n "${ASC_THREAD_TREE:-}" ]]; then
    mapfile -t thread_tree_arr <<< "${ASC_THREAD_TREE}"
  fi

  f_thread_yml_write "${ASC_THREAD_ENTRY}"

  # Release flock if held on fd 9.
  if { true >&9; } 2>/dev/null; then
    flock -u 9 2>/dev/null || true
  fi
}

##
# Chown path to invoking human when sudoing (S1).
#
f_thread_chown_human() {
  local a_path="$1"

  if [[ ! -e "$a_path" ]]; then
    return 0
  fi

  if [[ -n "${SUDO_USER:-}" ]]; then
    chown "$SUDO_USER:" "$a_path" 2>/dev/null || true
  fi
}

##
# Pile-up check: return 0 if safe to start, 1 if should skip (already running).
#
f_thread_pileup_should_skip() {
  local a_entry="$1"
  local yml="data/threads/${a_entry}.yml"

  if [[ ! -f "$yml" ]]; then
    return 1
  fi

  if ! f_thread_yml_load "$a_entry"; then
    return 1
  fi

  if [[ "$thread_status" == 'running' ]]; then
    if kill -0 "$thread_pid" 2>/dev/null; then
      return 0
    fi
    f_thread_yml_mark_stale
  fi

  return 1
}

##
# Acquire non-blocking flock for entry; skip/wait per lock mode.
#
# Uses fd 9. Returns 0 on lock acquired, 1 on skip.
#
f_thread_lock_acquire() {
  local a_entry="$1"
  local a_mode="${2:-skip}"
  local lock="data/threads/${a_entry}.lock"

  mkdir -p data/threads
  eval "exec 9>\"$lock\""
  f_thread_chown_human "$lock"

  case "$a_mode" in
    wait)
      flock 9 || return 1
      ;;
    *)
      if ! flock -n 9; then
        return 1
      fi
      ;;
  esac

  return 0
}

##
# Parse delay like 10s / 2m into integer seconds (echo).
#
f_thread_delay_seconds() {
  local d="${1:-10s}"
  if [[ "$d" =~ ^([0-9]+)s$ ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [[ "$d" =~ ^([0-9]+)m$ ]]; then
    echo $((BASH_REMATCH[1] * 60))
  elif [[ "$d" =~ ^([0-9]+)h$ ]]; then
    echo $((BASH_REMATCH[1] * 3600))
  elif [[ "$d" =~ ^[0-9]+$ ]]; then
    echo "$d"
  else
    echo 10
  fi
}

##
# Last modification time of a file (ISO ms), or empty if missing.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
# The default variable name is overridable : see arg 2.
#
# @param 1 String : file path.
# @param 2 [optional] String : variable name in calling scope for the result.
#   Defaults to : 'thread_output_mtime_ms'.
#
# @example
#   f_thread_output_mtime_ms 'data/logs/foo.txt'
#   echo "$thread_output_mtime_ms"
#
f_thread_output_mtime_ms() {
  local a_file="$1"
  local a_var_name="$2"

  if [[ -z "$a_var_name" ]]; then
    a_var_name='thread_output_mtime_ms'
  fi

  if [[ ! -f "$a_file" ]]; then
    printf -v "$a_var_name" '%s' ''
    return 1
  fi

  printf -v "$a_var_name" '%s' \
    "$(date -r "$a_file" '+%Y-%m-%dT%H:%M:%S.%3N' 2>/dev/null || true)"
}

##
# Host sibling index directory ($HOME/.local/share/asc/threads).
#
# Writes thread_host_index_dir in calling scope.
#
f_thread_host_index_dir() {
  local home="${HOME:-}"
  if [[ -z "$home" ]]; then
    home="$(getent passwd "${SUDO_USER:-$(id -un)}" 2>/dev/null | cut -d: -f6 || true)"
  fi
  if [[ -z "$home" ]]; then
    home='/tmp'
  fi
  thread_host_index_dir="${home}/.local/share/asc/threads"
}

##
# True when host thread monitoring / publish is enabled.
#
f_thread_host_monitor_enabled() {
  case "${ASC_MONITORING:-1}" in 0|false|FALSE|off|OFF) return 1 ;; esac
  case "${ASC_HOST_THREAD_MONITOR:-1}" in 0|false|FALSE|off|OFF) return 1 ;; esac
  return 0
}

##
# Publish (or update) one entry in the host sibling index.
#
# Safe no-op when monitoring env gates are off. Filename encodes a stable hash
# of docroot+entry so nested instances do not collide.
#
# @param 1 String : make entry name.
#
f_thread_host_publish() {
  local a_entry="$1"
  local docroot
  local slug
  local host_file
  local y_keys
  declare -A y_sc_dict=()

  if [[ -z "$a_entry" ]]; then
    return 1
  fi

  if ! f_thread_host_monitor_enabled; then
    return 0
  fi

  docroot="${PROJECT_DOCROOT:-$(pwd)}"
  f_thread_host_index_dir
  mkdir -p "$thread_host_index_dir"

  slug="$(printf '%s\n' "${docroot}::${a_entry}" | sha256sum | awk '{print $1}')"
  slug="${slug:0:16}"
  host_file="${thread_host_index_dir}/${slug}.yml"

  y_sc_dict[docroot]="$docroot"
  y_sc_dict[entry]="${ASC_THREAD_ENTRY:-$a_entry}"
  y_sc_dict[pid]="${ASC_THREAD_PID:-${thread_pid:-}}"
  y_sc_dict[status]="${ASC_THREAD_STATUS:-${thread_status:-}}"
  y_sc_dict[owner]="${ASC_THREAD_OWNER:-${thread_owner:-}}"
  y_sc_dict[mtime]="$(date +%Y-%m-%dT%H:%M:%S.%3N)"
  y_sc_dict[trigger]="${ASC_THREAD_TRIGGER:-${thread_trigger:-manual}}"
  y_keys=(docroot entry pid status owner mtime trigger)

  f_yaml_write "$host_file" y_sc_dict y_keys
}

##
# Composition helpers: parse e:/a:/join:/workers: and run sequence / batch / pipe.
#
# Shared calling-scope outputs (parsers) :
#   thread_join, thread_max_workers
#   thread_entries_arr[], thread_entry_args_arr[]   (args are printf-%q encoded)
#   thread_stage_kind_arr[], thread_stage_value_arr[], thread_stage_args_arr[]  (pipe)
#

##
# Appends one printf-%q encoded arg to thread_entry_args_arr[idx] (or stage args).
#
f_thread_args_append() {
  local a_arr_name="$1"
  local a_idx="$2"
  local a_val="$3"
  local enc
  local -n _u_ta_ref_arr_nameref="$a_arr_name"

  printf -v enc '%q' "$a_val"
  if [[ -n "${_u_ta_ref_arr_nameref[$a_idx]}" ]]; then
    _u_ta_ref_arr_nameref[$a_idx]+=" $enc"
  else
    _u_ta_ref_arr_nameref[$a_idx]="$enc"
  fi
}

##
# Runs: make <entry> [decoded args…]
#
# @param 1 String : make entry.
# @param 2 String : printf-%q encoded args (may be empty).
#
f_thread_run_make_step() {
  local a_entry="$1"
  local a_encoded="$2"
  local -a args_arr=()
  local found=0
  local e=''

  # Reject unknown entries: Makefile has a silent catch-all (%:) that would
  # otherwise make missing goals look successful.
  if [[ -f data/asc/cache/make.sh ]]; then
    # Fresh arrays (cache uses +=).
    make_entries_arr=()
    real_scripts_arr=()
    . data/asc/cache/make.sh
    for e in "${make_entries_arr[@]}"; do
      if [[ "$e" == "$a_entry" ]]; then
        found=1
        break
      fi
    done
    if [[ $found -ne 1 ]]; then
      echo >&2 "Error: unknown make entry '$a_entry'."
      return 127
    fi
  fi

  if [[ -n "$a_encoded" ]]; then
    # shellcheck disable=SC2086
    eval "args_arr=($a_encoded)"
  fi

  make "$a_entry" "${args_arr[@]}"
}

##
# Parses sequence/batch argv into thread_entries_arr / thread_entry_args_arr + kwargs.
#
# Accepts: e:<entry>, e:<N>:<entry>, a:<arg>, join:&&|;, workers:<N>
# Bare tokens (no known prefix) are treated as entry names (compat).
#
# @return 1 on parse error (e.g. a: before any e:).
#
f_thread_parse_e_args() {
  thread_join="${ASC_THREAD_JOIN:-&&}"
  thread_max_workers="${ASC_THREAD_MAX_WORKERS:-4}"
  thread_entries_arr=()
  thread_entry_args_arr=()

  local arg=''
  local entry=''
  local rest=''
  local current=-1

  for arg in "$@"; do
    case "$arg" in
      join:*)
        thread_join="${arg#join:}"
        ;;
      workers:*)
        thread_max_workers="${arg#workers:}"
        ;;
      a:*)
        if [[ $current -lt 0 ]]; then
          echo >&2 "Error: a: arg before any e: entry ($arg)."
          return 1
        fi
        f_thread_args_append thread_entry_args_arr "$current" "${arg#a:}"
        ;;
      e:*)
        rest="${arg#e:}"
        case "$rest" in
          [0-9]*:*)
            entry="${rest#*:}"
            ;;
          *)
            entry="$rest"
            ;;
        esac
        if [[ -z "$entry" ]]; then
          echo >&2 "Error: empty e: entry ($arg)."
          return 1
        fi
        thread_entries_arr+=("$entry")
        thread_entry_args_arr+=('')
        current=$((${#thread_entries_arr[@]} - 1))
        ;;
      *)
        # Bare make entry (compat with older batch/sequence call sites).
        thread_entries_arr+=("$arg")
        thread_entry_args_arr+=('')
        current=$((${#thread_entries_arr[@]} - 1))
        ;;
    esac
  done

  if [[ ${#thread_entries_arr[@]} -eq 0 ]]; then
    echo >&2 "Error: at least one e:<entry> (or bare entry) is required."
    return 1
  fi

  case "$thread_join" in
    '&&'|';') ;;
    *)
      echo >&2 "Error: invalid join:'$thread_join' (use && or ;)."
      return 1
      ;;
  esac

  if [[ ! "$thread_max_workers" =~ ^[0-9]+$ ]]; then
    echo >&2 "Error: workers must be a number (got '$thread_max_workers')."
    return 1
  fi
  if (( thread_max_workers < 1 )); then
    thread_max_workers=1
  elif (( thread_max_workers > 32 )); then
    thread_max_workers=32
  fi

  return 0
}

##
# Parses pipe argv: shell strings and/or e:/a: make stages.
#
# @var thread_stage_kind_arr[]  make|shell
# @var thread_stage_value_arr[] entry or shell command string
# @var thread_stage_args_arr[]  encoded make args
#
# @return 1 on parse error.
#
f_thread_parse_pipe_stages() {
  thread_stage_kind_arr=()
  thread_stage_value_arr=()
  thread_stage_args_arr=()

  local arg=''
  local entry=''
  local rest=''
  local current=-1

  for arg in "$@"; do
    case "$arg" in
      a:*)
        if [[ $current -lt 0 ]]; then
          echo >&2 "Error: a: before any pipe stage ($arg)."
          return 1
        fi
        if [[ "${thread_stage_kind_arr[$current]}" != 'make' ]]; then
          echo >&2 "Error: a: only applies to make stages ($arg)."
          return 1
        fi
        f_thread_args_append thread_stage_args_arr "$current" "${arg#a:}"
        ;;
      e:*)
        rest="${arg#e:}"
        case "$rest" in
          [0-9]*:*) entry="${rest#*:}" ;;
          *) entry="$rest" ;;
        esac
        if [[ -z "$entry" ]]; then
          echo >&2 "Error: empty e: entry ($arg)."
          return 1
        fi
        thread_stage_kind_arr+=('make')
        thread_stage_value_arr+=("$entry")
        thread_stage_args_arr+=('')
        current=$((${#thread_stage_kind_arr[@]} - 1))
        ;;
      join:*|workers:*)
        echo >&2 "Error: $arg is not valid for pipe (use sequence/batch)."
        return 1
        ;;
      *)
        # Positional shell stage.
        thread_stage_kind_arr+=('shell')
        thread_stage_value_arr+=("$arg")
        thread_stage_args_arr+=('')
        current=$((${#thread_stage_kind_arr[@]} - 1))
        ;;
    esac
  done

  if (( ${#thread_stage_kind_arr[@]} < 2 )); then
    echo >&2 "Error: pipe requires at least 2 stages."
    return 1
  fi

  return 0
}

##
# Runs parsed sequence (thread_entries_arr) with join && or ;.
#
# @return step rc (&& fail-fast) or worst nonzero (;).
#
f_thread_run_sequence() {
  local i
  local rc=0
  local worst=0

  for i in "${!thread_entries_arr[@]}"; do
    f_thread_run_make_step "${thread_entries_arr[$i]}" "${thread_entry_args_arr[$i]}"
    rc=$?
    if (( rc == 0 )); then
      continue
    fi
    if [[ "$thread_join" == '&&' ]]; then
      return "$rc"
    fi
    if (( rc > worst )); then
      worst=$rc
    fi
  done

  return "$worst"
}

##
# Runs parsed batch with wave barriers (thread_max_workers) and wait; exit worst.
#
f_thread_run_batch() {
  local i=0
  local n=${#thread_entries_arr[@]}
  local workers=$thread_max_workers
  local worst=0
  local w
  local pid
  local brc
  local -a pids_arr=()

  if (( workers < 1 )); then workers=1; fi
  if (( workers > 32 )); then workers=32; fi

  while (( i < n )); do
    pids=()
    w=0
    while (( i < n && w < workers )); do
      (
        f_thread_run_make_step "${thread_entries_arr[$i]}" "${thread_entry_args_arr[$i]}"
      ) &
      pids_arr+=($!)
      i=$((i + 1))
      w=$((w + 1))
    done
    for pid in "${pids_arr[@]}"; do
      wait "$pid"
      brc=$?
      if (( brc == 0 )); then
        continue
      fi
      if (( brc > worst )); then
        worst=$brc
      fi
    done
  done

  return "$worst"
}

##
# Runs parsed pipe stages under pipefail.
#
f_thread_run_pipe() {
  local i
  local n=${#thread_stage_kind_arr[@]}
  local cmd=''
  local part=''
  local qentry=''

  set -o pipefail

  for ((i = 0; i < n; i++)); do
    if [[ "${thread_stage_kind_arr[$i]}" == 'make' ]]; then
      printf -v qentry '%q' "${thread_stage_value_arr[$i]}"
      part="make $qentry"
      if [[ -n "${thread_stage_args_arr[$i]}" ]]; then
        part+=" ${thread_stage_args_arr[$i]}"
      fi
    else
      printf -v qentry '%q' "${thread_stage_value_arr[$i]}"
      part="bash -c -- $qentry"
    fi
    if [[ -n "$cmd" ]]; then
      cmd+=' | '
    fi
    cmd+="{ $part ; }"
  done

  eval "$cmd"
}
