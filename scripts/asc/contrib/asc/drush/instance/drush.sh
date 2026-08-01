#!/usr/bin/env bash

##
# Custom Make entry point to forward all arguments to the drush program.
#
# @example
#   make drush st
#   make drush ev 'print "hello from Drupal php";'
#   # Or :
#   asc/extensions/drush/instance/drush.sh st
#   asc/extensions/drush/instance/drush.sh ev 'print "hello from Drupal php";'
#

. asc/bootstrap.sh

# This may be called from contexts with or without docker-compose.
# The docroot option is implemented here :
# @see asc/extensions/drush/asc/alias.hook.sh
# @see asc/extensions/drush/asc/alias.compose.hook.sh
# This extension does not deal with multi-site Drupal setups. For that, see the
# "drupalwt" extension.
if [[ -n "$DRUSH_DEFAULT_URI" ]]; then
  drush --uri="$DRUSH_DEFAULT_URI" $@
else
  drush $@
fi
