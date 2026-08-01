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
# all primitives required by hooks - e.g. given a_namespace='ASC' (default value
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
# 3. ASC_EXTENSIONS contains a list of all active extensions' folder names. Each
#   one uses the same structure as the 'asc' folder. The primitive mecanisms
#   explained in 1 & 2 above apply to each one of these extensions.
#   Important notes : extensions' folder names can only contain the following
#   characters : A-Z a-z 0-9 dots . underscores _ dashes -
#   Exception : the name 'extend' is reserved for project-specific
#   implementations.
#
# 4. The 'ASC_INC' values are a simple list of files to be sourced in
#   asc/bootstrap.sh scope directly. They are meant to contain bash functions
#   organized by subject. E.g. given subject = git : "$a_path/git/git.inc.sh".
#   For convenience, any file matching the scripts/asc/*.inc.sh pattern will
#   also be added. This gives a place to put some custom project-specific
#   functions that would not necessarily be pertinent in a subject dir.
#
f_asc_extend() {
  local a_path="$1"
  local a_namespace="$2"

  if [[ -z "$a_path" ]]; then
    a_path='asc'
  fi

  # Namespace defaults to the "$a_path" sanitized folder name (uppercase).
  if [[ -z "$a_namespace" ]]; then
    f_asc_extension_namespace "${a_path##*/}" 'a_namespace'
  fi

  # Always reinit as empty strings on every call to f_asc_extend().
  # @see asc/test/asc/hook.test.sh
  export "${a_namespace}_SUBJECTS"=''
  export "${a_namespace}_ACTIONS"=''

  # "Reusable" local var name.
  # @see f_asc_primitive_values()
  local primitive_values

  # Agregate subjects.
  primitive_values=''
  f_asc_primitive_values 'subjects' "$a_path"
  local subjects_list="$primitive_values"

  # Agregate remaining primitives.
  local inc
  local action
  local actions_list

  for subject in $subjects_list; do

    # Build up exported subjects list.
    export "${a_namespace}_SUBJECTS"+="$subject "

    # Build up exported generic includes list (by subject).
    inc="$a_path/$subject/${subject}.inc.sh"
    if [[ -f "$inc" ]]; then
      # NB : this must not be namespaced, otherwise extensions' includes wouldn't
      # be loaded during bootstrap.
      ASC_INC+="$inc "
    fi

    primitive_values=''
    f_asc_primitive_values 'actions' "$a_path/$subject"
    actions_list="$primitive_values"

    for action in $actions_list; do
      # Build up exported actions list (by subject).
      export "${a_namespace}_ACTIONS"+="${subject}/$action "
    done
  done

  # Debug.
  # local subjects_var="${a_namespace}_SUBJECTS"
  # echo "$subjects_var = '${!subjects_var}'"
  # local actions_var="${a_namespace}_ACTIONS"
  # echo "$actions_var = '${!actions_var}'"

  # If extensions are detected, loop through each of them to aggregate namespaced
  # primitives + restrict this to ASC namespace only.
  if [[ "$a_namespace" == 'ASC' ]]; then
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
    local prefixed_subjects_var="${a_namespace}_SUBJECTS"
    local prefixed_actions_var="${a_namespace}_ACTIONS"
    asc_primitives_cache_str+="
$prefixed_subjects_var='${!prefixed_subjects_var}'
$prefixed_actions_var='${!prefixed_actions_var}'
"
  fi
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
  local exclusions_arr
  local exclusions
  local excl
  local custom_extend_path
  local extensions_ignore_filepath
  local ei_override_lookup_arr
  local ei_override

  # ALlow to deactivate some extensions using dotfile '.asc_extensions_ignore'.
  # This file can be overridden in project-specific scripts/asc/override folder.
  exclusions_arr=()
  extensions_ignore_filepath='asc/extensions/.asc_extensions_ignore'

  # The following lookups will be used in this order (the last found takes
  # precedence) :
  # - scripts/asc/override/.asc_extensions_ignore (convenience default path)
  # - scripts/asc/override/extensions/.asc_extensions_ignore (normal override)
  # - scripts/asc/override/.${PROVISION_USING}.asc_extensions_ignore
  # - scripts/asc/override/.${INSTANCE_DOMAIN}.asc_extensions_ignore
  ei_override_lookup_arr=()
  ei_override_lookup_arr+=('scripts/asc/override/.asc_extensions_ignore')
  ei_override_lookup_arr+=('scripts/asc/override/extensions/.asc_extensions_ignore')
  if [[ -n "$PROVISION_USING" ]]; then
    ei_override_lookup_arr+=("scripts/asc/override/.${PROVISION_USING}.asc_extensions_ignore")
  fi
  if [[ -n "$INSTANCE_DOMAIN" ]]; then
    ei_override_lookup_arr+=("scripts/asc/override/.${INSTANCE_DOMAIN}.asc_extensions_ignore")
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
        exclusions_arr+=("$excl")
      done
    fi
  fi

  f_fs_dir_list "asc/extensions"
  for extension in $dir_list; do

    # Ignore dirnames starting with '.'.
    if [[ "${extension:0:1}" == '.' ]]; then
      continue
    fi

    # Exclusions check.
    if f_in_array "$extension" exclusions_arr; then
      continue
    fi

    ASC_EXTENSIONS+="$extension "

    # Aggregate namespaced primitives for every extension.
    f_asc_extend "asc/extensions/$extension"

    # For convenience, also accept generic includes at the root of extensions.
    inc="asc/extensions/$extension/${extension}.inc.sh"
    if [[ -f "$inc" ]]; then
      ASC_INC+="$inc "
    fi
  done

  # Consider "scripts/asc/extend" as an extension. This allows to
  # provide any implementation like "normal" ASC extensions meant for current
  # project-specific operations (non-reusable).
  custom_extend_path="scripts/asc/extend"
  if [[ -d "$custom_extend_path" ]]; then
    ASC_EXTENSIONS+="extend "
    f_asc_extend "$custom_extend_path"
    inc="$custom_extend_path/extend.inc.sh"
    if [[ -f "$inc" ]]; then
      ASC_INC+="$inc "
    fi
  fi
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
f_asc_extension_path() {
  ext_path='asc/extensions'
  case "$1" in 'extend')
    ext_path='scripts/asc'
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
  local a_primitive="$1"
  local a_path="$2"
  local a_action="$3"

  if [[ -z "$a_path" ]]; then
    a_path='asc'
  fi

  local dotfile
  local dotfile_contents

  # For prefixes and variants primitives, hardcoded default values are used
  # during the generation of lookup paths unless specific dotfiles per action
  # exist. This extra dotfile (per action) does not cancel out the base dotfile
  # (per subject) - its values are simply added if both exist.
  local dn
  local dotfile_names='asc'
  # case "$a_primitive" in variants|prefixes)
  if [[ -n "$a_action" ]]; then
    dotfile_names+=" asc_$a_action"
  fi
  # esac

  # Look for the dotfile that provides explictly ignored values.
  local ignored_values_arr=()
  local ignored_val
  for dn in $dotfile_names; do
    dotfile="$a_path/.${dn}_${a_primitive}_ignore"
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
    dotfile="$a_path/.${dn}_${a_primitive}"
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
    case "$a_primitive" in
      subjects)
        f_fs_dir_list "$a_path"
        dyn_values=$dir_list
      ;;
      actions)
        f_fs_file_list "$a_path"
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
      if [[ "$a_primitive" == 'actions' ]]; then
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
    dotfile="$a_path/.${dn}_${a_primitive}_append"
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
  local a_ext="$1"
  local a_asc_ext_ns_var_name="$2"
  local asc_ext_ns_result

  if [[ -z "$a_asc_ext_ns_var_name" ]]; then
    a_asc_ext_ns_var_name='extension_namespace'
  fi

  asc_ext_ns_result="${a_ext##*/}"
  f_str_sanitize_var_name "$asc_ext_ns_result" 'asc_ext_ns_result'
  f_str_uppercase "$asc_ext_ns_result" 'asc_ext_ns_result'

  printf -v "$a_asc_ext_ns_var_name" '%s' "$asc_ext_ns_result"
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
  local a_extension_path="$1"
  local a_subject="$2"

  local extension_subjects
  local extension_subjects_var
  local extension_namespace

  f_asc_extension_namespace "$a_extension_path"
  extension_subjects_var="${extension_namespace}_SUBJECTS"
  extension_subjects="${!extension_subjects_var}"

  if [[ -n "$extension_subjects" ]]; then
    local s
    for s in $extension_subjects; do
      case "$a_subject" in "$s")
        return
      esac
    done
  fi

  false
}

