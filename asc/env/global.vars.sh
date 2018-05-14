#!/usr/bin/env bash

##
# ASC core global env vars.
#
# This file (and every others named like it in ASC extensions and in the ASC
# customization dir) is used during "instance init" to generate a single script :
#
# asc/env/current/global.vars.sh
#
# That script file will contain declarations for every global variables found in
# this project instance as readonly. It is git-ignored and loaded on every
# bootstrap - if it exists, that is if "instance init" was already launched once
# in current project instance.
#
# Unless the "instance init" command is set to bypass prompts, most calls to
# global() will prompt for confirming or replacing default values or for simply
# entering a value if no default is declared. The only exceptions are global
# declarations explicitly providing a value.
#
# @see asc/env/current/global.vars.sh
# @see asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

global PROJECT_DOCROOT "[default]=$PWD"
global APP_DOCROOT "[default]=$PROJECT_DOCROOT/web"
global INSTANCE_TYPE "[default]=dev"
global INSTANCE_DOMAIN "[default]='$(u_instance_domain)'"

# This allows supporting multi-repo projects, i.e. 1 repo for the app + 1 for
# the "dev stack" :
# - Use ASC_MODE='monolithic' for single-repo projects.
# - Use ASC_MODE='separate' for multi-repo projects (mandatory app Git details).
# TODO support any other combination of any number of repos ?
global ASC_MODE "[default]=separate"
global APP_GIT_ORIGIN "[if-ASC_MODE]=separate"
global APP_GIT_WORK_TREE "[if-ASC_MODE]=separate [default]=$APP_DOCROOT"

# These values are used to generate lookup paths in hooks (events), overrides
# and/or complements.
# @see scripts/README.md
global HOST_TYPE "[default]=local"
global HOST_OS "$(u_host_os)"
global PROVISION_USING "[default]=docker-compose"

# Path to custom scripts ~ commonly automated processes. ASC will also use this
# path to look for overrides and complements.
# @see u_autoload_override()
# @see u_autoload_get_complement()
global PROJECT_SCRIPTS "[default]=scripts"

# [optional] Allows extensions to provide their own makefile includes (after
# instance init). This global must contain a list of paths relative to
# PROJECT_DOCROOT separated by space.
# @see https://www.gnu.org/software/make/manual/html_node/Include.html
# @see asc/env/current/README.md
# @see Makefile
global ASC_MAKE_INC
