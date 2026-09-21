#!/usr/bin/env bash

##
# Make-related utility functions.
#
# This file is sourced during core ASC bootstrap.
# Init-only generate: `. asc/make/generate.sh`
# @see asc/make/generate.sh
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#

##
# Make tasks arg safety check.
#
# Make sure none of the "arguments" passed in make calls would trigger unwanted
# targets (since we use it as aliases with completion in terminal).
#
# @example
#   # All args are checked.
#   f_make_check_args arg1 arg2
#
f_make_check_args() {
  local pivots_arr=()
  local real_scripts_arr=()

  f_make_list_hardcoded
  f_make_list_entry_points

  if [[ -z "${pivots_arr[@]}" ]]; then
    echo >&2
    echo "Error in f_make_check_args() - $BASH_SOURCE line $LINENO: make entry points not found." >&2
    echo "It seems local instance hasn't been initialized yet." >&2
    echo "@see asc/instance/init.sh" >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi

  local make_entry_point=''

  while [[ $# -gt 0 ]]; do
    for make_entry_point in "${pivots_arr[@]}"; do
      case "$1" in "$make_entry_point")
        echo >&2
        echo "The value '$1' is reserved as a Make entry point." >&2
        echo "-> Aborting (2)." >&2
        echo >&2
        exit 2
      esac
    done
    shift
  done
}

##
# Converts given string to a task name - e.g. for use as Make task.
#
# During conversion, some terms are abbreviated - e.g. :
#   - core-cache-clear -> cc
#   - host-registry -> host-reg (via registry/reg)
#   - logged-thread -> lt
#   - logged-batch -> lb
#   - logged-chain -> lc
#   - logged-sequence -> ls
#   - logged-loop -> ll
#   - logged-pipe -> lp
#   - lookup-path -> pl
#   - registry -> reg
#
# Stored in global ASC_SYNONYMS entries. E.g. :
# @see asc/env/global.vars.sh
#
# @param 1 String : input to convert.
# @param 2 [optional] String : the variable name in calling scope which will be
#   assigned the result. Defaults to 'task'.
#
# @var [default] task
#
f_make_task_name() {
  local p_str="$1"
  local p_itn_var_name="$2"

  if [[ -z "$p_itn_var_name" ]]; then
    p_itn_var_name='task'
  fi

  f_str_sanitize "$p_str" '-' 'p_str' '[^a-zA-Z0-9]'

  if [[ -n "$ASC_SYNONYMS" ]]; then
    local search_replace_pattern=''

    for search_replace_pattern in $ASC_SYNONYMS; do
      f_str_sanitize "$search_replace_pattern" '' 'search_replace_pattern' '[^a-zA-Z0-9\/\-_]'
      eval "p_str=\"\${p_str//$search_replace_pattern}\""
    done
  fi

  printf -v "$p_itn_var_name" '%s' "$p_str"
}

##
# Count '/' in a primitive pair (`subject/action` = 1, `subject/object/action` = 2).
#
# @param 1 String : primitive pair.
# @param 2 String : output variable name.
#
f_make_sp_pair_slash_count() {
  local p_pair="$1"
  local p_var="$2"
  local n=0
  local rest="$p_pair"

  while [[ "$rest" == */* ]]; do
    rest="${rest#*/}"
    n=$((n + 1))
  done

  printf -v "$p_var" '%s' "$n"
}

##
# Register or collide one make entry (keeps pivots_arr / real_scripts_arr zipped).
#
# Same namespace + deeper primitive pair replaces the script. Same namespace +
# shallower or equal depth skips. Returns 1 when the task exists in another
# namespace (caller prefixes).
#
# @requires pivots_arr, real_scripts_arr, pivot_ns_arr, pivot_sp_pairs_arr
#
f_make_register_entry_point() {
  local p_task="$1"
  local p_sp_pair="$2"
  local p_script="$3"
  local p_ns="$4"
  local i
  local old_depth=0
  local new_depth=0

  f_make_sp_pair_slash_count "$p_sp_pair" 'new_depth'

  for i in "${!pivots_arr[@]}"; do
    if [[ "${pivots_arr[i]}" != "$p_task" ]]; then
      continue
    fi

    if [[ "${pivot_ns_arr[i]}" == "$p_ns" ]]; then
      f_make_sp_pair_slash_count "${pivot_sp_pairs_arr[i]}" 'old_depth'

      if [[ $new_depth -gt $old_depth ]]; then
        real_scripts_arr[i]="$p_script"
        pivot_sp_pairs_arr[i]="$p_sp_pair"
      fi

      return 0
    fi

    return 1
  done

  pivots_arr+=("$p_task")
  real_scripts_arr+=("$p_script")
  pivot_ns_arr+=("$p_ns")
  pivot_sp_pairs_arr+=("$p_sp_pair")

  return 0
}

##
# Aggregates subject-action entry points to be used as Make tasks.
#
# This function writes its result to variables subject to collision in calling
# scope :
#
# @var pivots_arr
# @var real_scripts_arr
#
# @example
#   pivots_arr=()
#   real_scripts_arr=()
#
#   f_make_list_entry_points
#
#   for i in "${!real_scripts_arr[@]}"; do
#     task="${pivots_arr[i]}"
#     script="${real_scripts_arr[i]}"
#
#     echo "Make entry point $i :"
#     echo "  task = $task"
#     echo "  script = $script"
#   done
#
f_make_list_entry_points() {
  local extension
  local extension_var
  local extension_actions
  local extension_namespace
  local extension_iteration
  local pivot_ns_arr=()
  local pivot_sp_pairs_arr=()

  # From our "entry point" scripts' path, we need to provide a unique task
  # name -> we use subject-action pairs while preventing potential collisions
  # in case different extensions implement the same subject-action pair.
  # Important note : the arrays 'pivots_arr' and 'real_scripts_arr' must have the
  # exact same order and size.
  local task
  local sp_pair
  local ext_path

  for sp_pair in $ASC_ACTIONS; do
    task=''
    f_make_task_name "$sp_pair"

    case "$task" in instance-init|instance-setup)
      continue
      ;;
    instance-*)
      task="${task#*instance-}"
      ;;
    esac

    f_make_register_entry_point "$task" "$sp_pair" "asc/$sp_pair.sh" 'ASC'
  done

  # We need the custom 'extend' scripts folder to have priority for avoiding
  # "prefixed" aliases in case of collision with generic ASC extensions (so that
  # they get prefixed, not the project-specific implementation).
  # -> Move it first in iteration below.
  extension_iteration='extend'
  for extension in $ASC_EXTENSIONS; do
    case "$extension" in 'extend')
      continue
    esac
    extension_iteration+=" $extension"
  done

  for extension in $extension_iteration; do
    f_asc_extension_namespace "$extension"
    extension_var="${extension_namespace}_ACTIONS"
    extension_actions="${!extension_var}"

    if [[ -n "$extension_actions" ]]; then
      for sp_pair in $extension_actions; do
        task=''
        f_make_task_name "$sp_pair"

        case "$task" in instance-*)
          task="${task#*instance-}"
        esac

        ext_path=''
        f_asc_extension_path "$extension"

        if ! f_make_register_entry_point "$task" "$sp_pair" "$ext_path/$extension/$sp_pair.sh" "$extension"; then
          task="${extension}-$task"
          f_make_task_name "$task"
          f_make_register_entry_point "$task" "$sp_pair" "$ext_path/$extension/$sp_pair.sh" "$extension"
        fi
      done
    fi
  done
}

