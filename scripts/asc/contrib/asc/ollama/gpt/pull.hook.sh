#!/usr/bin/env bash

##
# Implements hook_ms -s 'agent' -a 'pull' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# Pull one or more models from the Ollama registry.
#
# @example
#   make agent-pull llama3.2
#   agent_MODEL=llama3.2 make agent-pull
#
# @see asc/extensions/agent/agent/pull.sh
#

if ! command -v ollama >/dev/null 2>&1; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - 'ollama' not found in PATH." >&2
  echo "Install host tools first : make host-provision ; then make agent-start" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

a_models="${a_models:-${agent_MODEL:-${agent_OLLAMA_MODEL:-}}}"

if [[ -z "$a_models" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - no model specified." >&2
  echo "Usage: make agent-pull MODEL [MODEL…]  (or export agent_MODEL)" >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

for a_model in $a_models; do
  echo "Pulling model '$a_model' ..."
  ollama pull "$a_model" || exit $?
done

echo "Over."
