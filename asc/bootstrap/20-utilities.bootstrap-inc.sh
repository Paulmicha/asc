#!/usr/bin/env bash

##
# Bootstrap phase: source ASC core utilities (fixed order).
#
# Sourced only from asc/bootstrap.sh (inside ASC_BS_FLAG).
#
# @see asc/bootstrap.sh
#

# Include ASC core utilities.
. asc/utilities/shell.sh
. asc/utilities/asc.sh
. asc/utilities/global.sh
. asc/utilities/hook.sh
. asc/utilities/autoload.sh
. asc/utilities/fs.sh
. asc/utilities/array.sh
. asc/utilities/string.sh
. asc/utilities/yaml.sh
