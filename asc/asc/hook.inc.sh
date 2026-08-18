#!/usr/bin/env bash

##
# Hooks-related utility functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#

##
# Triggers an "event" optionally filtered by primitives.
#
# Arguments are all optional, but this function requires at least either
# 1 action (-a) OR 1 extension (-e). See explanations below.
#
# In order to "listen" to events, some specific file(s) must use the exact path
# and name corresponding to its arguments. For a detailed list of expected
# output given various inputs :
# @see asc/test/asc/hook.test.sh
#
# Primitives are fundamental values dynamically generated during bootstrap :
# @see asc/bootstrap.sh
# @see f_asc_extend()
#
# Calling this function will source all file includes matched by subject,
# action, prefix, variant, and extension. Every extension defines a base path from
# which additional lookup paths are derived (as well as a corresponding namespace
# for glabals containing their primitives).
#
# Important notes about the 'variants' (-v) argument :
# If this function gets called without any 'variant' filter(s), it will
# automatically look for suggestions using INSTANCE_TYPE.
# Variants are combinatory. Each variant value must be an existing glabal var
# which will generate the following lookup paths given the call :
# $ hook -a 'my_action' -s 'my_subject' -v 'PROVISION_USING INSTANCE_TYPE'
# + the values PROVISION_USING='compose' and INSTANCE_TYPE='dev' :
# - asc/my_subject/my_action.hook.sh
# - asc/my_subject/my_action.compose.hook.sh
# - asc/my_subject/my_action.compose.dev.hook.sh
# - asc/my_subject/my_action.dev.hook.sh
#
# @requires the following global variables in calling scope :
# - ASC_ACTIONS
# - ASC_SUBJECTS
# - ASC_EXTENSIONS
#
# @uses the following global variables in calling scope if they exist :
# - ${EXTENSION_NAMESPACE}_ACTIONS
# - ${EXTENSION_NAMESPACE}_SUBJECTS
#
# NB : the default separator used to concatenate parts in file names is
# the underscore '_', except for variants which use dot '.'.
# Dashes '-' are reserved for folder names and to separate "semver" suffixes.
# Semver suffixes can be used in extension folder names and variant values.
#
# Also note that each argument accepts several values by using a space to
# separate them. E.g. :
# $ hook -a 'start' -s 'stack service instance app'
#
# TODO Document cache warmup.
#
# @examples
#
#   # 1. When providing a single action :
#   hook -a 'bootstrap'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='prod')
#   # - asc/<ASC_SUBJECTS>/bootstrap.hook.sh
#   # - asc/<ASC_SUBJECTS>/bootstrap.prod.hook.sh
#   # - asc/extensions/<ASC_EXTENSIONS>/<EXT_SUBJECTS>/bootstrap.hook.sh
#   # - asc/extensions/<ASC_EXTENSIONS>/<EXT_SUBJECTS>/bootstrap.prod.hook.sh
#
#   # 2. When providing an action + a filter by subject :
#   hook -a 'init' -s 'stack'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='prod')
#   # - asc/stack/init.hook.sh
#   # - asc/stack/init.prod.hook.sh
#   # - asc/extensions/<ASC_EXTENSIONS>/stack/init.hook.sh
#   # - asc/extensions/<ASC_EXTENSIONS>/stack/init.prod.hook.sh
#
#   # 3. When providing an action + a filter by 1 or several subjects + 1 or
#   #   several variants filter :
#   hook -a 'init' -s 'stack' -v 'HOST_TYPE INSTANCE_TYPE'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='dev' and HOST_TYPE='local')
#   # - asc/stack/init.hook.sh
#   # - asc/stack/init.local.hook.sh
#   # - asc/stack/init.local.dev.hook.sh
#   # - asc/stack/init.dev.hook.sh
#   # - asc/extensions/<ASC_EXTENSIONS>/stack/init.hook.sh
#   # - asc/extensions/<ASC_EXTENSIONS>/stack/init.local.hook.sh
#   # - asc/extensions/<ASC_EXTENSIONS>/stack/init.local.dev.hook.sh
#   # - asc/extensions/<ASC_EXTENSIONS>/stack/init.dev.hook.sh
#
#   # 4. Extensions filter :
#   hook -e 'nodejs'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='prod')
#   # - scripts/extensions/nodejs/<EXT_SUBJECTS>/<SUBJECT_ACTIONS>.prod.hook.sh
#
#   # 5. Prefixes filter are exclusive by default, which means pure actions are
#   #   not included. Ex :
#   hook -a 'bootstrap' -p 'pre'
#   # Yields the following lookup paths (ALL includes found are sourced) :
#   # (given INSTANCE_TYPE='prod')
#   # - asc/<ASC_SUBJECTS>/pre_bootstrap.hook.sh
#   # - asc/<ASC_SUBJECTS>/pre_bootstrap.prod.hook.sh
#   # - asc/extensions/<ASC_EXTENSIONS>/<EXT_SUBJECTS>/pre_bootstrap.hook.sh
#   # - asc/extensions/<ASC_EXTENSIONS>/<EXT_SUBJECTS>/pre_bootstrap.prod.hook.sh
#
#   # 6. Project root dir additional lookup :
#   hook -s 'instance' -a 'env' -c 'yml' -v 'HOST_TYPE INSTANCE_TYPE' -t -r
#   # Yields the following lookup paths (not sourcing matches because -t flag) :
#   # (given HOST_TYPE='local' and INSTANCE_TYPE='dev')
#   # - asc/instance/env.yml
#   # - asc/instance/asc.local.yml
#   # - asc/instance/asc.local.dev.yml
#   # - asc/instance/asc.dev.yml
#   # - asc/extensions/<ASC_EXTENSIONS>/instance/env.yml
#   # - asc/extensions/<ASC_EXTENSIONS>/instance/asc.local.yml
#   # - asc/extensions/<ASC_EXTENSIONS>/instance/asc.local.dev.yml
#   # - asc/extensions/<ASC_EXTENSIONS>/instance/asc.dev.yml
#   # - env.yml
#   # - asc.local.yml
#   # - asc.local.dev.yml
#   # - asc.dev.yml
#
# We exceptionally name that function without following the usual convention.
#
hook() {
  # Update 2024-06 cache results.
  local cache_key="$@"
  local regex="-v ([^\-]+)"

  if [[ $cache_key =~ $regex ]]; then
    for var in ${BASH_REMATCH[1]}; do
      cache_key="${cache_key/$var/${!var}}"
    done
  fi

  cache_key="${cache_key// -/-}"
  f_str_sanitize_var_name "$cache_key" 'cache_key'
  local hook_cache_file="data/asc/cache/hook.${cache_key}.sh"

  if [[ -f "$hook_cache_file" ]]; then
    . "$hook_cache_file"
    return
  fi

  local hook_cache_contents=''

  local o_actions_filter
  local o_subjects_filter
  local o_prefixes_filter
  local o_variants_filter
  local o_extensions_filter
  local o_custom_filter
  local b_debug=0
  local b_dry_run=0
  local b_root_lookup=0
  local b_cache_warmup=0

  # Parse current function arguments.
  # See https://stackoverflow.com/a/31443098
  while [ "$#" -gt 0 ]; do
    case "$1" in
      # Options format : 1 dash + arg 'name' + space + value ("o_*" prefix).
      -a) o_actions_filter="$2"; shift 2;;
      -s) o_subjects_filter="$2"; shift 2;;
      -p) o_prefixes_filter="$2"; shift 2;;
      -v) o_variants_filter="$2"; shift 2;;
      -e) o_extensions_filter="$2"; shift 2;;
      -c) o_custom_filter="$2"; shift 2;;
      # Flag (arg without any value) = boolean ("b_*" prefix).
      -d) b_debug=1; shift 1;;
      -t) b_dry_run=1; shift 1;;
      -r) b_root_lookup=1; shift 1;;
      -w) b_cache_warmup=1; shift 1;;
      # Prevent unhandled arguments.
      -*) echo "Error in $BASH_SOURCE line $LINENO: unknown option: $1" >&2; return 1;;
      *) echo "Error in $BASH_SOURCE line $LINENO: unsupported unnamed argument: $1" >&2; return 2;;
    esac
  done

  # Enforce minimum conditions for triggering hook (see 5 in function docblock).
  if [ -z "$o_actions_filter" ] && [ -z "$o_extensions_filter" ] && [ -z "$o_variants_filter" ]; then
    echo
    echo "Error in $BASH_SOURCE line $LINENO: cannot trigger hook without either 1 action (or 1 extension + 1 variant)." >&2
    echo "-> Aborting." >&2
    echo
    return 1
  fi

  local prim_var
  local subjects="$ASC_SUBJECTS"
  local actions="$ASC_ACTIONS"
  local extensions="$ASC_EXTENSIONS"
  local variants=""
  local prefixes=""

  local base_paths_arr=("asc")
  local extension
  local uppercase
  local ext_path

  # Doc contract: without -v, still suggest INSTANCE_TYPE variants.
  # @see function docblock above (Important notes about the 'variants' argument)
  if [[ -z "$o_variants_filter" ]]; then
    variants='INSTANCE_TYPE'
  fi

  # Allow using only a particular extension (see the '-p' argument).
  if [ -n "$o_extensions_filter" ]; then
    for extension in $o_extensions_filter; do
      uppercase="$extension"
      f_str_sanitize_var_name "$uppercase" 'uppercase'
      f_str_uppercase "$uppercase"
      prim_var="${uppercase}_SUBJECTS"
      subjects="${!prim_var}"
      prim_var="${uppercase}_ACTIONS"
      actions="${!prim_var}"
      # Override base path for lookups.
      ext_path=''
      f_asc_extension_path "$extension"
      base_paths_arr=("$ext_path/$extension")
    done

  # By default, any extension can append its own "primitives".
  # NB : this process will create duplicates e.g. when extension has identical
  # subject(s) than asc core. They are dealt with below.
  # @see f_asc_extend()
  elif [ -n "$extensions" ]; then
    for extension in $extensions; do
      uppercase="$extension"
      f_str_sanitize_var_name "$uppercase" 'uppercase'
      f_str_uppercase "$uppercase"
      prim_var="${uppercase}_SUBJECTS"
      subjects+=" ${!prim_var}"
      prim_var="${uppercase}_ACTIONS"
      actions+=" ${!prim_var}"
      # Every extension defines an additional base path for lookups.
      ext_path=''
      f_asc_extension_path "$extension"
      base_paths_arr+=("$ext_path/$extension")
    done
  fi

  # Triggering a hook requires subjects and actions.
  if [ -z "$subjects" ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: cannot trigger hook without any subjects." >&2
    echo "-> Aborting." >&2
    echo >&2
    return 2
  fi

  # Apply filters.
  local filters='subjects actions prefixes variants'
  local f
  local f_arg
  local f_arg_var
  local s
  local a
  local arg_val
  local dedup
  local deduo_val
  local deduo_arr

  for f in $filters; do

    # Use the same loop to remove potential duplicate values (cf. extensions above).
    dedup="${!f}"
    deduo_arr=()
    for deduo_val in $dedup; do
      f_array_add_once "$deduo_val" deduo_arr
    done
    eval "$f=\"${deduo_arr[@]}\""

    f_arg_var="o_${f}_filter"
    f_arg="${!f_arg_var}"
    if [ -z "$f_arg" ]; then
      continue
    fi

    declare "$f"=''

    case "$f" in
      subjects|prefixes|variants)
        for arg_val in $f_arg; do
          declare "$f"+="$arg_val "
        done
      ;;
      actions)
        for arg_val in $f_arg; do
          for s in $subjects; do
            declare "$f"+="$s/$arg_val "
          done
        done
      ;;
    esac
  done

  # Debug.
  # if [ $b_debug -eq 1 ]; then
  #   echo
  #   echo "debug hook call :"
  #   echo "  base_paths_arr :"
  #   f_array_print 'base_paths_arr'
  #   echo "  subjects = '$subjects'"
  #   echo "  actions = '$actions'"
  #   echo "  extensions = '$extensions'"
  #   echo "  variants = '$variants'"
  #   echo "  prefixes = '$prefixes'"
  # fi

  # Build lookup paths.
  local lookup_paths_arr=()
  local lookup_subject

  for lookup_subject in $subjects; do
    f_hook_build_lookup_by_subject "$lookup_subject" "$o_custom_filter"
  done

  # Add support for project root lookup.
  if [ $b_root_lookup -eq 1 ]; then
    f_hook_build_project_root_dir_lookup "$o_actions_filter" "$o_custom_filter"
  fi

  # Debug.
  if [ $b_debug -eq 1 ]; then
    local debug_msg
    debug_msg='hook'
    if [[ -n "$o_subjects_filter" ]]; then
      debug_msg+=" -s '$o_subjects_filter'"
    fi
    if [[ -n "$o_actions_filter" ]]; then
      debug_msg+=" -a '$o_actions_filter'"
    fi
    if [[ -n "$o_custom_filter" ]]; then
      debug_msg+=" -c '$o_custom_filter'"
    fi
    if [[ -n "$o_variants_filter" ]]; then
      debug_msg+=" -v '$o_variants_filter'"
    fi
    if [[ -n "$o_prefixes_filter" ]]; then
      debug_msg+=" -p '$o_prefixes_filter'"
    fi
    if [[ -n "$o_extensions_filter" ]]; then
      debug_msg+=" -e '$o_extensions_filter'"
    fi
    if [ $b_root_lookup -eq 1 ]; then
      debug_msg+=" -r"
    fi
    f_autoload_print_lookup_paths lookup_paths_arr "$debug_msg"
  fi

  # Source each file include (with optional override mecanism).
  # Non-dry-run: seed colocated *.opt-inc.sh into the same cache file (1a).
  # @see asc/utilities/autoload.sh
  # @see f_hook_opt_inc_append_candidates()
  local inc
  local src
  local oi
  local matched_hooks_arr=()
  local opt_incs_arr=()

  for inc in "${lookup_paths_arr[@]}"; do
    if [ -f "$inc" ]; then
      # Note : for tests, the "dry run" option prevents "override" alterations.
      # @see asc/test/asc/hook.test.sh
      # @see hook_ms()
      if [ $b_dry_run -eq 1 ]; then
        hook_dry_run_matches+="$inc
