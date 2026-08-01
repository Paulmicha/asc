#!/usr/bin/env bash

##
# Bootstrap phase: source ASC core utilities (fixed order).
#
# Sourced only from asc/bootstrap.sh (inside ASC_BS_FLAG).
#
# Layout after the utilities → asc/asc + asc/utils + asc/yml split:
#   - Primordial (hook/global/extend): asc/asc/*.inc.sh
#   - Generic helpers: asc/utils/{shell,fs,arr,str}/*.opt-inc.sh (eager here)
#   - YAML: asc/yml/yml.inc.sh (also on ASC_INC as subject include)
#
# @see asc/bootstrap.sh
#

# Include ASC core utilities.
. asc/utils/shell/shell.opt-inc.sh
. asc/asc/core.inc.sh
. asc/asc/global.inc.sh
. asc/asc/hook.inc.sh
. asc/asc/autoload.inc.sh
. asc/utils/fs/fs.opt-inc.sh
. asc/utils/arr/arr.opt-inc.sh
. asc/utils/str/str.opt-inc.sh
. asc/yml/yml.inc.sh
