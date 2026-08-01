#!/usr/bin/env bash

##
# Global (env) vars for the 'remote_db' ASC extension.
#
# This file is used during "instance init" to generate the global environment
# variables specific to current project instance.
#
# @see f_instance_init() in asc/instance/instance.inc.sh
# @see asc/utilities/global.sh
# @see asc/bootstrap.sh
#

# Skipping means an extra roundtrip to get the latest dump(s) file name
# from the remote, instead of having a local file named after the symlink. The
# extra wait allows to maintain a local downloaded file name typically
# containing a datestamp.
global ASC_REMOTE_DB_SYMLINK_DL "[default]='no'"
