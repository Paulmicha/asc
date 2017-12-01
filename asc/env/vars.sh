#!/bin/bash

##
# Env settings model file.
#
# This file is dynamically included during stack init.
# @see asc/stack/init.sh
# @see asc/utilities/stack.sh
# @see asc/utilities/env.sh
#
# Matching rules and syntax are explained in documentation :
# @see asc/env/README.md
#
# TODO provide tests / CI examples.
#

define PROJECT_STACK
define PROJECT_DOCROOT "[default]=$PWD"
define APP_DOCROOT "[default]=\$PROJECT_DOCROOT/web"
define INSTANCE_TYPE "[default]=dev"
define INSTANCE_DOMAIN "[default]='$(u_get_instance_domain)'"
define INSTANCE_ALIAS

define ASC_MODE "[default]=separate"
define APP_GIT_ORIGIN "[if-ASC_MODE]=separate"
define APP_GIT_DIR "[default]=\$APP_DOCROOT [if-ASC_MODE]=separate"

define HOST_TYPE "[default]=local"
define HOST_OS "[default]='$(u_host_get_os)'"
define PROVISION_USING "[default]=docker-compose"
define DEPLOY_USING "[default]=git"

# TODO evaluate removal of "registry" feature.
define REG_BACKEND "[default]=file"
# TODO else consider using a separate store for secrets, see asc/env/README.md.
# define SECRETS_BACKEND
