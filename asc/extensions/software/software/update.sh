#!/usr/bin/env bash

##
# Software update: alias of apply (upgrade outdated pinned tools).
#
# @example
#   make software-update
#   # Or :
#   asc/extensions/software/software/update.sh
#

. asc/bootstrap.sh

f_software_parse_args "$@"
f_software_provision apply
