#!/usr/bin/env bash

##
# Make-related utility functions.
#
# This file is sourced during core ASC bootstrap.
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
  local make_entries_arr=()
  local real_scripts_arr=()

  f_make_list_hardcoded
  f_make_list_entry_points

  if [[ -z "${make_entries_arr[@]}" ]]; then
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
    for make_entry_point in "${make_entries_arr[@]}"; do
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
#   - asc-cache-clear -> cc
#   - host-dependency -> dep
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
  local a_str="$1"
  local a_itn_var_name="$2"

  if [[ -z "$a_itn_var_name" ]]; then
    a_itn_var_name='task'
  fi

  f_str_sanitize "$a_str" '-' 'a_str' '[^a-zA-Z0-9]'

  if [[ -n "$ASC_SYNONYMS" ]]; then
    local search_replace_pattern=''

    for search_replace_pattern in $ASC_SYNONYMS; do
      f_str_sanitize "$search_replace_pattern" '' 'search_replace_pattern' '[^a-zA-Z0-9\/\-_]'
      eval "a_str=\"\${a_str//$search_replace_pattern}\""
    done
  fi

  printf -v "$a_itn_var_name" '%s' "$a_str"
}

##
# Aggregates subject-action entry points to be used as Make tasks.
#
# This function writes its result to variables subject to collision in calling
# scope :
#
# @var make_entries_arr
# @var real_scripts_arr
#
# @example
#   make_entries_arr=()
#   real_scripts_arr=()
#
#   f_make_list_entry_points
#
#   for i in "${!real_scripts_arr[@]}"; do
#     task="${make_entries_arr[i]}"
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

  # From our "entry point" scripts' path, we need to provide a unique task
  # name -> we use subject-action pairs while preventing potential collisions
  # in case different extensions implement the same subject-action pair.
  # Important note : the arrays 'make_entries_arr' and 'real_scripts_arr' must have the
  # exact same order and size.
  local task
  local sa_pair
  local ext_path

  # No need to check for collisions in ASC core (we know there aren't any).
  for sa_pair in $ASC_ACTIONS; do
    task=''
    f_make_task_name "$sa_pair"

    # The 'instance' subject is a special case : we remove it to explicitly make
    # it the default subject. All actions belonging to the 'instance' subject
    # are transformed to the action part alone.
    # Exception : instance-init -> init = already hardcoded, so prevent adding
    # it twice. Same for setup.
    # @see asc/instance/init.make.sh
    # @see Makefile (the one in PROJECT_DOCROOT path).
    case "$task" in instance-*)
      case "$task" in instance-init|instance-setup)
        continue
      esac
      task="${task#*instance-}"
    esac

    make_entries_arr+=("$task")
    real_scripts_arr+=("asc/$sa_pair.sh")
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
      # Extensions' subject-action pairs must yield unique tasks -> check for
      # collisions.
      for sa_pair in $extension_actions; do
        task=''
        f_make_task_name "$sa_pair"

        case "$task" in instance-*)
          task="${task#*instance-}"
        esac

        if f_in_array "$task" 'make_entries_arr'; then
          task="${extension}-$task"
          f_make_task_name "$task"
        fi

        make_entries_arr+=("$task")
        ext_path=''
        f_asc_extension_path "$extension"
        # TODO [minor] Figure out why this can produce duplicate entries.
        # real_scripts_arr+=("$ext_path/$extension/$sa_pair.sh")
        f_array_add_once "$ext_path/$extension/$sa_pair.sh" real_scripts_arr
      done
    fi
  done
}

