#!/usr/bin/env bash

##
# Thread wrapper to run a make entry point in the background.
#
# Backgrounds the wrapped command under a supervised subshell that records
# lifecycle data in data/threads/{entrypoint}.yml. Output capture is log-wrap's
# job when composed via logged-thread (asc/log/log.wrap.sh asc/thread/thread.wrap.sh …).
#
# Supports pile-up skip (flock + YAML), optional inner retry, dual identity when
# sudoing, and noninteractive stdin (/dev/null).
#
# @param 1 String : make entry point name or path to wrapped script.
#
# @example
#   make thread-wrap e:transcribe-all
#   asc/thread/thread.wrap.sh transcribe-all
#

. asc/bootstrap.sh

a_script="$1"
shift

a_is_wrapper=0
thread_file="$a_script"

if [[ "$a_script" == *'log.wrap.sh' ]]; then
  a_is_wrapper=1
  thread_file="$1"
fi

# Restrict to make entry points, and convert scripts paths to entry points names.
make_entries_arr=()
real_scripts_arr=()
is_thread_file_valid=0

f_make_list_entry_points

for index in "${!real_scripts_arr[@]}"; do
  task="${make_entries_arr[index]}"
  script="${real_scripts_arr[index]}"

  case "$thread_file" in "$script")
    thread_file="${thread_file/$script/$task}"
    is_thread_file_valid=1
    continue
  esac

  if [[ $a_is_wrapper -eq 0 ]]; then
    case "$thread_file" in "$task")
      a_script="$script"
      is_thread_file_valid=1
    esac
  else
    case "$thread_file" in "$task")
      is_thread_file_valid=1
    esac
  fi
done

