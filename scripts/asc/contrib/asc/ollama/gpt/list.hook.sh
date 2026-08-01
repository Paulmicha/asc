#!/usr/bin/env bash

##
# Implements hook_ms -s 'agent' -a 'list' -v 'HOST_OS HOST_TYPE INSTANCE_TYPE'
#
# List locally available Ollama models (`ollama list`).
#
# @see asc/extensions/agent/agent/list.sh
#

if ! command -v ollama >/dev/null 2>&1; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - 'ollama' not found in PATH." >&2
  echo "Install host tools first : make host-provision ; then make agent-start" >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

ollama list
