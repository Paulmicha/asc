#!/usr/bin/env bash

##
# Implements hook -a 'init'.
#
# Writes the hooks named in ASC_GIT_HOOKS_WIRED.
# Empty writes none. App cloning belongs to instance-provided clone hooks.
#
# @see f_git_write_hooks() in asc/git/write_hooks.sh
#

if [[ -n "${ASC_GIT_HOOKS_WIRED:-}" ]]; then
  . asc/git/write_hooks.sh
  f_git_write_hooks "$ASC_GIT_HOOKS_WIRED"
fi