"
        continue
      fi

      # Derive opt-incs from the lookup path (extension/project location), not
      # from an override path under scripts/overrides.
      f_hook_opt_inc_append_candidates "$inc" opt_incs_arr

      f_hook_resolve_source_path "$inc" 'src'
      matched_hooks_arr+=("$src")
    fi
  done

  if [ $b_dry_run -eq 1 ]; then
    hook_cache_contents+="hook_dry_run_matches=\"$hook_dry_run_matches\""
  else
    if [[ ${#opt_incs_arr[@]} -gt 0 ]]; then
      hook_cache_contents+="# --- opt-inc (seeded) ---
"

      for oi in "${opt_incs_arr[@]}"; do
        f_hook_resolve_source_path "$oi" 'src'
        hook_cache_contents+=". $src
"

        if [[ $b_cache_warmup -ne 1 ]]; then
          . "$src"
        fi
      done
    fi

    if [[ ${#matched_hooks_arr[@]} -gt 0 ]]; then
      hook_cache_contents+="# --- hooks ---
"

      for src in "${matched_hooks_arr[@]}"; do
        hook_cache_contents+=". $src
"

        if [[ $b_cache_warmup -ne 1 ]]; then
          . "$src"
        fi
      done
    fi
  fi

  if [[ $b_debug -eq 1 && ${#opt_incs_arr[@]} -gt 0 ]]; then
    echo
    echo "Seeded opt-inc paths :"

    for oi in "${opt_incs_arr[@]}"; do
      echo "  - $oi"
    done
  fi

  cat > "$hook_cache_file" <<CACHE
#!/usr/bin/env bash

##
# Generated cache file for hook $cache_key
#
# @see asc/utilities/hook.sh
#

$hook_cache_contents

CACHE

  # Debug.
  # echo "New cache written for hook $cache_key"
}

##
# Adds hook lookup paths by subject.
#
# Side note : we could have every subject implement every other subjects' hooks,
# if we wanted to. E.g. env/app_bootstrap.hook.sh, etc. - but #YAGNI (mentionned
# here for potential future re-evaluation).
#
# @requires the following vars in calling scope :
# - $base_paths_arr
# - $lookup_paths_arr
# - $filters
# - $actions
#
# @uses the following optional vars in calling scope if available :
# - $prefixes
# - $variants
# - $o_prefixes_filter
#
# @see hook()
# @see f_autoload_add_lookup_level()
#
f_hook_build_lookup_by_subject() {
  local o_subject="$1"
  local a_suffix_override="$2"

  local bp

  local a_path
  local a_parts_arr
  local a

  local x_prim
  local x_parts_arr
  local x_val
  local x_values

  local v_prim
  local v_parts_arr
  local v
  local v_values
  local v_val
  local v_flag
  local v_fallback

  # By default, this function will produce lookup paths using the default
  # double-extension pattern "*.hook.sh". This can be altered when using the
  # custom filter argument (-c).
  local suffix='hook.sh'
  if [[ -n "$a_suffix_override" ]]; then
    suffix="$a_suffix_override"
  fi

  for bp in "${base_paths_arr[@]}"; do

    # Avoid lookups for namespaces not having the subject we're looking for.
    if ! f_asc_namespace_has_subject "$bp" "$o_subject" ; then
      continue
    fi

    for a_path in $actions; do

      # Ignore actions not "belonging" to current subject.
      case "$a_path" in "$o_subject"*)

        # First, add "pure" actions suggestions - unless excluded (see prefixes).
        if [[ -z "$o_prefixes_filter" ]]; then
          lookup_paths_arr+=("$bp/${a_path}.${suffix}")
        fi

        f_str_split1 'a_parts_arr' "$a_path" '/'
        a="${a_parts_arr[1]}"

        # Then add "prefixed" actions suggestions.
        for x_val in $prefixes; do
          lookup_paths_arr+=("$bp/$o_subject/${x_val}_${a}.${suffix}")
        done

        # Finally, add the variants suggestions.
        for v_prim in $variants; do
          v_val="${!v_prim}"
          f_hook_variant_values_add "$v_prim" "$v_val" 'v_values'
        done

        # Now that we fetched variants actual values, add them as as suggestions
        # unless excluded (see prefixes). These are combinatory, e.g. :
        # - init.local.dev.hook.sh
        # - bootstrap.compose.dev.hook.sh
        # - bootstrap.docker-compose.prod.remote.hook.sh
        f_str_subsequences "$v_values" '.'
        if [[ -z "$o_prefixes_filter" ]]; then
          for v_val in $str_subsequences; do
            f_autoload_add_lookup_level "$bp/$o_subject/${a}." "$suffix" "$v_val" lookup_paths_arr
          done
        fi

        # Implement prefix + variant lookup paths, e.g. :
        # pre_bootstrap.compose.hook.sh
        for x_val in $prefixes; do
          for v_val in $str_subsequences; do
            f_autoload_add_lookup_level "$bp/$o_subject/${x_val}_${a}." "$suffix" "$v_val" lookup_paths_arr
          done
        done
      esac
    done
  done
}

##
# Adds hook lookup paths in project root dir.
#
# @requires the following vars in calling scope :
# - $lookup_paths_arr
# - $filters
# - $actions
#
# @uses the following optional vars in calling scope if available :
# - $prefixes
# - $variants
# - $o_prefixes_filter
#
# @see hook()
# @see f_autoload_add_lookup_level()
#
f_hook_build_project_root_dir_lookup() {
  local o_action="$1"
  local a_suffix_override="$2"

  local a

  local x_prim
  local x_parts_arr
  local x_val
  local x_values

  local v_prim
  local v_parts_arr
  local v
  local v_values
  local v_val
  local v_flag
  local v_fallback

  # TODO [evol] Whitelist possible values ?
  a="$o_action"

  # By default, this function will produce lookup paths using the default
  # double-extension pattern "*.hook.sh". This can be altered when using the
  # custom filter argument (-c).
  local suffix='hook.sh'
  if [[ -n "$a_suffix_override" ]]; then
    suffix="$a_suffix_override"
  fi

  # First, add "pure" actions suggestions - unless excluded (see prefixes).
  if [[ -z "$o_prefixes_filter" ]]; then
    lookup_paths_arr+=("${a}.${suffix}")
  fi

  # Then add "prefixed" actions suggestions.
  for x_val in $prefixes; do
    lookup_paths_arr+=("${x_val}_${a}.${suffix}")
  done

  # Finally, add the variants suggestions.
  for v_prim in $variants; do
    v_val="${!v_prim}"
    f_hook_variant_values_add "$v_prim" "$v_val" 'v_values'
  done

  # Now that we fetched variants actual values, add them as as suggestions
  # unless excluded (see prefixes). These are combinatory, e.g. :
  # - init.local.dev.hook.sh
  # - bootstrap.compose.dev.hook.sh
  # - bootstrap.docker-compose.prod.remote.hook.sh
  f_str_subsequences "$v_values" '.'
  if [[ -z "$o_prefixes_filter" ]]; then
    for v_val in $str_subsequences; do
      f_autoload_add_lookup_level "${a}." "$suffix" "$v_val" lookup_paths_arr
    done
  fi

  # Implement prefix + variant lookup paths, e.g. :
  # pre_bootstrap.compose.hook.sh
  for x_val in $prefixes; do
    for v_val in $str_subsequences; do
      f_autoload_add_lookup_level "${x_val}_${a}." "$suffix" "$v_val" lookup_paths_arr
    done
  done
}

##
# Same as hook() except it will only source the "most specific" match.
#
# This notion is totally arbitrary here - it will use the file having the
# deepest path and the highest number of dots in its path. In case of equality,
# the first match will be used.
#
# This "score" - a simple addition of slash & dot count in the filepath - allows
# to differenciate ASC's file-name-based implementations (hooks, globals,
# etc.) because of the way its patterns work :
#   - multiple extension (i.e. variants : pre_bootstrap.compose.hook.sh)
#   - complements (e.g. scripts/asc/extend/test/asc.hook.sh)
#   - overrides (e.g. scripts/overrides/extensions/compose/instance/init.compose.hook.sh)
# @see hook()
#
# NB : We must give some advantage to the project-specific 'scripts' path in
# comparison to generic ASC extensions so that the custom implementations always
# take precedence over extensions'.
# -> Any implementation located in './scripts' gets +4 to its score.
#
# TODO [evol] Attempt to implement some control over which one gets sourced
# in case of equality.
#
# [optional] (re)sets the following var in calling scope :
# @var most_specific_match
#
# @example
#   # Basic usage - only sources 1 match (the "most specific") :
#   hook_ms -s 'instance' -a 'registry_get' -v 'HOST_TYPE'
#
#   # Dry run example.
#   # @see f_stack_template() in asc/extensions/compose/stack/stack.inc.sh
#   most_specific_match=''
#   hook_ms 'dry-run' -s 'stack' -a 'compose' -c "yml" -v 'DC_YML_VARIANTS' -t
#   echo "$most_specific_match" # <- Prints the most specific "compose.yml" found.
#
hook_ms() {
  local msdr_flag=0

  # Here we "preprocess" specific arguments and remove them if found to avoid
  # breaking the call to hook() below.
  # For now, only the first is checked - but we may have to loop through all of
  # them if we need more later on.
  case $1 in
    # Request to set an existing var in calling scope to the most specific match
    # found (instead of sourcing it).
    'dry-run')
      msdr_flag=1
      shift 1
    ;;
  esac

  local f
  local depth=0
  local dot_arr
  local slash_arr
  local highest_depth=0
  local hook_dry_run_matches=''

  # Dry-run writes this in calling scope (not local). Callers init it:
  #   most_specific_match=''
  #   hook_ms 'dry-run' …
  most_specific_match=''

  # Forwards all arguments while forcing the "dry run" (-t) flag.
  hook -t "$@"

  for f in $hook_dry_run_matches; do
    f_str_split1 'dot_arr' "$f" '.'
    f_str_split1 'slash_arr' "$f" '/'

    # Debug
    # echo "f.${#dot_arr[@]}.${#slash_arr[@]} : $f"
    # f_array_print dot_arr
    # f_array_print slash_arr

    depth=${#dot_arr[@]}
    depth=$(( depth + ${#slash_arr[@]} ))

    # Apply score bonus to custom project implementations so they take
    # precedence over extensions'.
    case "$f" in "scripts/"*)
      depth=$(( depth + 4 ))
    esac

    # Files in project root dir, when requested (-r), must have higher priority
    # than the default, generic extensions' (even the ones in scripts/*).
    if [[ ${#slash_arr[@]} -eq 1 ]]; then
      depth=$(( depth + 10 ))
    fi

    # Debug
    # echo "  -> adjusted depth = $depth"

    if [[ $depth -ge $highest_depth ]]; then
      most_specific_match="$f"
      highest_depth=$depth
    fi
  done

  if [[ -n "$most_specific_match" ]] && [[ -f "$most_specific_match" ]]; then
    # If the "dry run" flag is requested, it bypasses the override mechanism.
    # TODO can we workaround this ?
    if [[ $msdr_flag -eq 1 ]]; then
      most_specific_match="$most_specific_match"
      return
    fi

    # Seed implementer opt-incs before the hook body (same derivation as hook 1a).
    # @see f_hook_source_opt_incs_for_path()
    f_hook_source_opt_incs_for_path "$most_specific_match"

    f_autoload_override "$most_specific_match" 'continue'
    eval "$inc_override_evaled_code"

    . "$most_specific_match"
  fi
}

##
# Return space-separated provision variant tokens for file/hook lookups.
#
# Dual-compat: compose and docker-compose resolve to both.
#
f_provision_using_lookup_values() {
  local a_provision_using="${1:-${PROVISION_USING:-}}"

  case "$a_provision_using" in
    compose|docker-compose)
      printf '%s' 'compose docker-compose'
      ;;
    *)
      if [[ -n "$a_provision_using" ]]; then
        printf '%s' "$a_provision_using"
      fi
      ;;
  esac
}

##
# Append variant value(s) to a space-separated lookup list.
#
# Expands PROVISION_USING via f_provision_using_lookup_values().
#
f_hook_variant_values_add() {
  local a_v_prim="$1"
  local a_v_val="$2"
  local a_v_values_var_name="$3"
  local current="${!a_v_values_var_name}"
  local alias_val

  if [[ "$a_v_prim" == 'PROVISION_USING' ]]; then
    for alias_val in $(f_provision_using_lookup_values "$a_v_val"); do
      if [[ "$current" != *"$alias_val"* ]]; then
        current+="$alias_val "
      fi
    done
  elif [[ -n "$a_v_val" ]] && [[ "$current" != *"$a_v_val"* ]]; then
    current+="$a_v_val "
  fi

  printf -v "$a_v_values_var_name" '%s' "$current"
}

##
# Append dir-local *.opt-inc.sh candidates for a *.hook.sh filepath.
#
# For path <dir>/<name>[.<variants>].hook.sh appends (if they exist, deduped):
#   <dir>/<subject>.opt-inc.sh   # subject = last component of <dir>
#   <dir>/<action>.opt-inc.sh    # action = <name> before first '.'
#
# Non-*.hook.sh paths are ignored (e.g. custom -c suffix lookups).
#
# @param 1 String : hook filepath
# @param 2 String : name of array in calling scope to append to
#
# @see hook()
# @see changelog/2026/07/16-asc-include-splitting-hook-mapped-deps.md
#
f_hook_opt_inc_append_candidates() {
  local a_hook_path="$1"
  local -n a_out_arr_nameref="$2" # Bash 4.3 +

  local dir
  local base
  local subject
  local action
  local candidate
  local existing
  local found

  if [[ -z "$a_hook_path" ]]; then
    return 0
  fi

  base="${a_hook_path##*/}"

  case "$base" in
    *.hook.sh) ;;
    *) return 0 ;;
  esac

  dir="${a_hook_path%/*}"

  if [[ "$dir" == "$a_hook_path" ]]; then
    dir='.'
  fi

  base="${base%.hook.sh}"
  action="${base%%.*}"
  subject="${dir##*/}"

  for candidate in \
    "${dir}/${subject}.opt-inc.sh" \
    "${dir}/${action}.opt-inc.sh"
  do
    if [[ ! -f "$candidate" ]]; then
      continue
    fi

    found=0

    for existing in "${a_out_arr_nameref[@]}"; do
      if [[ "$existing" == "$candidate" ]]; then
        found=1
        break
      fi
    done

    if [[ $found -eq 1 ]]; then
      continue
    fi

    a_out_arr_nameref+=("$candidate")
  done
}

##
# Resolve scripts/overrides counterpart for a path (if any).
#
# Writes the override path when it exists, otherwise the original.
#
# @param 1 String : filepath relative to PROJECT_DOCROOT
# @param 2 [optional] String : output var name (default: hook_resolve_source_path).
#
# @see f_autoload_override()
#
f_hook_resolve_source_path() {
  local a_path="$1"
  local a_output_var_name="${2:-hook_resolve_source_path}"
  local override="${a_path/asc/scripts/overrides}"

  if [[ -f "$override" ]]; then
    printf -v "$a_output_var_name" '%s' "$override"
  else
    printf -v "$a_output_var_name" '%s' "$a_path"
  fi
}

##
# Source dir-local opt-incs for one hook path (most-specific / ad hoc).
#
# @param 1 String : hook filepath
#
# @see f_hook_opt_inc_append_candidates()
# @see hook_ms()
#
f_hook_source_opt_incs_for_path() {
  local a_hook_path="$1"
  local opt_incs_arr=()
  local oi
  local src

  f_hook_opt_inc_append_candidates "$a_hook_path" opt_incs_arr

  for oi in "${opt_incs_arr[@]}"; do
    f_hook_resolve_source_path "$oi" 'src'
    . "$src"
  done
}
