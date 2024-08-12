#!/usr/bin/env bash

##
# Convenience 'make' shortcut : drush.
#
# Depends on drush (or an alias) being operational on current instance.
#
# @see asc/extensions/drupalwt/make.mk
#
# @example
#   make drush st
#   # Or :
#   asc/extensions/drupalwt/instance/drush.sh st
#

. asc/bootstrap.sh

drush $@
