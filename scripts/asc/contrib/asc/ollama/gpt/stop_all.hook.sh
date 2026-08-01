#!/usr/bin/env bash

##
# Implements hook_ms -s 'agent' -a 'stop_all' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Unload every model currently loaded in memory (`ollama ps` → `ollama stop`).
#
# @see asc/extensions/agent/agent/stop_all.sh
#

if ! command -v ollama >/dev/null 2>&1; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - 'ollama' not found in PATH." >&2
  echo "Install host tools first : make host-provision ; then make agent-start" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

a_running_arr=()
while IFS= read -r a_name; do
  [[ -n "$a_name" ]] || continue
  a_running_arr+=("$a_name")
done < <(ollama ps 2>/dev/null | awk 'NR > 1 && $1 != "" { print $1 }')

if [[ ${#a_running_arr[@]} -eq 0 ]]; then
  echo "No running Ollama models."
  echo "Over."
  exit 0
fi

for a_model in "${a_running_arr[@]}"; do
  echo "Stopping model '$a_model' ..."
  ollama stop "$a_model" || exit $?
done

echo "Over."
