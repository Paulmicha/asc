#!/usr/bin/env bash

##
# Rotates log files in data/logs when they exceed a size threshold.
#
# @param 1 [optional] String : make entry point name. Rotates all logs if omitted.
# @param 2 [optional] Number : max size in bytes (default: 1048576 = 1 MiB).
#
# @example
#   # All logs :
#   make log-rotate
#   # Or :
#   asc/log/rotate.sh
#
#   # Filtered by make entry point :
#   make log-rotate e:transcribe-all
#   # Or :
#   asc/log/rotate.sh transcribe-all
#

. asc/bootstrap.sh

a_entry="$1"
a_max_bytes="${2:-1048576}"

if [[ ! -d data/logs ]]; then
  exit 0
fi

f_log_rotate_file() {
  local a_log_file="$1"
  local a_size=''

  if [[ ! -f "$a_log_file" ]]; then
    return 0
  fi

  a_size="$(stat -c '%s' "$a_log_file" 2>/dev/null || echo 0)"

  if [[ "$a_size" -lt "$a_max_bytes" ]]; then
    return 0
  fi

  a_rotated="${a_log_file}.1"

  if [[ -f "$a_rotated" ]]; then
    mv -f "$a_rotated" "${a_log_file}.2"
  fi

  mv -f "$a_log_file" "$a_rotated"
  touch "$a_log_file"

  echo "Rotated: $a_log_file -> $a_rotated (${a_size} bytes)"
}

if [[ -n "$a_entry" ]]; then
  a_entry=${a_entry#'e:'}
  f_log_rotate_file "data/logs/${a_entry}.txt"

  exit 0
fi

shopt -s nullglob
log_files_arr=(data/logs/*.txt)

for a_log_file in "${log_files_arr[@]}"; do
  case "$a_log_file" in
    *.sidecar.txt) continue;;
  esac

  f_log_rotate_file "$a_log_file"
done
