#!/usr/bin/env bash

##
# Upgrades ASC from the source repo on Github.
#
# Deletes and replaces the following folders with contents from ASC main public
# repo :
# - asc
# - scripts/asc/contrib/asc
#
# It leaves everything else untouched.
#
# The remote branch/tag is overridable using a global named 'ASC_BRANCH'
# (defaults to 'main').
#
# @example
#   make asc-upgrade
#   # Or :
#   asc/asc/upgrade.sh
#
#   # Upgrade from a specific branch or tag :
#   ASC_BRANCH=main make asc-upgrade
#
#   # If the temporary directory already exists, use existing folder without
#   # prompt :
#   make asc-upgrade n
#   # Or :
#   asc/asc/upgrade.sh n
#
#   # If the temporary directory already exists, force re-download the sources
#   # from remote repo without prompt :
#   make asc-upgrade y
#   # Or :
#   asc/asc/upgrade.sh y
#
#   # To keep the temporary directory once completed, use arg 2 (value 'k') :
#   make asc-upgrade n k
#   # Or :
#   asc/asc/upgrade.sh n k
#

. asc/bootstrap.sh

echo "Upgrading ASC from the source repo on Github ..."

tmp_dir="data/tmp/upstream-asc"

if [[ ! -d 'data/tmp' ]]; then
  mkdir -p 'data/tmp'

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: failed to create tmp dir 'data/tmp'." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
fi

# Support retries without having to re-download the sources from remote repo
# every time.
proceed_with_download='y'

if [[ -d "$tmp_dir" ]]; then
  if [[ -z "$1" ]]; then
    echo
    echo "It seems the temporary directory '$tmp_dir' already exists."
    echo "Should we delete it and re-download the sources from the main public repository on Github ?"
    read -p "Yes/no (y/n); 'no' = skip download, use existing folder : " proceed_with_download
  else
    case "$1" in n|no)
      proceed_with_download='n'
    esac
  fi
fi

case "$proceed_with_download" in y|yes)
  if [[ -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi

  asc_upstream_git='https://github.com/Paulmicha/asc.git'
  asc_branch="${ASC_BRANCH:-main}"
  f_str_sanitize "$asc_branch" '-' 'asc_branch'

  git clone --depth 1 -b "$asc_branch" "$asc_upstream_git" "$tmp_dir"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to clone ASC 'core' from the main public repository on Github." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
esac

# Delete managed folders from current project instance.
if [[ -d 'asc' ]]; then
  rm -rf 'asc'

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: failed to remove ASC core dir 'asc'." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi
fi

if [ -d 'scripts/asc/contrib/asc' ]; then
  rm -rf 'scripts/asc/contrib/asc'

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: failed to remove ASC contrib extensions dir 'scripts/asc/contrib/asc'." >&2
    echo "-> Aborting (2)." >&2
    echo >&2
    exit 2
  fi
fi

# Replace them with the new ones.
cp -r "$tmp_dir/asc" 'asc'

if [[ $? -ne 0 || ! -d 'asc' ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to copy the new sources from '$tmp_dir/asc' to 'asc'." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

cp -r "$tmp_dir/scripts/asc/contrib/asc" 'scripts/asc/contrib/asc'

if [[ $? -ne 0 || ! -d 'scripts/asc/contrib/asc' ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to copy the new sources from '$tmp_dir/scripts/asc/contrib/asc' to 'scripts/asc/contrib/asc'." >&2
  echo "-> Aborting (3)." >&2
  echo >&2
  exit 3
fi

# Clean up temporary folder, unless prevented in arg 2 (pass 'k').
if [[ "$2" != 'k' ]]; then
  rm -rf "$tmp_dir"
fi

echo "Upgrading ASC from the source repo on Github : done."
echo

echo "Running post-upgrade hook ..."

hook -s 'asc' -a 'post_upgrade' -v 'STACK_VERSION HOST_TYPE INSTANCE_TYPE PROVISION_USING'

echo "Running post-upgrade hook : done."
echo
