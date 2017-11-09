#!/bin/bash

##
# Aggregates env vars.
#
# @see asc/stack/init.sh
#

u_env_models_get_lookup_paths

# Start with ASC globals.
. asc/env/vars.sh

# Include any existing matching models.
for env_model in "${ENV_MODELS_PATHS[@]}"; do
  echo "matching model : $env_model"
  if [[ -f "$env_model" ]]; then
    . "$env_model"
  fi
done

# WIP
for var_name in "${!ENV_VARS[@]}"; do
  echo "var $var_name = '${ENV_VARS[$var_name]}'"
done
