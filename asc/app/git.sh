#!/usr/bin/env bash

##
# Entry point / "bridge" to execute git commands in app dir from project docroot.
#
# Useful if the "dev stack" has its own separate Git repo.
#
# @requires APP_GIT_WORK_TREE global.
# @see asc/env/global.vars.sh
# @see u_git_wrapper() in asc/git/git.inc.sh
#
# @example
#   make app-git 'status'
#   make app-git 'pull'
#   make app-git 'gc'
#   make app-git 'checkout develop'
#   make app-git 'diff --name-only'
#   # Or :
#   asc/app/git.sh status
#   asc/app/git.sh pull
#   asc/app/git.sh gc
#   asc/app/git.sh checkout develop
#   asc/app/git.sh diff --name-only
#

. asc/bootstrap.sh

u_git_wrapper $@
