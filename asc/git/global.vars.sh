#!/usr/bin/env bash

##
# Git subject globals.
#
# Instance init writes the git hooks named here. The core default stays empty;
# this append is what installs pre-commit so README.md can refresh its TOC.
#
# @see asc/git/init.hook.sh
# @see asc/git/pre-commit.hook.sh
#

global ASC_GIT_HOOKS_WIRED "[append]='pre-commit'"
