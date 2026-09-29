#!/usr/bin/env bash

##
# Upgrades ASC from the source repo on Github.
#
# Deletes and replaces the following folders with contents from ASC main public
# repo :
# - asc
# - scripts/asc/contrib/asc
#
# It leaves everything else untouched. The remote branch/tag is overridable
# using a global named 'ASC_BRANCH' (defaults to 'main').
#
# @example
#   make core-upgrade
#   # Or :
#   asc/core/upgrade.sh
#
#   # Upgrade from a specific branch or tag :
#   ASC_BRANCH=main make core-upgrade
#
#   # If the temporary directory already exists, use existing folder without
#   # prompt :
#   make core-upgrade n
#   # Or :
#   asc/core/upgrade.sh n
#
#   # If the temporary directory already exists, force re-download the sources
#   # from remote repo without prompt :
#   make core-upgrade y
#   # Or :
#   asc/core/upgrade.sh y
#
#   # To keep the temporary directory once completed, use arg 2 (value 'k') :
#   make core-upgrade n k
#   # Or :
#   asc/core/upgrade.sh n k
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

# Consolidated synchronizing of entire folders.
dirs_swapped=()
dirs_swapped+=('asc')
dirs_swapped+=('scripts/asc/contrib/asc')
dirs_swapped+=('.agents/skills/asc-author-code')
dirs_swapped+=('.agents/skills/asc-author-docs')
dirs_swapped+=('.agents/skills/asc-mother-guard')

# Ensure the parent folders of every path that needs replacing already exists.
mkdir -p 'scripts/asc/contrib'
mkdir -p '.cursor/rules'
mkdir -p '.agents/skills'

# Delete the paths whose contents are to be entirely replaced (= swapped), then
# copy the new ones in their place.
for dir_swapped in "${dirs_swapped[@]}"; do
  if [[ -d "$dir_swapped" ]]; then
    rm -rf "$dir_swapped"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: failed to remove ASC core dir '$dir_swapped'." >&2
      echo "-> Aborting (2)." >&2
      echo >&2
      exit 2
    fi
  fi

  # Replace them with the new ones.
  cp -r "$tmp_dir/$dir_swapped" "$dir_swapped"

  if [[ $? -ne 0 || ! -d "$dir_swapped" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to copy the new sources from '$tmp_dir/$dir_swapped' to '$dir_swapped'." >&2
    echo "-> Aborting (3)." >&2
    echo >&2
    exit 3
  fi
done

# Cursor rules to be shared among every ASC project instances are dealt with
# on a case by case basis in order to preserve any other eventual rules specific
# to the local project instance (which may version others, thus preventing a
# whole dir swap like for the other paths).
cursor_rules=()
cursor_rules+=('.cursor/rules/asc-builder-anti-pattern.mdc')
cursor_rules+=('.cursor/rules/asc-dollar-prefix.mdc')
cursor_rules+=('.cursor/rules/asc-lightweight.mdc')
cursor_rules+=('.cursor/rules/asc-mother-guard.mdc')

for cursor_rule in "${cursor_rules[@]}"; do
  cp -f "$tmp_dir/$cursor_rule" "$cursor_rule"

  if [[ $? -ne 0 || ! -f "$cursor_rule" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to copy the new cursor rule from '$tmp_dir/$cursor_rule' to '$cursor_rule'." >&2
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi
done

# Individual files.
cp -f "$tmp_dir/AGENTS.md" 'AGENTS.md'

if [[ $? -ne 0 || ! -f 'AGENTS.md' ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to copy AGENTS.md to '$tmp_dir/AGENTS.md'." >&2
  echo "-> Aborting (5)." >&2
  echo >&2
  exit 5
fi

# Clean up temporary folder, unless prevented in arg 2 (pass 'k').
if [[ "$2" != 'k' ]]; then
  rm -rf "$tmp_dir"
fi

# TODO 2026-09-27 we'll go back to this later on. Comment everything out for now.
# echo "Upgrading ASC from the source repo on Github : done."
# echo
# echo "Running post-upgrade hook ..."
# hook -s 'core' -a 'post_upgrade' -v 'STACK_VERSION HOST_TYPE INSTANCE_TYPE PROVISION_USING'
# echo "Running post-upgrade hook : done."
# echo
