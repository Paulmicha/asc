#!/usr/bin/env bash

##
# Upgrades ASC from the source repo on Github.
#
# Deletes and replaces the ./asc folder with contents from the main public repo.
# Preserves extensions that aren't part of the list bundled with ASC (based on
# the latest remote sources).
#
# The remote branch/tag is overridable using a global named 'ASC_BRANCH'
# (defaults to 'v2.0.0').
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

tmp_dir="data/asc/tmp-core-upgrade"

if [[ ! -d 'data/asc' ]]; then
  mkdir -p 'data/asc'
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
    case "$1" in n)
      proceed_with_download='n'
    esac
  fi
fi

case "$proceed_with_download" in y*|Y*)
  if [[ -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi

  asc_upstream_git='https://github.com/Paulmicha/asc.git'
  asc_branch="${ASC_BRANCH:-v2.0.0}"
  u_str_sanitize "$asc_branch" '-' 'asc_branch'

  git clone --depth 1 -b "$asc_branch" "$asc_upstream_git" "$tmp_dir"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to clone ASC 'core' from the main public repository on Github." >&2
    echo "-> Aborting (1)." >&2
    echo >&2
    exit 1
  fi
esac

# Delete individually all bundled extensions in existing project instance.
u_fs_dir_list "$tmp_dir/asc/extensions"
for dir in $dir_list; do
  if [[ -d "asc/extensions/$dir" ]]; then
    rm -rf "asc/extensions/$dir"
  fi
done

# If there are any extension left in existing project instance, move them
# temporarily.
dir_list=''
u_fs_dir_list "asc/extensions"
if [[ -n "$dir_list" ]]; then
  mkdir "$tmp_dir/_extensions_backup"
  for dir in $dir_list; do
    mv "asc/extensions/$dir" "$tmp_dir/_extensions_backup/"
  done
fi

# Delete ./asc folder from current project instance.
rm -rf ./asc

# Replace it with the new one.
cp -r "$tmp_dir/asc" ./asc

if [[ $? -ne 0 ]] || [[ ! -d ./asc ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to copy the new sources from '$tmp_dir/asc' to './asc'." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

# Restore any extensions previously backed up (if any).
if [[ -d "$tmp_dir/_extensions_backup" ]]; then
  dir_list=''
  u_fs_dir_list "$tmp_dir/_extensions_backup"
  for dir in $dir_list; do
    mv "$tmp_dir/_extensions_backup/$dir" "asc/extensions/"
  done
  rm -rf "$tmp_dir/_extensions_backup"
fi

# Clean up temporary folder, unless prevented in arg 2 (pass 'k').
if [[ "$2" != 'k' ]]; then
  rm -rf "$tmp_dir"
fi

echo "Upgrading ASC from the source repo on Github : done."
echo

echo "Running post-update hook ..."

hook -s 'asc' -a 'post_upgrade' -v 'STACK_VERSION HOST_TYPE INSTANCE_TYPE PROVISION_USING'

echo "Running post-update hook : done."
echo