##
# Writes make entrypoints to data/asc/generated.mk
#
# Generates a Makefile include with tasks corresponding to every subject-action
# in current instance.
#
# Also generates a script called before any make entry point to do the same as :
# @see f_make_check_args()
#
f_make_generate() {
  local i
  local make_entry_point
  local real_script

  local make_entries_arr=()
  local real_scripts_arr=()

  # All except the hardcoded ones.
  f_make_list_entry_points

  if [[ -z "$real_scripts_arr" ]]; then
    echo "Notice in f_make_generate() - $BASH_SOURCE line $LINENO: no Make entry points have been found."
    return
  fi

  echo "Writing Makefile include data/asc/generated.mk ..."

  cat > data/asc/generated.mk <<'EOF'

##
# Current instance Makefile include.
#
# Contains generic tasks for subject-action entry points (default scripts).
#
# This file is automatically generated during "instance init", and it will be
# entirely overwritten every time it is executed.
#
# @see f_instance_init() in asc/instance/instance.inc.sh
# @see f_make_generate() in asc/make/make.inc.sh
#

EOF

  for i in "${!make_entries_arr[@]}"; do
    make_entry_point="${make_entries_arr[i]}"
    real_script="${real_scripts_arr[i]}"

    echo ".PHONY: $make_entry_point
$make_entry_point:
	@ asc/make/call_wrap.make.sh $real_script \$(MAKECMDGOALS)
" >> data/asc/generated.mk

  done

  f_make_generate_test_cases

  echo "Writing Makefile include data/asc/generated.mk : done."
  echo

  # We'll also need to generate a "normal" shell script (not bash) to check
  # that among all arguments sent to a Make entry point, none are "reserved"
  # values - i.e. that would trigger unwanted other targets.
  echo "Creating cache file data/asc/cache/make.sh ..."

  # Including the hardcoded ones (this is only used for the safety check).
  f_make_list_hardcoded

  local cache_file='data/asc/cache/make.sh'
  local make_entries_code_gen=''
  local real_scripts_code_gen=''

  # Replace contents in case cache file exists.
  cat > "$cache_file" <<'SHELL_SCRIPT_HEAD'
#!/usr/bin/env bash

##
# Cache the list of make entry points.
#
# This script is generated during "instance init".
#
# @see f_instance_init() in asc/instance/instance.inc.sh
# @see f_make_generate() in asc/make/make.inc.sh
#

make_entries_arr=()
real_scripts_arr=()

SHELL_SCRIPT_HEAD

  for i in "${!make_entries_arr[@]}"; do
    make_entry_point="${make_entries_arr[i]}"
    real_script="${real_scripts_arr[i]}"

    make_entries_code_gen+="make_entries_arr+=('$make_entry_point')
"
    real_scripts_code_gen+="real_scripts_arr+=('$real_script')
"
  done

  if [[ -f data/asc/cache/test-cases.sh ]]; then
    # shellcheck disable=SC1090
    . data/asc/cache/test-cases.sh
    for make_entry_point in "${test_case_registry_targets_arr[@]}"; do
      make_entries_code_gen+="make_entries_arr+=('$make_entry_point')
"
      real_scripts_code_gen+="real_scripts_arr+=('asc/test/case.run.sh')
"
    done
  fi

  echo '' >> "$cache_file"
  echo "$make_entries_code_gen" >> "$cache_file"
  echo '' >> "$cache_file"
  echo "$real_scripts_code_gen" >> "$cache_file"

  echo "Creating cache file data/asc/cache/make.sh : done."
  echo
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
# @var make_entries_arr
# @var real_scripts_arr
#
# @example
#   make_entries_arr=()
#   real_scripts_arr=()
#   f_make_list_hardcoded
#
f_make_list_hardcoded() {
  make_entries_arr+=('init')
  real_scripts_arr+=('asc/instance/init.make.sh')
  make_entries_arr+=('init-debug')
  real_scripts_arr+=('asc/instance/init.make.sh -d -r')
  # make_entries_arr+=('reinit')
  # real_scripts_arr+=('asc/instance/reinit.sh')
  make_entries_arr+=('setup')
  real_scripts_arr+=('asc/instance/setup.sh')
  make_entries_arr+=('hook')
  real_scripts_arr+=('asc/instance/hook.make.sh')
  make_entries_arr+=('hook-debug')
  real_scripts_arr+=('asc/instance/hook.make.sh -d -t')
  make_entries_arr+=('globals-lp')
  real_scripts_arr+=('asc/env/global_lookup_paths.make.sh')
  make_entries_arr+=('debug')
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
  local a_arg="$1"
  local a_var_name="$2"

  if [[ -z "$a_var_name" ]]; then
    a_var_name='unescaped_arg'
  fi

  unescaped_arg="$a_arg"

  case "$a_arg" in *'\$'*)
    unescaped_arg="${unescaped_arg//'\$'/'$'}"
  esac

  case "$a_arg" in *'∓'*)
    unescaped_arg="${unescaped_arg//'∓'/'='}"
  esac

  # Debug
  # echo "u_make_unescape $a_var_name = $unescaped_arg"

  printf -v "$a_var_name" '%s' "$unescaped_arg"
}

