#!/usr/bin/env bash

##
# Implements hook -a 'ensure_dirs_exist' -s 'instance'.
#
# This file is dynamically included when the "hook" is triggered.
# @see f_instance_init() in asc/instance/instance.inc.sh
#

if [[ ! -d "data/asc/cache/entities/remote_instance" ]]; then
  echo "Creating required dir data/asc/cache/entities/remote_instance"
  mkdir -p "data/asc/cache/entities/remote_instance"
fi