##
# Single source of truth for hardcoded Make entry points.
#
# Manually list our own hardcoded entries.
#
# @see asc/make/default.mk
#
# This function writes its result to variables subject to collision in calling
# scope :
#
# @var pivots_arr
# @var real_scripts_arr
#
# @example
#   pivots_arr=()
#   real_scripts_arr=()
#   f_make_list_hardcoded
#
f_make_list_hardcoded() {
  pivots_arr+=('init')
  real_scripts_arr+=('asc/instance/init.make.sh')
  pivots_arr+=('init-debug')
  real_scripts_arr+=('asc/instance/init.make.sh -d -r')
  # pivots_arr+=('reinit')
  # real_scripts_arr+=('asc/instance/reinit.sh')
  pivots_arr+=('setup')
  real_scripts_arr+=('asc/instance/setup.sh')
  pivots_arr+=('hook')
  real_scripts_arr+=('asc/instance/hook.make.sh')
  pivots_arr+=('hook-debug')
  real_scripts_arr+=('asc/instance/hook.make.sh -d -t')
  pivots_arr+=('globals-lp')
  real_scripts_arr+=('asc/env/global_lookup_paths.make.sh')
  pivots_arr+=('debug')
  real_scripts_arr+=('asc/make/echo.make.sh')
}

##
# Make cannot handle the '=' sign (by design).
#
# TODO [evol] find better workaround than the '∓' swap.
#
# @see asc/escape.sh
# @see asc/make/call_wrap.make.sh
#
f_make_unescape() {
  local p_arg="$1"
  local p_var_name="$2"

  if [[ -z "$p_var_name" ]]; then
    p_var_name='unescaped_arg'
  fi

  unescaped_arg="$p_arg"

  case "$p_arg" in *'\$'*)
    unescaped_arg="${unescaped_arg//'\$'/'$'}"
  esac

  case "$p_arg" in *'∓'*)
    unescaped_arg="${unescaped_arg//'∓'/'='}"
  esac

  # Debug
  # echo "u_make_unescape $p_var_name = $unescaped_arg"

  printf -v "$p_var_name" '%s' "$unescaped_arg"
}
