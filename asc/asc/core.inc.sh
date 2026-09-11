#!/usr/bin/env bash

##
# ASC core utility functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
#

##
# Initializes primitives (fundamental values for ASC extension mechanisms).
#
# @param 1 [optional] String relative path (defaults to 'asc' = ASC "core").
#   Provides a extension folder without trailing slash.
# @param 2 [optional] String globals "namespace" (defaults to the uppercase name
#   of the folder passed as 1st arg).
#
# Exports the following "namespaced" global variables, effectively initializing
# all primitives required by hooks - e.g. given p_namespace='ASC' (default value
# of 2nd argument) :
# @export ASC_SUBJECTS (See 1)
# @export ASC_ACTIONS (See 2)
# @export ASC_EXTENSIONS (See 3)
# @export ASC_INC (See 4)
#
# @see hook()
#
# This process uses dotfiles similar to .gitignore (e.g. asc/.asc_subjects_ignore).
# they control hooks lookup paths generation. See explanations below.
#
# 1. By default, ASC_SUBJECTS contains the list of depth 1 folders names in ./asc.
#   If the dotfile '.asc_subjects' is present in current level, it overrides
#   the entire list and may introduce values that are not folders (see below).
#   If the dotfile '.asc_subjects_append' exists, its values are added.
#   If the dotfile '.asc_subjects_ignore' exists, its values are removed from
#     the list of subjects (level 1 folders by default).
#
# 2. ASC_ACTIONS provides a list of *.sh files per subject : for each
#   ASC_SUBJECTS, it will generate values consisting of the file name (without
#   extension, see "Conventions" documentation).
#   The dotfiles '.asc_actions', '.asc_actions_append' and '.asc_actions_ignore'
#   have the same role as the 'subjects' ones described in 1 but must be placed
#   inside relevant subject's folder.
#
# 3. ASC_EXTENSIONS contains a list of all active extensions. Each one uses the
#   same structure as the 'asc' folder. The primitive mecanisms explained in
#   1 & 2 above apply to each one of these extensions.
#   Core extensions are listed by folder name under asc/extensions.
#   Contrib extensions are listed as $vendor/$extension (relative to
#   scripts/asc/contrib). The name 'extend' is reserved for project-specific
#   implementations under scripts/asc/extend.
#   Important notes : extension folder names can only contain the following
#   characters : A-Z a-z 0-9 dots . underscores _ dashes -
#
# 4. The 'ASC_INC' values are a simple list of files to be sourced in
#   asc/bootstrap.sh scope directly. They are meant to contain bash functions
#   organized by subject. E.g. given subject = git : "$p_path/git/git.inc.sh".
#   For convenience, any file matching the scripts/asc/*.inc.sh pattern will
#   also be added. This gives a place to put some custom project-specific
#   functions that would not necessarily be pertinent in a subject dir.
#
f_asc_extend() {
  local p_path="$1"
  local p_namespace="$2"

  if [[ -z "$p_path" ]]; then
    p_path='asc'
  fi

  # Namespace defaults to the "$p_path" sanitized folder name (uppercase).
  if [[ -z "$p_namespace" ]]; then
    f_asc_extension_namespace "${p_path##*/}" 'p_namespace'
  fi

  # Always reinit as empty strings on every call to f_asc_extend().
  # @see asc/test/asc/hook.test.sh
  export "${p_namespace}_SUBJECTS"=''
  export "${p_namespace}_ACTIONS"=''

  # "Reusable" local var name.
  # @see f_asc_primitive_values()
  local primitive_values

  # Agregate subjects.
  primitive_values=''
  f_asc_primitive_values 'subjects' "$p_path"
  local subjects_list="$primitive_values"

  # Agregate remaining primitives.
  local inc
  local action
  local actions_list

  for subject in $subjects_list; do

    # Build up exported subjects list.
    export "${p_namespace}_SUBJECTS"+="$subject "

    # Build up exported generic includes list (by subject).
    inc="$p_path/$subject/${subject}.inc.sh"
    if [[ -f "$inc" ]]; then
      # NB : this must not be namespaced, otherwise extensions' includes wouldn't
      # be loaded during bootstrap.
      ASC_INC+="$inc "
    fi

    primitive_values=''
    f_asc_primitive_values 'actions' "$p_path/$subject"
    actions_list="$primitive_values"

    for action in $actions_list; do
      # Build up exported actions list (by subject).
      export "${p_namespace}_ACTIONS"+="${subject}/$action "
    done
  done

  # Debug.
  # local subjects_var="${p_namespace}_SUBJECTS"
  # echo "$subjects_var = '${!subjects_var}'"
  # local actions_var="${p_namespace}_ACTIONS"
  # echo "$actions_var = '${!actions_var}'"

  # If extensions are detected, loop through each of them to aggregate namespaced
  # primitives + restrict this to ASC namespace only.
  if [[ "$p_namespace" == 'ASC' ]]; then
    export ASC_EXTENSIONS
    f_asc_extensions

    # Convenience additional INC lookup for project-specific functions.
    if [[ -d scripts/asc ]]; then
      for inc in scripts/asc/*.inc.sh; do
        if [[ -f "$inc" ]]; then
          ASC_INC+="$inc "
        fi
      done
    fi

    # Update 2024-06 cache results.
    # @see asc/bootstrap.sh
    asc_primitives_cache_str+="
ASC_INC='$ASC_INC'
ASC_SUBJECTS='$ASC_SUBJECTS'
ASC_ACTIONS='$ASC_ACTIONS'
ASC_EXTENSIONS='$ASC_EXTENSIONS'
"
  else
    local prefixed_subjects_var="${p_namespace}_SUBJECTS"
    local prefixed_actions_var="${p_namespace}_ACTIONS"
    asc_primitives_cache_str+="
$prefixed_subjects_var='${!prefixed_subjects_var}'
$prefixed_actions_var='${!prefixed_actions_var}'
"
  fi
}

##
# Loads the active '.asc_extensions_ignore' contents.
#
# @requires local var $extensions_ignore_arr in calling scope.
#
# Lookups in this order (the last found takes precedence) :
# - .asc_extensions_ignore
# - .$HOST_TYPE.asc_extensions_ignore
# - .$INSTANCE_TYPE.asc_extensions_ignore
# - .$STACK_VERSION.asc_extensions_ignore
# - .$HOST_TYPE.$INSTANCE_TYPE.asc_extensions_ignore
# - .$STACK_VERSION.$HOST_TYPE.asc_extensions_ignore
# - .$STACK_VERSION.$INSTANCE_TYPE.asc_extensions_ignore
# - .$STACK_VERSION.$HOST_TYPE.$INSTANCE_TYPE.asc_extensions_ignore
#
# Unprefixed entries apply to asc/extensions. Prefixed entries (e.g. asc/apache)
# apply to scripts/asc/contrib.
#
f_asc_extensions_ignore_load() {
  local extensions_ignore_filepath='.asc_extensions_ignore'
  local ei_override_lookup_arr=()
  local ei_override
  local exclusions
  local excl

  extensions_ignore_arr=()

  if [[ -n "$HOST_TYPE" ]]; then
    ei_override_lookup_arr+=(".$HOST_TYPE.asc_extensions_ignore")
  fi

  if [[ -n "$INSTANCE_TYPE" ]]; then
    ei_override_lookup_arr+=(".$INSTANCE_TYPE.asc_extensions_ignore")
  fi

  if [[ -n "$STACK_VERSION" ]]; then
    ei_override_lookup_arr+=(".$STACK_VERSION.asc_extensions_ignore")
  fi

  if [[ -n "$HOST_TYPE" && -n "$INSTANCE_TYPE" ]]; then
    ei_override_lookup_arr+=(".$HOST_TYPE.$INSTANCE_TYPE.asc_extensions_ignore")
  fi

  if [[ -n "$STACK_VERSION" && -n "$HOST_TYPE" ]]; then
    ei_override_lookup_arr+=(".$STACK_VERSION.$HOST_TYPE.asc_extensions_ignore")
  fi

  if [[ -n "$STACK_VERSION" && -n "$INSTANCE_TYPE" ]]; then
    ei_override_lookup_arr+=(".$STACK_VERSION.$INSTANCE_TYPE.asc_extensions_ignore")
  fi

  if [[ -n "$STACK_VERSION" && -n "$HOST_TYPE" && -n "$INSTANCE_TYPE" ]]; then
    ei_override_lookup_arr+=(".$STACK_VERSION.$HOST_TYPE.$INSTANCE_TYPE.asc_extensions_ignore")
  fi

  for ei_override in "${ei_override_lookup_arr[@]}"; do
    if [[ -f "$ei_override" ]]; then
      extensions_ignore_filepath="$ei_override"
    fi
  done

  if [[ -f "$extensions_ignore_filepath" ]]; then
    f_fs_get_file_contents "$extensions_ignore_filepath" 'exclusions'

    if [[ -n "$exclusions" ]]; then
      for excl in $exclusions; do
        extensions_ignore_arr+=("$excl")
      done
    fi
  fi
}

##
# Discovers extension identities present on disk (no ignore, no loading).
#
# Core : folder names under asc/extensions.
# Contrib : $vendor/$extension under scripts/asc/contrib.
# Project-specific : 'extend' when scripts/asc/extend exists.
#
# @requires local var $discovered_extensions in calling scope.
#
f_asc_extensions_discover() {
  local extension
  local contrib_root='scripts/asc/contrib'
  local contrib_vendors
  local vendor
  local custom_extend_path='scripts/asc/extend'

  discovered_extensions=''

  f_fs_dir_list "asc/extensions"

  for extension in $dir_list; do
    if [[ "${extension:0:1}" == '.' ]]; then
      continue
    fi

    discovered_extensions+="$extension "
  done

  if [[ -d "$contrib_root" ]]; then
    f_fs_dir_list "$contrib_root"
    contrib_vendors="$dir_list"

    for vendor in $contrib_vendors; do
      if [[ "${vendor:0:1}" == '.' ]]; then
        continue
      fi

      f_fs_dir_list "$contrib_root/$vendor"

      for extension in $dir_list; do
        if [[ "${extension:0:1}" == '.' ]]; then
          continue
        fi

        discovered_extensions+="$vendor/$extension "
      done
    done
  fi

  if [[ -d "$custom_extend_path" ]]; then
    discovered_extensions+="extend "
  fi
}

##
# True when a discovered extension is disabled by '.asc_extensions_ignore'.
#
# The reserved name 'extend' is never ignored.
#
# @param 1 String : extension identity (folder name or $vendor/$extension).
#
f_asc_extension_ignored() {
  local p_extension="$1"
  local ignored_name

  case "$p_extension" in
    extend)
      return 1
      ;;
  esac

  for ignored_name in "${extensions_ignore_arr[@]}"; do
    if [[ "$ignored_name" == "$p_extension" ]]; then
      return 0
    fi
  done

  return 1
}

##
# Loads extensions if any exist.
#
# @requires ASC_EXTENSIONS global in calling scope.
# @see f_asc_extend()
#
f_asc_extensions() {
  local inc
  local extension
  local ext_path
  local inc_stem
  local extensions_ignore_arr
  local discovered_extensions

  f_asc_extensions_ignore_load
  f_asc_extensions_discover

  for extension in $discovered_extensions; do
    if f_asc_extension_ignored "$extension"; then
      continue
    fi

    ASC_EXTENSIONS+="$extension "

    ext_path=''
    f_asc_extension_path "$extension"
    f_asc_extend "$ext_path/$extension"

    inc_stem="${extension##*/}"
    inc="$ext_path/$extension/${inc_stem}.inc.sh"

    if [[ -f "$inc" ]]; then
      ASC_INC+="$inc "
    fi
  done
}

