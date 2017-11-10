#!/bin/bash

##
# (Re)inits environment settings for this project intance.
#
# @see asc/env/README.md
#
# Usage examples :
# $ . asc/stack/init.sh                 # Will prompt to confirm/edit every default value
# $ . asc/stack/init.sh -s drupal-7     # Short name/value argument syntax
# $ . asc/stack/init.sh -s nodejs -y    # "-y" will use default values, no prompts
# $ . asc/stack/init.sh --stack=drupal-7 --yes      # Longer name/value argument syntax (equivalent)
#

. asc/bash_utils.sh

# Get named script arguments.
. asc/stack/init/get_args.sh

# These globals are needed throughout this task's related scripts.
export ENV_VARS
export ENV_VARS_COUNT
export ENV_VARS_UNIQUE_NAMES
export ENV_VARS_UNIQUE_KEYS

export PROJECT_STACK="$P_PROJECT_STACK"
export PROVISION_USING="$P_PROVISION_USING"
export CURRENT_ENV_SETTINGS_FILE='asc/env/current/vars.sh'

if [[ (-z "$PROJECT_STACK") && ($P_YES == 0) ]]; then
  read -p "Enter PROJECT_STACK value : " PROJECT_STACK
fi

if [[ -z "$PROJECT_STACK" ]]; then
  echo "Warning in $BASH_SOURCE line $LINENO: cannot carry on without a value for \$PROJECT_STACK."
  # TODO use exit instead or conditionally handle both.
  return
fi

# (Re)start env vars aggregation.
unset ENV_VARS
declare -A ENV_VARS
ENV_VARS_COUNT=0
ENV_VARS_UNIQUE_NAMES=()
ENV_VARS_UNIQUE_KEYS=()
. asc/stack/init/aggregate_env_vars.sh

# Write env vars in current instance's settings file.
. asc/env/write.sh
