#!/usr/bin/env bash

##
# ASC core utility functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
#

##
# Initializes primitives (fundamental values for ASC extension mecanisms).
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
# 3. ASC_EXTENSIONS contains a list of folders using the same structure as
#   the 'asc' folder. The primitive mecanisms explained in 1 & 2 above apply
#   to each one of these extensions.
#   Important notes : extensions' folder names can only contain the following
#   characters : A-Z a-z 0-9 dots . underscores _ dashes -
#   Also, if the ASC customization dir (PROJECT_SCRIPTS = 'scripts' by default)
#   is altered, extensions can only be detected AFTER stack init has been run once.
#
# 4. The 'ASC_INC' values are a simple list of files to be sourced in
#   asc/bootstrap.sh scope directly. They are meant to contain bash functions
#   organized by subject. E.g. given subject = git : "$p_path/git/git.inc.sh".
#
u_asc_extend() {
  local p_path="$1"
  local p_namespace="$2"

  if [[ -z "$p_path" ]]; then
    p_path='asc'
  fi

  # Namespace defaults to the "$p_path" sanitized folder name (uppercase).
  if [[ -z "$p_namespace" ]]; then
    u_asc_extension_namespace "${p_path##*/}" 'p_namespace'
  fi

  # Always reinit as empty strings on every call to u_asc_extend().
  # @see asc/test/asc/hook.test.sh
  eval "export ${p_namespace}_SUBJECTS=''"
  eval "export ${p_namespace}_ACTIONS=''"

  # "Reusable" local var name.
  # @see u_asc_primitive_values()
  local primitive_values

  # Agregate subjects.
  primitive_values=''
  u_asc_primitive_values 'subjects' "$p_path"
  local subjects_list="$primitive_values"

  # Agregate remaining primitives.
  local inc
  local action
  local actions_list

  for subject in $subjects_list; do

    # Build up exported subjects list.
    eval "${p_namespace}_SUBJECTS+=\"$subject \""

    # Build up exported generic includes list (by subject).
    inc="$p_path/$subject/${subject}.inc.sh"
    if [[ -f "$inc" ]]; then
      # NB : this must not be namespaced, otherwise extensions' includes wouldn't
      # be loaded during bootstrap.
      ASC_INC+="$inc "
    fi

    primitive_values=''
    u_asc_primitive_values 'actions' "$p_path/$subject"
    actions_list="$primitive_values"

    for action in $actions_list; do
      # Build up exported actions list (by subject).
      eval "${p_namespace}_ACTIONS+=\"${subject}/$action \""
    done
  done

  # If extensions are detected, loop through each of them to aggregate namespaced
  # primitives + restrict this to ASC namespace only.
  if [[ "$p_namespace" == 'ASC' ]]; then
    export ASC_EXTENSIONS
    u_asc_extensions
  fi
}

##
# Loads extensions if any exist.
#
# @requires ASC_EXTENSIONS global in calling scope.
# @see u_asc_extend()
#
u_asc_extensions() {
  local inc
  local extension

  u_fs_dir_list "asc/extensions"
  for extension in $dir_list; do

    # Ignore dirnames starting with '.'.
    if [[ "${extension:0:1}" == '.' ]]; then
      continue
    fi

    ASC_EXTENSIONS+="$extension "

    # Aggregate namespaced primitives for every extension.
    u_asc_extend "asc/extensions/$extension"

    # For convenience, also accept generic includes at the root of extensions.
    inc="asc/extensions/$extension/${extension}.inc.sh"
    if [[ -f "$inc" ]]; then
      ASC_INC+="$inc "
    fi
  done
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
# @see u_asc_extend()
#
# @example
#   primitive_values=''
#   u_asc_primitive_values 'subjects'
#   echo "$primitive_values" # Yields 'app git host instance remote test'
#
#   # Default path 'asc' can be modified by providing the 2nd argument :
#   primitive_values=''
#   u_asc_primitive_values 'actions' 'path/to/extension/folder'
#   echo "$primitive_values"
#
u_asc_primitive_values() {
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
  local ignored_values=()
  local ignored_val
  for dn in $dotfile_names; do
    dotfile="$p_path/.${dn}_${p_primitive}_ignore"
    if [[ -f "$dotfile" ]]; then
      u_fs_get_file_contents "$dotfile" 'dotfile_contents'
      if [[ -n "$dotfile_contents" ]]; then
        for ignored_val in $dotfile_contents; do
          ignored_values+=("$ignored_val")
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
      u_fs_get_file_contents "$dotfile" 'dotfile_contents'
      if [[ -n "$dotfile_contents" ]]; then
        primitive_values="$dotfile_contents"
      fi
    fi
  done

  # Provide dynamic default values.
  if [[ $proceed == 1 ]]; then
    local dyn_values
    case "$p_primitive" in
      subjects)
        u_fs_dir_list "$p_path"
        dyn_values=$dir_list
      ;;
      actions)
        u_fs_file_list "$p_path"
        dyn_values=$file_list
      ;;
    esac

    # Filter out invalid values.
    # TODO should we forbid / sanitize unexpected characters (space, *, etc.) ?
    local v
    local v_wodots
    for v in $dyn_values; do

      # Always ignore values starting with a dot.
      if [[ "${v:0:1}" == '.' ]]; then
        continue
      fi

      # Leave out any value explicitly ignored via dotfile.
      if u_in_array "$v" ignored_values; then
        continue
      fi

      # Actions need to remove *.sh extension + ignore files using any double
      # extension pattern.
      if [[ "$p_primitive" == 'actions' ]]; then
        v="${v%%.sh}"
        v_wodots="${v//\.}"
        if (( ${#v} - ${#v_wodots} > 0 )); then
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
      u_fs_get_file_contents "$dotfile" 'dotfile_contents'
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
#   u_asc_extension_namespace "asc/extensions/docker-compose"
#   echo "$extension_namespace" # <- Prints DOCKER_COMPOSE.
#
#   # Using a custom variable name :
#   my_ns_var=""
#   for extension in $ASC_EXTENSIONS; do
#     u_asc_extension_namespace "$extension" 'my_ns_var'
#     echo "$my_ns_var"
#   done
#
u_asc_extension_namespace() {
  local p_ext="$1"
  local p_asc_ext_ns_var_name="$2"
  local asc_ext_ns_result

  if [[ -z "$p_asc_ext_ns_var_name" ]]; then
    p_asc_ext_ns_var_name='extension_namespace'
  fi

  asc_ext_ns_result="${p_ext##*/}"
  u_str_sanitize_var_name "$asc_ext_ns_result" 'asc_ext_ns_result'
  u_str_uppercase "$asc_ext_ns_result" 'asc_ext_ns_result'

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
#     if u_asc_namespace_has_subject "asc/extensions/$extension" 'db' ; then
#       echo "extension '$extension' has the 'db' subject"
#     fi
#   done
#
u_asc_namespace_has_subject() {
  local p_extension_path="$1"
  local p_subject="$2"

  local extension_subjects
  local extension_namespace

  u_asc_extension_namespace "$p_extension_path"
  eval "extension_subjects=\"\$${extension_namespace}_SUBJECTS\""

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
