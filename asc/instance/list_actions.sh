#!/usr/bin/env bash

##
# Convenience make task to list available actions in current project instance.
#
# @see Makefile
# @see asc/make/default.mk
#
# @example
#   make list-actions
#   # Or :
#   asc/instance/list_actions.sh
#

. asc/bootstrap.sh

f_asc_get_actions
f_array_qsort "${asc_action_names_arr[@]}"

for val in "${sorted_arr[@]}"; do
  printf "%s\n" "$val"
done
