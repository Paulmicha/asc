#!/usr/bin/env bash

##
# (Re)write Moodle local settings.
#
# @see asc/extensions/moodle_d4php/moodle_d4php.inc.sh
#
# Usage :
# make app-write-settings
# # Or :
# asc/extensions/moodle_d4php/app/write_settings.sh
#

. asc/bootstrap.sh

u_db_set
u_moodle_write_settings