if [[ $is_thread_file_valid -ne 1 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - only supports valid make entry points." >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

a_entry="${thread_file#e:}"
a_script_real="$(realpath -e "$a_script")"

# Refuse interactive-required scripts under wrap.
if grep -q '@requires interactive' "$a_script_real" 2>/dev/null; then
  echo >&2 "Error: '$a_entry' requires an interactive shell; refuse wrap."
  echo >&2 "Run in the foreground: make $a_entry"
  exit 1
fi

# Fast-fail @requires sudoing without root.
if grep -q '@requires sudoing' "$a_script_real" 2>/dev/null; then
  if [[ "$(id -u)" -ne 0 ]]; then
    echo >&2 "Error: '$a_entry' requires sudoing / root; refuse wrap as uid $(id -u)."
    echo >&2 "Example: sudo make lt e:$a_entry"
    exit 1
  fi
fi

a_args="$*"
a_owner="$(f_print_current_user)"
a_uid="$(id -u)"
a_euid="${EUID:-$a_uid}"
a_run_as="$(id -un)"
a_sudoing='false'
if [[ -n "${SUDO_USER:-}" ]] || [[ "$a_euid" -eq 0 && "$a_owner" != "$a_run_as" ]]; then
  a_sudoing='true'
fi
if [[ -n "${SUDO_USER:-}" ]]; then
  a_owner="$SUDO_USER"
fi

a_started_ms="$(date +%Y-%m-%dT%H:%M:%S.%3N)"
a_lock_mode="${ASC_THREAD_LOCK_MODE:-skip}"
a_retry_max="${ASC_WRAP_RETRY_MAX:-0}"
a_retry_delay="${ASC_WRAP_RETRY_DELAY:-10s}"
a_trigger="${ASC_THREAD_TRIGGER:-manual}"

if [[ -n "${ASC_LOG_WRAP_ACTIVE:-}" ]]; then
  a_output="data/logs/${a_entry}.txt"
else
  a_output='nohup.out'
fi

mkdir -p data/threads

# Pile-up prevention (P1 + P5) via YAML/PID before backgrounding.
if f_thread_pileup_should_skip "$a_entry"; then
  echo "Thread '$a_entry' already running (PID $thread_pid); skip."
  exit 0
fi

export ASC_WRAP_NONINTERACTIVE=1
export GIT_TERMINAL_PROMPT=0

export ASC_THREAD_ENTRY="$a_entry"
export ASC_THREAD_OWNER="$a_owner"
export ASC_THREAD_UID="$a_uid"
export ASC_THREAD_EUID="$a_euid"
export ASC_THREAD_RUN_AS="$a_run_as"
export ASC_THREAD_SUDOING="$a_sudoing"
export ASC_THREAD_SCRIPT="$a_script_real"
export ASC_THREAD_ARGS="$a_args"
export ASC_THREAD_STARTED_MS="$a_started_ms"
export ASC_THREAD_OUTPUT="$a_output"
export ASC_THREAD_STATUS='running'
export ASC_THREAD_EXIT_CODE=''
export ASC_THREAD_ENDED_MS=''
export ASC_THREAD_MAX_ATTEMPTS="$a_retry_max"
export ASC_THREAD_LOCK_MODE="$a_lock_mode"
export ASC_THREAD_TRIGGER="$a_trigger"
export ASC_THREAD_NEEDS_INTERACTIVE='false'
export ASC_WRAP_EMITTER="${ASC_WRAP_EMITTER:-manual}"
export ASC_WRAP_RECEIVER="${ASC_WRAP_RECEIVER:-$a_entry}"
export ASC_WRAP_KIND="${ASC_WRAP_KIND:-thread-wrap}"

# Supervisor writes YAML (start + EXIT) so short jobs cannot race the parent.
f_thread_supervised_run() {
  trap 'u_thread_supervisor_exit $?' EXIT

  if ! f_thread_lock_acquire "$ASC_THREAD_ENTRY" "$a_lock_mode"; then
    echo "Thread '$ASC_THREAD_ENTRY' lock busy; skip."
    ASC_THREAD_STATUS='exited'
    ASC_THREAD_EXIT_CODE=0
    ASC_THREAD_ENDED_MS="$(date +%Y-%m-%dT%H:%M:%S.%3N)"
    # Avoid overwriting a running peer's YAML on skip.
    trap - EXIT
    exit 0
  fi

  export ASC_THREAD_PID="$BASHPID"
  export ASC_THREAD_PPID="$PPID"

  f_thread_proc_tree "$BASHPID"
  export ASC_THREAD_TREE="$(printf '%s\n' "${thread_tree_arr[@]}")"

  local attempt=1
  local max_try=$((a_retry_max + 1))
  local delay_s
  local rc=0

  delay_s="$(f_thread_delay_seconds "$a_retry_delay")"

  while true; do
    export ASC_THREAD_ATTEMPT="$attempt"
    f_thread_yml_write "$ASC_THREAD_ENTRY"
    f_thread_chown_human "data/threads/${ASC_THREAD_ENTRY}.yml"

    # Noninteractive: no stdin (fail-fast on prompts).
    "$a_script_real" "$@" </dev/null
    rc=$?

    # Do not retry on SIGINT/SIGTERM-ish or success.
    if [[ $rc -eq 0 || $rc -eq 130 || $rc -eq 143 ]]; then
      return "$rc"
    fi

    if [[ $attempt -ge $max_try ]]; then
      return "$rc"
    fi

    echo "Thread retry $attempt/$a_retry_max after exit $rc (sleep ${delay_s}s) ..."
    sleep "$delay_s"
    attempt=$((attempt + 1))
  done
}

if [[ -n "${ASC_LOG_WRAP_ACTIVE:-}" ]]; then
  f_thread_supervised_run "$@" &
else
  (
    trap '' HUP
    f_thread_supervised_run "$@"
  ) >> "$a_output" 2>&1 </dev/null &
fi
a_pid=$!

# Brief wait so supervisor can create the YAML before we print its path.
sleep 0.05

f_thread_chown_human "data/threads/${a_entry}.yml"
f_thread_chown_human "data/threads/${a_entry}.lock"

echo "Thread started (PID $a_pid)."
echo "  script    : $a_script_real $*"
echo "  thread    : data/threads/${a_entry}.yml"
echo "  output    : $a_output"
