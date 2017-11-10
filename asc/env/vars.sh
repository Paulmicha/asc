#!/bin/bash

##
# Env (settings) model file.
#
# This file is dynamically included during stack init.
# @see asc/stack/init.sh
# @see asc/stack/init/aggregate_env_vars.sh
# @see asc/utilities/env.sh
#
# Matching rules and syntax are explained in documentation :
# @see asc/env/README.md
#

define PROJECT_STACK
define PROJECT_DOCROOT "[default]=$PWD"
define PROVISION_USING "[default]=docker-compose-2"
define REG_BACKEND "[default]=file"
# TODO consider using a separate store for secrets, see asc/env/README.md.
# define SECRETS_BACKEND

define APP_DOCROOT "[default]=$PWD/web"
define INSTANCE_TYPE "[default]=dev"
define INSTANCE_DOMAIN "[default]=$(u_get_instance_domain)"
define INSTANCE_ALIAS

define DEPLOY_USING "[default]=git"
