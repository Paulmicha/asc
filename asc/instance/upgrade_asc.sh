#!/usr/bin/env bash

##
# Upgrades ASC from the source repo on Github.
#
# Deletes and replaces the ./asc folder with contents from the main public repo.
# Preserves extensions that aren't part of the list bundled with ASC (based on
# the latest remote sources).
#
# The remote git URL is overridable using a global named 'ASC_REPO'.
#
# @example
#   make upgrade-asc
#   # Or :
#   asc/instance/upgrade_asc.sh
#
#   # If the temporary directory already exists, use existing folder without
#   # prompt :
#   make upgrade-asc n
#   # Or :
#   asc/instance/upgrade_asc.sh n
#
#   # If the temporary directory already exists, force re-download the sources
#   # from remote repo without prompt :
#   make upgrade-asc y
#   # Or :
#   asc/instance/upgrade_asc.sh y
#
#   # To keep the temporary directory once completed, use arg 2 (value 'k') :
#   make upgrade-asc n k
#   # Or :
#   asc/instance/upgrade_asc.sh n k
#

. asc/bootstrap.sh

echo "Upgrading ASC from the source repo on Github..."

tmp_dir="scripts/asc/local/tmp-core-upgrade"

if [[ ! -d 'scripts/asc/local' ]]; then
  mkdir -p 'scripts/asc/local'
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

  git clone "${ASC_REPO:=https://github.com/Paulmicha/asc.git}" "$tmp_dir"

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
