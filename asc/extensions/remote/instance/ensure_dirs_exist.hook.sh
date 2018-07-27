#!/usr/bin/env bash

##
# Implements hook -a 'ensure_dirs_exist' -s 'instance'.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_init() in asc/instance/instance.inc.sh
#

if [[ ! -d "asc/env/current/remote-instances" ]]; then
  echo "Creating required dir asc/env/current/remote-instances"
  mkdir -p "asc/env/current/remote-instances"
fi
