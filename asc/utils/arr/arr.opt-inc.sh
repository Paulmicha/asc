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
  local needle="${1}"
  local haystack=${2}[@]
  local i

  for i in ${!haystack}; do
    if [[ "$i" == "$needle" ]]; then
      return 0
    fi
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
  local needle="${1}"
  local haystack_var_name="${2}"

  if ! f_in_array "$needle" "$haystack_var_name"; then
    eval "$haystack_var_name+=($needle)"
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
  local stack_arr=( 0 $(($#-1)) ) beg end i pivot smaller_arr larger_arr
  sorted_arr=("$@")

  while ((${#stack_arr[@]})); do
    beg=${stack_arr[0]}
    end=${stack_arr[1]}
    stack=( "${stack_arr[@]:2}" )
    smaller_arr=() larger_arr=()
    pivot=${sorted_arr[beg]}

    for ((i=beg+1;i<=end;++i)); do
      if [[ "${sorted_arr[i]}" < "$pivot" ]]; then
        smaller_arr+=( "${sorted_arr[i]}" )
      else
        larger_arr+=( "${sorted_arr[i]}" )
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
# Sorts an array by its keys (not is values).
#
# This function writes its result to a variable subject to collision in calling
# scope, and requires that the input array be already defined as 'array_dict'.
#
# @var array_dict
# @var sorted_arr
#
# @example
#   declare -A array_dict=()
#   array_dict[12]='a'
#   array_dict[7]='b'
#   array_dict[32]='c'
#   array_dict[6785]='d'
#   f_array_ksort
#   # Check result :
#   declare -p sorted_arr
#   # -> output :
#   #   declare -a sorted_arr=([7]="b" [12]="a" [32]="c" [6785]="d")
#
f_array_ksort() {
  local array_keys_arr="${!array_dict[@]}"
  local k
  f_array_qsort "${array_keys_arr[@]}"
  array_keys_arr="${sorted_arr[@]}"
  sorted_arr=()
  for k in $array_keys_arr; do
    sorted_arr["$k"]="${array_dict[$k]}"
  done
}

##
# Reverses an array.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to a variable subject to collision in calling scope.
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
  local a
  local tmp_arr

  tmp_arr=("$@")
  reversed_arr=()
  last=${#tmp_arr[@]}

  a=""
  for (( i=last-1 ; i>=0 ; i-- ));do
    # printf '%s%s' "$a" "${tmp_arr[i]}"
    reversed_arr+=("${tmp_arr[i]}")
    a=" "
  done
}


##
# Prints array (debug utility).
#
# See https://unix.stackexchange.com/a/366655
#
# @example (associative array)
#   declare -A a_dict=([a]=123 [b]="foo bar" [c]="(blah)")
#   f_array_print a_dict
#   # -> outputs :
#   #   a=123
#   #   b=foo bar
#   #   c=(blah)
#
# @example (indexed array)
#   b_arr=(abba acdc)
#   f_array_print b_arr
#   # -> outputs :
#   #   0=abba
#   #   1=acdc
#
f_array_print() {
  declare -n __p_nameref="$1"
  for k in "${!__p_nameref[@]}"; do
    printf "%s=%s\n" "$k" "${__p_nameref[$k]}"
  done
}
