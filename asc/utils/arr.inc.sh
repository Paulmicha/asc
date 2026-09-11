#!/usr/bin/env bash

##
# Array-related utility functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#

##
# Checks if an array contains an item.
#
# @param 1 String needle.
# @param 2 Array haystack.
#
# @example
#   declare -a my_array_arr=("test1" "test2" "test3");
#   if f_in_array 'test1' my_array_arr; then
#     echo "Ok, 'test1' found in my_array_arr"
#   else
#     echo "'test1' NOT found in my_array_arr"
#   fi
#
f_in_array() {
  local p_needle="$1"
  local -n p_haystack="$2"
  local item

  for item in "${p_haystack[@]}"; do
    [[ "$item" == "$p_needle" ]] && return 0
  done

  return 1
}

##
# Adds item in array only once (idempotent).
#
# @param 1 String needle.
# @param 2 String the Array variable name (haystack).
#
# @example
#   declare -a my_array_arr=("test1" "test2" "test3");
#   f_array_add_once "test1" my_array_arr
#   f_array_add_once "test4" my_array_arr
#   f_array_add_once "test2" my_array_arr
#   # To debug result :
#   declare -p my_array_arr
#
f_array_add_once() {
  local p_needle="$1"
  local -n p_haystack="$2"

  if ! f_in_array "$p_needle" "$2"; then
    p_haystack+=("$p_needle")
  fi
}

##
# Quickly sorts an array by the values it contains.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# @var sorted_arr
#
# See https://stackoverflow.com/a/30576368
#
# @example
#   my_array_arr=(a c b f 3 5)
#   f_array_qsort "${my_array_arr[@]}"
#   # Check result :
#   declare -p sorted_arr
#   # -> output :
#   #   declare -a sorted_arr='([0]="3" [1]="5" [2]="a" [3]="b" [4]="c" [5]="f")'
#
f_array_qsort() {
  (($#==0)) && return 0

  local stack_arr=(0 $(($#-1)))
  local beg end i pivot smaller_arr larger_arr

  sorted_arr=("$@")

  while (( ${#stack_arr[@]} )); do
    beg=${stack_arr[0]}
    end=${stack_arr[1]}
    stack_arr=("${stack_arr[@]:2}")
    smaller_arr=()
    larger_arr=()
    pivot=${sorted_arr[beg]}

    for (( i=beg+1; i<=end; ++i )); do
      if [[ "${sorted_arr[i]}" < "$pivot" ]]; then
        smaller_arr+=("${sorted_arr[i]}")
      else
        larger_arr+=("${sorted_arr[i]}")
      fi
    done

    sorted_arr=( "${sorted_arr[@]:0:beg}" "${smaller_arr[@]}" "$pivot" "${larger_arr[@]}" "${sorted_arr[@]:end+1}" )

    if ((${#smaller_arr[@]}>=2)); then
      stack_arr+=( "$beg" "$((beg+${#smaller_arr[@]}-1))" )
    fi

    if ((${#larger_arr[@]}>=2)); then
      stack_arr+=( "$((end-${#larger_arr[@]}+1))" "$end" )
    fi
  done
}

##
# Reverses an array.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
#
# Builds reversed_arr from positional parameters directly (no intermediate copy).
#
# @var reversed_arr
#
# See https://unix.stackexchange.com/a/412872
#
# @example
#   my_array_arr=(a c b f 3 5)
#   f_array_reverse "${my_array_arr[@]}"
#   # Check result :
#   declare -p reversed_arr
#   # -> output :
#   #   declare -a reversed_arr='([0]="3" [1]="5" [2]="f" [3]="b" [4]="c" [5]="a")'
#
f_array_reverse() {
  local i

  reversed_arr=()

  for (( i=$#; i>=1; i-- )); do
    reversed_arr+=("${!i}")
  done
}
