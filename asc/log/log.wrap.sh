#!/usr/bin/env bash

##
# Log wrapper to run a make entry point in the background.
#
# Writes stdout + stderr to data/logs/{entrypoint}.txt and records each run
# in data/logs/{entrypoint}.sidecar.txt.
#
# @param 1 String : path to wrapped script or make entry point name.
#
# @example
#   # This will write stdout + stderr to the following log file :
#   # data/logs/transcribe-all.txt
#   # And also add a new line in its corresponding "registry file" :
#   # data/logs/transcribe-all.sidecar.txt
#   asc/log/log.wrap.sh \
#     asc/extensions/transcription/transcribe/all.sh
#
#   # Works with raw make entry points too :
#   make log-wrap e:test-asc
#   # Or :
#   asc/log/log.wrap.sh test-asc
#
#   # Works with thread-wrap inner wrapper (log captures, thread backgrounds) :
#   make lt e:transcribe-all
#   # Or :
#   asc/instance/logged/thread.sh transcribe-all
#   # Yields :
#   #   data/logs/transcribe-all.txt (+ sidecar); PID in data/threads/
#   # Equivalent (without pre-process and post-process hooks) :
#   asc/log/log.wrap.sh asc/thread/thread.wrap.sh transcribe-all
#

. asc/bootstrap.sh

a_script="$1"
shift

log_file="$a_script"
uses_thread_inner_wrap=0
is_valid=0

if [[ "$a_script" == *'thread.wrap.sh' ]]; then
  uses_thread_inner_wrap=1
  log_file="$1"
fi

# Restrict to make entry points, and convert scripts paths to entry points names.
make_entries_arr=()
real_scripts_arr=()

f_make_list_entry_points

for index in "${!real_scripts_arr[@]}"; do
  task="${make_entries_arr[index]}"
  script="${real_scripts_arr[index]}"

  # Convert script path to make entry point name.
  case "$log_file" in "$script")
    log_file="${log_file/$script/$task}"
    is_valid=1
    continue
  esac

  # Check other values against make entry points (whitelist).
  if [[ $uses_thread_inner_wrap -eq 0 ]]; then
    case "$log_file" in "$task")
      a_script="$script"
      is_valid=1
    esac
  else
    case "$log_file" in "$task")
      is_valid=1
    esac
  fi
done

if [[ $is_valid -ne 1 ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - only supports valid make entry points." >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

# Pile-up: do not truncate/restart logs if the entry thread is still running.
a_entry_name="${log_file#e:}"
if f_thread_pileup_should_skip "$a_entry_name"; then
  echo "Log/thread '$a_entry_name' already running (PID $thread_pid); skip."
  exit 0
fi

hook_ms 'dry-run' -s 'log' -a 'storage' -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'

if [[ ! -f "$most_specific_match" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - no implementation match :" >&2
  echo >&2
  echo "  hook_ms 'dry-run' -s 'log' -a 'storage' -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'" >&2
  echo >&2
  echo "    STACK_VERSION = '$HOST_OS'" >&2
  echo "    PROVISION_USING = '$PROVISION_USING'" >&2
  echo "    HOST_TYPE = '$HOST_TYPE'" >&2
  echo "    HOST_OS = '$HOST_OS'" >&2
  echo >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

. "$most_specific_match" "$@"
