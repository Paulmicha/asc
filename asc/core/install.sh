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

echo "Copy ASC core files ..."

# Consolidated synchronizing of entire folders.
dirs=()
dirs+=('asc')
dirs+=('docs/specs/asc')
dirs+=('scripts/asc/contrib/asc')
dirs+=('.agents/skills/asc-actions-priority')
dirs+=('.agents/skills/asc-author-code')
dirs+=('.agents/skills/asc-author-docs')
dirs+=('.agents/skills/asc-mother-guard')

# Ensure the parent folders of every path that needs replacing already exists.
mkdir -p "$p_instance_path/docs/specs/asc"
mkdir -p "$p_instance_path/scripts/asc/contrib"
mkdir -p "$p_instance_path/.agents/skills"

# Delete the paths whose contents are to be entirely replaced (= swapped), then
# copy the new ones in their place.
for dir in "${dirs[@]}"; do
  target_dir="$p_instance_path/$dir"

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
  cp -r "$dir" "$target_dir"

  if [[ $? -ne 0 || ! -d "$target_dir" ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to copy the new sources from '$dir' to '$target_dir'." >&2
    echo "-> Aborting (6)." >&2
    echo >&2
    exit 6
  fi
done

# Shared agent instructions. The instance owns its root AGENTS.md.
cp -f "AGENTS.asc.md" "$p_instance_path/AGENTS.asc.md"

if [[ $? -ne 0 || ! -f "$p_instance_path/AGENTS.asc.md" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: unable to copy 'AGENTS.asc.md' to '$p_instance_path/AGENTS.asc.md'." >&2
  echo "-> Aborting (7)." >&2
  echo >&2
  exit 7
fi

# For newly created project instances, we need an initial AGENTS.md.
if [[ ! -f "$p_instance_path/AGENTS.md" ]]; then
  cp "AGENTS.md" "$p_instance_path/AGENTS.md"
fi

# Initialize extension settings without replacing instance configuration.
if [[ ! -f "$p_instance_path/.asc_extensions_ignore" ]]; then
  cp ".asc_extensions_ignore" "$p_instance_path/.asc_extensions_ignore"

  if [[ $? -ne 0 ]]; then
    echo >&2
    echo "Error in $BASH_SOURCE line $LINENO: unable to copy '.asc_extensions_ignore' to '$p_instance_path/.asc_extensions_ignore'." >&2
    echo "-> Aborting (8)." >&2
    echo >&2
    exit 8
  fi
else
  cp -f ".asc_extensions_ignore" "$p_instance_path/.asc_extensions_ignore.asc-upstream-copy"
  echo "TODO : '.asc_extensions_ignore' needs manual review."
  echo "  -> compare with upstream temporary copy : '$p_instance_path/.asc_extensions_ignore.asc-upstream-copy'."
fi

# Gitignore needs attention.
if [[ ! -f "$p_instance_path/.gitignore" ]]; then
  cp ".gitignore" "$p_instance_path/.gitignore"
else
  cp -f ".gitignore" "$p_instance_path/.gitignore.asc-upstream-copy"
  echo "TODO : '$p_instance_path/.gitignore' needs manual review."
  echo "  -> compare with upstream temporary copy : '$p_instance_path/.gitignore.asc-upstream-copy'."
fi

# Default Makefile too.
if [[ ! -f "$p_instance_path/Makefile" ]]; then
  cp "Makefile" "$p_instance_path/Makefile"
else
  cp -f "Makefile" "$p_instance_path/Makefile.asc-upstream-copy"
  echo "TODO : '$p_instance_path/Makefile' needs manual review."
  echo "  -> compare with upstream temporary copy : '$p_instance_path/Makefile.asc-upstream-copy'."
fi

echo "Copy ASC core files : done."
echo
