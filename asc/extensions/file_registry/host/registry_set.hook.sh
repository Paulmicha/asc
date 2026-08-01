#!/usr/bin/env bash

##
# Implements hook -s 'host' -a 'registry_set'.
#
# Uses the following vars in calling scope :
# - reg_key
# - reg_val
#
# @see f_host_registry_set() in asc/host/host.inc.sh
#

reg_file_path=''

f_file_registry_get_path "$reg_key" 'host'

echo "$reg_val" > "$reg_file_path"
