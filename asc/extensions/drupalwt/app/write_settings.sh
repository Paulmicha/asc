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

u_db_set
u_dwt_write_settings
