#!/usr/bin/env bash

##
# Implements hook_ms -s 'agent' -a 'stop' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Unload one or more running models from memory (`ollama stop`).
#
# @example
#   make agent-stop llama3.2
#   agent_MODEL=llama3.2 make agent-stop
#
# @see asc/extensions/agent/agent/stop.sh
#

if ! command -v ollama >/dev/null 2>&1; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - 'ollama' not found in PATH." >&2
  echo "Install host tools first : make host-provision ; then make agent-start" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

p_models="${p_models:-${agent_MODEL:-${agent_OLLAMA_MODEL:-}}}"

if [[ -z "$p_models" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - no model specified." >&2
  echo "Usage: make agent-stop MODEL [MODEL…]  (or export agent_MODEL)" >&2
  echo "Use make agent-stop-all to unload every running model." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

for p_model in $p_models; do
  echo "Stopping model '$p_model' ..."
  ollama stop "$p_model" || exit $?
done

echo "Over."
