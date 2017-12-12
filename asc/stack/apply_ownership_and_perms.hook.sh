#!/usr/bin/env bash

##
# Implements u_hook_app 'apply' 'ownership_and_perms' '' 'stack'.
#
# This file is dynamically included when the "hook" is triggered.
#

if [[ -d "$PROJECT_DOCROOT/asc" ]]; then
  chmod u+x "$PROJECT_DOCROOT/asc" -R
fi

if [[ -d "$PROJECT_DOCROOT/scripts" ]]; then
  chmod u+x "$PROJECT_DOCROOT/scripts" -R
fi
