#!/usr/bin/env bash

##
# Global (env) vars for the 'cognition' ASC core extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see f_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

# [optional] Shorter generated make tasks names.
# @see f_make_task_name() in asc/instance/instance.inc.sh
# This allows to use :
#   make ocr
# as an equivalent of :
#   make recognize-text
global ASC_SYNONYMS "[append]='recognize-text/ocr'"