##
# Get extension path by name.
#
# @requires local var $ext_path in calling scope.
# This function modifies an existing variable for performance reasons (in order
# to avoid using a subshell).
#
# @example
#   ext_path=''
#   f_asc_extension_path 'extend'
#   echo "$ext_path" # Yields 'scripts/asc'
#
#   ext_path=''
#   f_asc_extension_path 'asc/apache'
#   echo "$ext_path" # Yields 'scripts/asc/contrib'
#
f_asc_extension_path() {
  ext_path='asc/extensions'
  case "$1" in
    extend)
      ext_path='scripts/asc'
      ;;
    */*)
      ext_path='scripts/asc/contrib'
      ;;
  esac
}

##
# Provides primitive values for given path.
#
# @requires local var $primitive_values in calling scope.
# This function modifies an existing variable for performance reasons (in order
# to avoid using a subshell).
#
# @param 1 String which primitive values to get (lowercase).
# @param 2 [optional] String relative path (defaults to 'asc' = ASC "core").
#   Provides a extension folder without trailing slash.
# @param 3 [optional] String an 'action' value.
#
# Dotfiles MUST contain a list of words without any special characters nor
# spaces. The values provided will determine dynamic includes lookup paths :
# @see f_asc_extend()
#
# @example
#   primitive_values=''
#   f_asc_primitive_values 'subjects'
#   echo "$primitive_values" # Yields 'app  cache  git  host  instance  make  test'
#
#   # Default path 'asc' can be modified by providing the 2nd argument :
#   primitive_values=''
#   f_asc_primitive_values 'actions' 'path/to/extension/folder'
#   echo "$primitive_values"
#
f_asc_primitive_values() {
  local p_primitive="$1"
  local p_path="$2"
  local p_action="$3"

  if [[ -z "$p_path" ]]; then
    p_path='asc'
  fi

  local dotfile
  local dotfile_contents

  # For prefixes and variants primitives, hardcoded default values are used
  # during the generation of lookup paths unless specific dotfiles per action
  # exist. This extra dotfile (per action) does not cancel out the base dotfile
  # (per subject) - its values are simply added if both exist.
  local dn
  local dotfile_names='asc'

  # case "$p_primitive" in variants|prefixes)
  if [[ -n "$p_action" ]]; then
    dotfile_names+=" asc_$p_action"
  fi
  # esac

  # Look for the dotfile that provides explictly ignored values.
  local ignored_values_arr=()
  local ignored_val

  for dn in $dotfile_names; do
    dotfile="$p_path/.${dn}_${p_primitive}_ignore"

    if [[ -f "$dotfile" ]]; then
      f_fs_get_file_contents "$dotfile" 'dotfile_contents'

      if [[ -n "$dotfile_contents" ]]; then
        for ignored_val in $dotfile_contents; do
          ignored_values_arr+=("$ignored_val")
        done
      fi
    fi
  done

  # Look for the dotfile that will override all default values.
  local proceed=1

  for dn in $dotfile_names; do
    dotfile="$p_path/.${dn}_${p_primitive}"

    if [[ -f "$dotfile" ]]; then
      proceed=0
      f_fs_get_file_contents "$dotfile" 'dotfile_contents'

      if [[ -n "$dotfile_contents" ]]; then
        primitive_values="$dotfile_contents"
      fi
    fi
  done

  # Provide dynamic default values.
  if [[ $proceed -eq 1 ]]; then
    local dyn_values

    case "$p_primitive" in
      subjects)
        f_fs_dir_list "$p_path"
        dyn_values=$dir_list
      ;;
      actions)
        f_fs_file_list "$p_path"
        dyn_values=$file_list
      ;;
    esac

    # Filter out invalid values.
    local v
    local v_dots_arr

    for v in $dyn_values; do

      # Always ignore values starting with a dot.
      if [[ "${v:0:1}" == '.' ]]; then
        continue
      fi

      # Leave out any value explicitly ignored via dotfile.
      if f_in_array "$v" 'ignored_values_arr'; then
        continue
      fi

      # Actions need to remove *.sh extension + ignore files using any double
      # extension pattern.
      if [[ "$p_primitive" == 'actions' ]]; then
        v="${v%%.sh}"
        f_str_split1 'v_dots_arr' "$v" '.'

        if [[ ${#v_dots_arr[@]} -gt 1 ]]; then
          continue
        fi
      fi

      primitive_values+=" $v "
    done
  fi

  # Look for the dotfile that provides additional values + add them if it exists.
  for dn in $dotfile_names; do
    dotfile="$p_path/.${dn}_${p_primitive}_append"

    if [[ -f "$dotfile" ]]; then
      f_fs_get_file_contents "$dotfile" 'dotfile_contents'

      if [[ -n "$dotfile_contents" ]]; then
        local added_val

        for added_val in $dotfile_contents; do
          primitive_values+=" $added_val "
        done
      fi
    fi
  done
}

##
# Gets a ASC extension namespace.
#
# @param 1 String : extension folder name or path.
# @param 2 [optional] String : the variable name in calling scope which will be
#   assigned the result. Defaults to 'extension_namespace'.
#
# @var [default] extension_namespace
#
# @example
#   f_asc_extension_namespace "asc/extensions/compose"
#   echo "$extension_namespace" # <- Prints DOCKER_COMPOSE.
#
#   # Using a custom variable name :
#   my_ns_var=""
#   for extension in $ASC_EXTENSIONS; do
#     f_asc_extension_namespace "$extension" 'my_ns_var'
#     echo "$my_ns_var"
#   done
#
f_asc_extension_namespace() {
  local p_ext="$1"
  local p_asc_ext_ns_var_name="$2"
  local asc_ext_ns_result

  if [[ -z "$p_asc_ext_ns_var_name" ]]; then
    p_asc_ext_ns_var_name='extension_namespace'
  fi

  asc_ext_ns_result="${p_ext##*/}"
  f_str_sanitize_var_name "$asc_ext_ns_result" 'asc_ext_ns_result'
  f_str_uppercase "$asc_ext_ns_result" 'asc_ext_ns_result'

  printf -v "$p_asc_ext_ns_var_name" '%s' "$asc_ext_ns_result"
}

