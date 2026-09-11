#!/usr/bin/env bash

##
# Lists ASC extension.
#
# @param 1 [optional] String - either :
#   - 'all' | 'a' : list every single extensions,
#   - 'enabled' | 'e' : only enabled extensions,
#   - 'disabled' | 'd' : only disabled extensions.
#   Defaults to 'enabled'.
#
# @example
#   # List enabled extensions only (default) :
#   make list-extensions
#   # Or :
#   asc/instance/list_extensions.sh
#
#   # List all extensions (enabled + disabled) :
#   make list-extensions 'a'
#   make list-extensions 'all'
#   # Or :
#   asc/instance/list_extensions.sh 'a'
#   asc/instance/list_extensions.sh 'all'
#
#   # List disabled extensions only :
#   make list-extensions 'd'
#   make list-extensions 'disabled'
#   # Or :
#   asc/instance/list_extensions.sh 'd'
#   asc/instance/list_extensions.sh 'disabled'
#

. asc/bootstrap.sh

ASC_INC=''
f_asc_extensions

for val in "$ASC_INC"; do
  printf "%s\n" "$val"
done
