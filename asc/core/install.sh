#!/usr/bin/env bash

##
# Turns the given folder path into an ASC project instance.
#
# Same as running "make core-upgrade" if path is already an ASC project instance.
#
# @param 1 String : new instance folder path.
#
# @example
#   asc/core/install.sh path/to/folder
#   # Or :
#   make core-install path/to/folder
#

. asc/bootstrap.sh

p_instance_path="$1"

if [[ -z "$p_instance_path" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: new instance folder path required." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

if [[ ! -d "$p_instance_path" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: new instance folder path does not exist." >&2
  echo "-> Aborting (2)." >&2
  echo >&2
  exit 2
fi

echo "Temporarily shallow clone ASC upstream repo ..."

tmp_dir="$p_instance_path/data/tmp/upstream-asc"

if [[ ! -d "$p_instance_path/data/tmp" ]]; then
  mkdir -p "$p_instance_path/data/tmp"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: failed to create tmp dir '$p_instance_path/data/tmp'." >&2
    echo "-> Aborting (3)." >&2
    echo >&2
    exit 3
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
    echo "-> Aborting (4)." >&2
    echo >&2
    exit 4
  fi
esac

echo "Temporarily shallow clone ASC upstream repo : done."
echo

echo "Copy ASC core files ..."

# Consolidated synchronizing of entire folders.
dirs_swapped=()
dirs_swapped+=('asc')
dirs_swapped+=('docs/specs/asc')
dirs_swapped+=('scripts/asc/contrib/asc')
dirs_swapped+=('.agents/skills/asc-actions-priority')
dirs_swapped+=('.agents/skills/asc-author-code')
dirs_swapped+=('.agents/skills/asc-author-docs')
dirs_swapped+=('.agents/skills/asc-mother-guard')

# Ensure the parent folders of every path that needs replacing already exists.
mkdir -p "$p_instance_path/docs/specs/asc"
mkdir -p "$p_instance_path/scripts/asc/contrib"
mkdir -p "$p_instance_path/.agents/skills"

# Delete the paths whose contents are to be entirely replaced (= swapped), then
# copy the new ones in their place.
for dir_swapped in "${dirs_swapped[@]}"; do
  target_dir="$p_instance_path/$dir_swapped"

  if [[ -d "$target_dir" ]]; then
    rm -rf "$target_dir"

    if [[ $? -ne 0 ]]; then
      echo >&2
      echo "Error in $BASH_SOURCE line $LINENO: failed to remove ASC core dir '$target_dir'." >&2
      echo "-> Aborting (5)." >&2
      echo >&2
      exit 5
    fi
  fi

  # Replace them with the new ones.
  cp -r "$tmp_dir/$dir_swapped" "$target_dir"

  if [[ $? -ne 0 || ! -d "$target_dir" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to copy the new sources from '$tmp_dir/$dir_swapped' to '$target_dir'." >&2
    echo "-> Aborting (6)." >&2
    echo >&2
    exit 6
  fi
done

# Shared agent instructions. The instance owns its root AGENTS.md.
cp -f "$tmp_dir/AGENTS.asc.md" "$p_instance_path/AGENTS.asc.md"

if [[ $? -ne 0 || ! -f "$p_instance_path/AGENTS.asc.md" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to copy '$tmp_dir/AGENTS.asc.md' to '$p_instance_path/AGENTS.asc.md'." >&2
  echo "-> Aborting (7)." >&2
  echo >&2
  exit 7
fi

# For newly created project instances, we need an initial AGENTS.md.
if [[ ! -f "$p_instance_path/AGENTS.md" ]]; then
  cp "$tmp_dir/AGENTS.md" "$p_instance_path/AGENTS.md"
fi

# Initialize extension settings without replacing instance configuration.
if [[ ! -f "$p_instance_path/.asc_extensions_ignore" ]]; then
  cp "$tmp_dir/.asc_extensions_ignore" "$p_instance_path/.asc_extensions_ignore"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to copy '$tmp_dir/.asc_extensions_ignore' to '$p_instance_path/.asc_extensions_ignore'." >&2
    echo "-> Aborting (8)." >&2
    echo >&2
    exit 8
  fi
else
  cp -f "$tmp_dir/.asc_extensions_ignore" "$p_instance_path/.asc_extensions_ignore.asc-upstream-copy"
  echo "TODO : '$tmp_dir/.asc_extensions_ignore' needs manual review."
  echo "  -> compare with upstream temporary copy : '$p_instance_path/.asc_extensions_ignore.asc-upstream-copy'."
fi

# Gitignore needs attention.
if [[ ! -f "$p_instance_path/.gitignore" ]]; then
  cp "$tmp_dir/.gitignore" "$p_instance_path/.gitignore"
else
  cp -f "$tmp_dir/.gitignore" "$p_instance_path/.gitignore.asc-upstream-copy"
  echo "TODO : '$p_instance_path/.gitignore' needs manual review."
  echo "  -> compare with upstream temporary copy : '$p_instance_path/.gitignore.asc-upstream-copy'."
fi

# Default Makefile too.
if [[ ! -f "$p_instance_path/Makefile" ]]; then
  cp "$tmp_dir/Makefile" "$p_instance_path/Makefile"
else
  cp -f "$tmp_dir/Makefile" "$p_instance_path/Makefile.asc-upstream-copy"
  echo "TODO : '$p_instance_path/Makefile' needs manual review."
  echo "  -> compare with upstream temporary copy : '$p_instance_path/Makefile.asc-upstream-copy'."
fi

# Clean up temporary folder, unless prevented in arg 2 (pass 'k').
if [[ "$2" != 'k' ]]; then
  rm -rf "$tmp_dir"
fi

echo "Copy ASC core files : done."
echo
