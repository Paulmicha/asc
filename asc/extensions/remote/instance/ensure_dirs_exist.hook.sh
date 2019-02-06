#!/usr/bin/env bash

##
# Implements hook -a 'ensure_dirs_exist' -s 'instance'.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_init() in asc/instance/instance.inc.sh
#

if [[ ! -d "scripts/asc/local/remote-instances" ]]; then
  echo "Creating required dir scripts/asc/local/remote-instances"
  mkdir -p "scripts/asc/local/remote-instances"
fi
