#!/usr/bin/env bash

##
# Implements hook -a 'fs_perms_set' -s 'app instance' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'.
#
# (Re)sets ASC-managed filesystem permissions.
#
# By default, only touches ./data, ./asc, ./scripts/asc, and ./.git. Application
# sources and project root entries are handled by extension hooks (e.g.
# fs_perms_pre_set) when needed.
#
# This file is dynamically included when the "hook" is triggered.
# @see u_instance_set_permissions() in asc/instance/instance.inc.sh
#
# To verify which files can be used (and will be sourced) when this hook is
# triggered :
# $ make hook-debug s:app instance a:fs_perms_set v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
#

# Whitelisted root files default permissions.
default_files=()
default_files+=('./.env')
default_files+=('./.gitconfig')
default_files+=('./.gitignore')
default_files+=('./env.yml')
default_files+=('./Makefile')

for f in "${default_files[@]}"; do
  if [[ ! -f "$f" ]]; then
    continue
  fi

  chmod "$FS_NW_FILES" "$f"
  check_chmod=$?

  if [ $check_chmod -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: 'chmod $FS_NW_FILES $f' exited with non-zero status ($check_chmod)." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
done

# ASC "core" files and folders default permissions.
if [[ -d './asc' ]]; then
  find './asc' -type f -exec chmod "$FS_NW_FILES" {} +
  find './asc' -type d -exec chmod "$FS_NW_DIRS" {} +
fi

# ASC project-specific files and folders default permissions.
if [[ -d './scripts' ]]; then
  chmod "$FS_NW_DIRS" './scripts'
  check_chmod=$?

  if [ $check_chmod -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi
fi

if [[ -d './scripts/asc' ]]; then
  chmod "$FS_NW_DIRS" './scripts/asc'
  check_chmod=$?

  if [ $check_chmod -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
    echo "-> Aborting (3)." >&2
    echo >&2
    exit 3
  fi

  find './scripts/asc' -type d -exec chmod "$FS_NW_DIRS" {} +
  find './scripts/asc' -type f -exec chmod "$FS_E_FILES" {} +
fi

# ASC "actions" - and the ones of its active extensions - need to be executable.
u_asc_get_actions

for f in "${asc_action_scripts[@]}"; do
  chmod "$FS_E_FILES" "$f"
  check_chmod=$?

  if [ $check_chmod -ne 0 ]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi
done

# Apply the ./data folder default permissions.

# Test files (*.test.sh in ./asc and ./scripts/asc) need to be executable.
# ASC make shortcut scripts as well.
for scope in './asc' './scripts/asc'; do
  if [[ ! -d "$scope" ]]; then
    continue
  fi

  # Test files (*.test.sh).
  file_list=''
  u_fs_file_list "$scope" '*.test.sh' 32

  for f in $file_list; do
    chmod "$FS_E_FILES" "$scope/$f"
    check_chmod=$?

    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (5)." >&2
      echo >&2
      exit 5
    fi
  done

  # ASC make shortcut scripts (*.make.sh). escape.sh lives only under ./asc.
  file_list=''
  u_fs_file_list "$scope" '*.make.sh' 32
  if [[ "$scope" == './asc' ]]; then
    file_list+=' escape.sh'
  fi

  for f in $file_list; do
    if [[ ! -f "$scope/$f" ]]; then
      continue
    fi

    chmod "$FS_E_FILES" "$scope/$f"
    check_chmod=$?

    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (6)." >&2
      echo >&2
      exit 6
    fi
  done
done

# Same for '.git' folders and files, except for git hooks which need executable
# file permissions.
if [[ -d './.git' ]]; then
  find './.git' -type f -exec chmod "$FS_NW_FILES" {} +
  find './.git' -type d -exec chmod "$FS_NW_DIRS" {} +

  if [[ -d './.git/hooks' ]]; then
    find './.git/hooks' -type f -exec chmod "$FS_E_FILES" {} +
  fi
fi

# Writeable dirs, if declared, must have their permissions enforced by default.
if [[ -n "$WRITEABLE_DIRS" ]]; then
  for d in $WRITEABLE_DIRS; do
    if [[ ! -d "$d" ]]; then
      continue
    fi

    chmod "$FS_W_DIRS" "$d"
    check_chmod=$?

    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (7)." >&2
      echo >&2
      exit 7
    fi
  done
fi


# Writeable files, if declared, must have their permissions enforced by default.
if [[ -n "$WRITEABLE_FILES" ]]; then
  for f in $WRITEABLE_FILES; do
    if [[ ! -f "$f" ]]; then
      continue
    fi

    chmod "$FS_E_FILES" "$f"
    check_chmod=$?

    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (8)." >&2
      echo >&2
      exit 8
    fi
  done
fi

# Executable files, if declared, must have their permissions enforced by default.
if [[ -n "$EXECUTABLE_FILES" ]]; then
  for f in $EXECUTABLE_FILES; do
    if [[ ! -f "$f" ]]; then
      continue
    fi

    chmod "$FS_E_FILES" "$f"
    check_chmod=$?

    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (9)." >&2
      echo >&2
      exit 9
    fi
  done
fi

# Protected files, if declared, must have their permissions enforced by default.
if [[ -n "$PROTECTED_FILES" ]]; then
  for f in $PROTECTED_FILES; do
    if [[ ! -f "$f" ]]; then
      continue
    fi

    chmod "$FS_P_FILES" "$f"
    check_chmod=$?

    if [ $check_chmod -ne 0 ]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: chmod exited with non-zero status ($check_chmod)." >&2
      echo "-> Aborting (10)." >&2
      echo >&2
      exit 10
    fi
  done
fi
