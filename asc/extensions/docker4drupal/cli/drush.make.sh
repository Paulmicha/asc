#!/usr/bin/env bash

##
# Convenience 'make' shortcut : drush.
#
# Depends on drush (or an alias) being operational on current instance.
#
# @see asc/extensions/docker4drupal/make.mk
#
# @example
#   make drush st
#   # Or :
#   asc/extensions/docker4drupal/cli/drush.make.sh st
#

. asc/bootstrap.sh

drush $@
