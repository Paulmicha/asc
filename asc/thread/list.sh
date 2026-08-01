#!/usr/bin/env bash

##
# Lists background threads started via asc/thread/thread.wrap.sh.
#
# @example
#   make thread-list
#   # Or :
#   asc/thread/list.sh
#

. asc/bootstrap.sh

if [[ ! -d data/threads ]]; then
  echo "No threads directory (data/threads)."

  exit 0
fi

shopt -s nullglob
yml_files_arr=(data/threads/*.yml)

if [[ ${#yml_files_arr[@]} -eq 0 ]]; then
  echo "No thread YAML files in data/threads."

  exit 0
fi

printf '%-28s %-8s %-10s %-10s %-24s %-24s %s\n' \
  'ENTRY' 'PID' 'OWNER' 'STATUS' 'STARTED' 'LAST_UPDATE' 'OUTPUT'
printf '%-28s %-8s %-10s %-10s %-24s %-24s %s\n' \
  '----' '---' '-----' '------' '-------' '----------' '------'

for a_yml in "${yml_files_arr[@]}"; do
  a_entry="${a_yml##*/}"
  a_entry="${a_entry%.yml}"

  unset thread_tree_arr
  unset thread_entry thread_owner thread_pid thread_status
  unset thread_started_ms thread_output

  if ! f_thread_yml_load "$a_entry"; then
    continue
  fi

  if [[ "$thread_status" == 'running' ]] \
    && ! kill -0 "$thread_pid" 2>/dev/null; then
    f_thread_yml_mark_stale
  fi

  a_last='-'
  f_thread_output_mtime_ms "$thread_output" 'a_last'
  [[ -n "$a_last" ]] || a_last='-'

  printf '%-28s %-8s %-10s %-10s %-24s %-24s %s\n' \
    "$thread_entry" \
    "$thread_pid" \
    "$thread_owner" \
    "$thread_status" \
    "$thread_started_ms" \
    "$a_last" \
    "$thread_output"
done
