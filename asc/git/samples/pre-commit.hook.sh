#!/usr/bin/env bash

##
# Sample implementation of hook -s 'git' -a 'pre-commit'.
#
# @see f_git_wrapper() in asc/git/git.opt-inc.sh
#
# This example is inactive. To be used for real when ASC hook is triggered,
# this file would have to be placed in 'git/pre-commit.hook.sh' in an extension.
# To list all the possible paths that can be used, use :
#
# $ make hook-debug s:git a:pre-commit
#

# Include globals, aliases, utility functions (ASC).
. asc/bootstrap.sh

# Caller dir is samples/, so git.opt-inc.sh is not derived.
# shellcheck disable=SC1091
. asc/git/git.opt-inc.sh

# (Re)set file system ownership and permissions.
hook -s 'app instance' -a 'set_fsop'

# Re-add previously staged files in case their permissions have changed.
f_git_get_staged_files "$APP_DOCROOT" '' 'staged'
for f in $staged; do
  f_git_wrapper add "$f"
done
