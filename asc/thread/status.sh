#!/usr/bin/env bash

##
# Reports whether a background thread is still running.
#
# @param 1 String : make entry point name (e.g. transcribe-all).
#
# @example
#   make thread-status e:transcribe-all
#   # Or :
#   asc/thread/status.sh transcribe-all
#

. asc/bootstrap.sh

a_entry="$1"

if [[ -z "$a_entry" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - entry point name is required." >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

a_entry=${a_entry#'e:'}
thread_yml="data/threads/${a_entry}.yml"

if [[ ! -f "$thread_yml" ]]; then
  echo "Thread '$a_entry' : not started (no YAML record)."

  exit 1
fi

if ! f_thread_yml_load "$a_entry"; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - cannot load $thread_yml." >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

a_last_update=''
f_thread_output_mtime_ms "$thread_output" 'a_last_update'

if [[ "$thread_status" == 'running' ]]; then
  if kill -0 "$thread_pid" 2>/dev/null; then
    echo "Thread '$a_entry' : running (PID $thread_pid)."
    echo "  owner       : $thread_owner (uid $thread_uid)"
    echo "  script      : $thread_script"
    echo "  args        : $thread_args"
    echo "  ppid        : $thread_ppid"
    echo "  tree        : ${thread_tree_arr[*]}"
    echo "  started_ms  : $thread_started_ms"
    echo "  status      : $thread_status"
    echo "  output      : $thread_output"
    echo "  last_update : ${a_last_update:-n/a}"
    echo "  yaml        : $thread_yml"

    exit 0
  fi

  f_thread_yml_mark_stale
  thread_status='stale'
fi

echo "Thread '$a_entry' : $thread_status (PID $thread_pid)."
echo "  owner       : $thread_owner (uid $thread_uid)"
echo "  script      : $thread_script"
echo "  args        : $thread_args"
echo "  ppid        : $thread_ppid"
echo "  tree        : ${thread_tree_arr[*]}"
echo "  started_ms  : $thread_started_ms"
echo "  status      : $thread_status"
echo "  exit_code   : $thread_exit_code"
echo "  ended_ms    : $thread_ended_ms"
echo "  output      : $thread_output"
echo "  last_update : ${a_last_update:-n/a}"
echo "  yaml        : $thread_yml"

exit 2
