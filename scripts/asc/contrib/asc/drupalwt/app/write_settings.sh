#!/usr/bin/env bash

##
# (Re)write Drupal local settings.
#
# @see asc/extensions/drupalwt/drupalwt.inc.sh
#
# Usage :
# make app-write-settings
# # Or :
# asc/extensions/drupalwt/app/write_settings.sh
#

. asc/bootstrap.sh

f_db_set
f_dwt_write_settings
