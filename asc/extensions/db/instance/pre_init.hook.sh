#!/usr/bin/env bash

##
# Implements hook -a 'init' -p 'pre'.
#
# After globals aggregation during instance init, we immediately trigger the DB
# crendentials initialization so that the values can be written once then
# always read (cf. registry), if applicable.
#
# @see f_db_set() in asc/extensions/db/db.inc.sh
# @see f_instance_init() in asc/instance/instance.inc.sh
#

f_db_set_all
