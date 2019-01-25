#!/usr/bin/env bash

##
# Convenience make task to list available actions in current project instance.
#
# @see Makefile
# @see asc/default.mk
#
# @example
#   make list-actions
#   # Or :
#   asc/instance/list_actions.make.sh
#

. asc/bootstrap.sh

u_asc_get_actions
u_array_qsort "${asc_action_names[@]}"

for val in "${sorted_arr[@]}"; do
  printf "%s\n" "$val"
done
