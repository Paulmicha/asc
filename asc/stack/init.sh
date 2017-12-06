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
#

. asc/bash_utils.sh

# Get named script arguments.
. asc/stack/init/get_args.sh

# These globals are needed throughout this task's related scripts.
export GLOBALS
export GLOBALS_COUNT
export GLOBALS_UNIQUE_NAMES
export GLOBALS_UNIQUE_KEYS

export PROJECT_STACK="$P_PROJECT_STACK"
export PROVISION_USING="$P_PROVISION_USING"
export ASC_CUSTOM_DIR="$P_ASC_CUSTOM_DIR"
export CURRENT_ENV_SETTINGS_FILE='asc/env/current/vars.sh'

if [[ (-z "$PROJECT_STACK") && ($P_YES == 0) ]]; then
  read -p "Enter PROJECT_STACK value : " PROJECT_STACK
fi

if [[ -z "$PROJECT_STACK" ]]; then
  echo
  echo "Error in $BASH_SOURCE line $LINENO: cannot carry on without a value for \$PROJECT_STACK."
  echo "Aborting (1)."
  return 1
fi

# (Re)start dependencies and env vars aggregation.
unset GLOBALS
declare -A GLOBALS
GLOBALS_COUNT=0
GLOBALS_UNIQUE_NAMES=()
GLOBALS_UNIQUE_KEYS=()

# Get ASC core globals required for aggregating dependencies and env vars.
. asc/env/vars.sh

# Aggregate dependencies and env vars.
. asc/stack/init/aggregate_deps.sh
. asc/stack/init/aggregate_env_vars.sh

# Write env vars in current instance's git-ignored settings file.
. asc/env/write.sh

# Apply correct ownership and permissions.
u_hook_app 'apply' 'ownership_and_perms' '' 'stack'

# Allow custom complements for this script.
# TODO evaluate removal of the 'complement' customization method.
u_autoload_get_complement "$BASH_SOURCE"

# Trigger stack/post-init hook.
u_hook 'stack' 'init' 'post'