##
# Gets all actions + their script path defined in current project instance.
#
# NB : for performance reasons (to avoid using a subshell), this function
# writes its result to variables subject to collision in calling scope.
#
# @var asc_action_names_arr
# @var asc_action_scripts_arr
#
# @example
#   f_asc_get_actions
#   # Check result (names) :
#   declare -p asc_action_names_arr
#   # -> output (names) :
#   #   declare -a asc_action_names_arr='([0]="app/compile" [1]="app/git" ...)'
#   # Check result (script files path) :
#   for f in "${asc_action_scripts_arr[@]}"; do
#     echo "$f"
#   done
#
# @example (sorted)
#   f_asc_get_actions
#   f_array_qsort "${asc_action_names_arr[@]}"
#   f_array_print sorted_arr
#
f_asc_get_actions() {
  local subjects="$ASC_SUBJECTS"
  local actions="$ASC_ACTIONS"
  local extensions="$ASC_EXTENSIONS"
  local base_paths_arr=("asc")

  local a
  local s
  local bp
  local extension
  local uppercase
  local ext_path
  local subjects_var
  local actions_var

  asc_action_names_arr=()
  asc_action_scripts_arr=()

  for extension in $extensions; do
    uppercase="$extension"
    f_str_sanitize_var_name "$uppercase" 'uppercase'
    f_str_uppercase "$uppercase"
    subjects_var="${uppercase}_SUBJECTS"
    subjects+=" ${!subjects_var}"
    actions_var="${uppercase}_ACTIONS"
    actions+=" ${!actions_var}"
    ext_path=''
    f_asc_extension_path "$extension"
    base_paths_arr+=("$ext_path/$extension")
  done

  for s in $subjects; do
    for bp in "${base_paths_arr[@]}"; do
      if ! f_asc_namespace_has_subject "$bp" "$s" ; then
        continue
      fi
      for a in $actions; do
        case "$a" in "$s"*)
          lookup_path="$bp/${a}.sh"
          if [[ -f "$lookup_path" ]]; then
            if ! f_in_array $lookup_path asc_action_scripts_arr; then
              asc_action_names_arr+=("$a")
              asc_action_scripts_arr+=("$lookup_path")
            fi
          fi
        esac
      done
    done
  done
}

##
# Prints a list of Makefiles includes.
#
# The default location is a file called 'make.mk' inside the extension folder.
# Only paths that exist are listed (space-separated) for each currently active
# extension. Missing files are skipped so ASC_MAKE_INC stays free of ghosts.
#
# @example
#   lookup_paths_arr="$(f_asc_extensions_get_makefiles)"
#   echo "$lookup_paths_arr"
#
f_asc_extensions_get_makefiles() {
  local mk_includes_lp=''
  local asc_gm_ext=''
  local ext_path=''
  local mk_file=''

  for asc_gm_ext in $ASC_EXTENSIONS; do
    ext_path=''
    f_asc_extension_path "$asc_gm_ext"
    mk_file="$ext_path/$asc_gm_ext/make.mk"

    if [[ -f "$mk_file" ]]; then
      mk_includes_lp+="$mk_file "
    fi
  done

  echo "$mk_includes_lp"
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
