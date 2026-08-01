#!/usr/bin/env bash

##
# List all currently active make entry points.
#
# @see Makefile
# @see asc/make/default.mk
#
# @example
#   make make-list-entry-points
#   # Or :
#   asc/make/list_entry_points.sh
#

. asc/bootstrap.sh

make_entries_arr=()
real_scripts_arr=()
output_arr=()

f_make_list_entry_points

for index in "${!real_scripts_arr[@]}"; do
  task="${make_entries_arr[index]}"
  script="${real_scripts_arr[index]}"

  output_arr+=("$task
  → $script")
done

f_array_qsort "${output_arr[@]}"

for line in "${sorted_arr[@]}"; do
  echo "$line"
done