##
# Checks if a namespace has given subject.
#
# @param 1 String : extension path (or folder name).
# @param 2 String : the subject to check against.
#
# @example
#   for extension in $ASC_EXTENSIONS; do
#     if f_asc_namespace_has_subject "asc/extensions/$extension" 'db' ; then
#       echo "extension '$extension' has the 'db' subject"
#     fi
#   done
#
f_asc_namespace_has_subject() {
  local p_extension_path="$1"
  local p_subject="$2"

  local extension_subjects
  local extension_subjects_var
  local extension_namespace

  f_asc_extension_namespace "$p_extension_path"
  extension_subjects_var="${extension_namespace}_SUBJECTS"
  extension_subjects="${!extension_subjects_var}"

  if [[ -n "$extension_subjects" ]]; then
    local s
    for s in $extension_subjects; do
      case "$p_subject" in "$s")
        return
      esac
    done
  fi

  false
}

##
# Tests if an extension is exists and is enabled.
#
# @param 1 String : the extension (folder) name.
#
# @example
#   ext='db'
#   if f_asc_extension_exists "$ext"; then
#     echo "The '$ext' extension exists and is enabled"
#   else
#     echo "The '$ext' extension is not enabled or doesn't exist"
#   fi
#
f_asc_extension_exists() {
  case "$ASC_EXTENSIONS" in *" $1 "*|"$1 "*)
    return 0
  esac
  return 1
}