##
# Append per-case make targets and write test-case registry cache.
#
# Uses make_entries_arr and real_scripts_arr arrays from calling scope (f_make_generate).
#
f_make_generate_test_cases() {
  local batch_task=''
  local batch_script=''
  local case_stem=''
  local case_target=''
  local cache_file="${ASC_TEST_CASE_CACHE:-data/asc/cache/test-cases.sh}"
  local cache_dir
  local i=''

  local -a tc_targets_arr=()
  local -a tc_batch_tasks_arr=()
  local -a tc_stems_arr=()
  local -a tc_modes_arr=()
  local -a tc_batch_dirs_arr=()
  local -a tc_batch_scripts_arr=()

  if [[ -z "$cache_file" ]]; then
    cache_file='data/asc/cache/test-cases.sh'
  fi

  cache_dir="${cache_file%/*}"
  mkdir -p "$cache_dir"

  for i in "${!make_entries_arr[@]}"; do
    batch_task="${make_entries_arr[i]}"
    batch_script="${real_scripts_arr[i]}"

    test_case_mode=''
    test_case_batch_dir=''
    test_case_stems=''

    f_test_discover_batch_cases "$batch_script" || continue

    for case_stem in $test_case_stems; do
      case_target="$(f_test_case_make_target "$batch_task" "$case_stem")"

      if f_in_array "$case_target" 'tc_targets_arr'; then
        continue
      fi

      tc_targets_arr+=("$case_target")
      tc_batch_tasks_arr+=("$batch_task")
      tc_stems_arr+=("$case_stem")
      tc_modes_arr+=("$test_case_mode")
      tc_batch_dirs_arr+=("$test_case_batch_dir")
      tc_batch_scripts_arr+=("$batch_script")

      echo ".PHONY: $case_target
$case_target:
	@ asc/make/call_wrap.make.sh asc/test/case.run.sh \$(MAKECMDGOALS)
" >> data/asc/generated.mk
    done
  done

  if [[ ${#tc_targets_arr[@]} -eq 0 ]]; then
    rm -f "$cache_file"
    return 0
  fi

  echo "Writing test-case registry ${cache_file} ..."

  cat > "$cache_file" <<'EOF'
#!/usr/bin/env bash

##
# Generated test-case registry for f_test_run_case_by_target().
#
# @see f_make_generate_test_cases() in asc/make/make.inc.sh
#

test_case_registry_targets_arr=()
test_case_registry_batch_tasks_arr=()
test_case_registry_stems_arr=()
test_case_registry_modes_arr=()
test_case_registry_batch_dirs_arr=()
test_case_registry_batch_scripts_arr=()

EOF

  {
    for i in "${!tc_targets_arr[@]}"; do
      echo "test_case_registry_targets_arr+=('${tc_targets_arr[i]}')"
      echo "test_case_registry_batch_tasks_arr+=('${tc_batch_tasks_arr[i]}')"
      echo "test_case_registry_stems_arr+=('${tc_stems_arr[i]}')"
      echo "test_case_registry_modes_arr+=('${tc_modes_arr[i]}')"
      echo "test_case_registry_batch_dirs_arr+=('${tc_batch_dirs_arr[i]}')"
      echo "test_case_registry_batch_scripts_arr+=('${tc_batch_scripts_arr[i]}')"
      echo ''
    done
  } >> "$cache_file"

  echo "Writing test-case registry ${cache_file} : done."
  echo
}
