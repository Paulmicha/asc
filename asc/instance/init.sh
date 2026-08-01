#!/usr/bin/env bash

##
# Instance initialization process ("instance init").
#
# Uses env.yml files.
# @see f_instance_init() in asc/instance/instance.inc.sh
#
# @example
#   # Calling this script without any arguments will use prompts in terminal
#   # to provide values for every globals.
#   asc/instance/init.sh
#   # Or :
#   make init
#
#   # Initializes given stack version without prompts (i.e. default values) :
#   asc/instance/init.sh -s 'myproject-2024' -y
#   # Or :
#   make init -- -s 'myproject-2024' -y
#
#   # Init with instance type = prod :
#   asc/instance/init.sh -t 'prod' -y
#   # Or :
#   make init -- -t 'prod' -y
#
#   # Init with host type = remote :
#   asc/instance/init.sh -h 'remote' -y
#   # Or :
#   make init -- -h 'remote' -y
#

# This action can be (re)launched after local instance was already initialized,
# and in this case, we cannot have 'readonly' variables automatically loaded
# during ASC bootstrap -> so we use that var as a flag to avoid it.
# @see asc/bootstrap.sh
ASC_BS_SKIP_GLOBALS=1

. asc/bootstrap.sh

f_instance_init $@
