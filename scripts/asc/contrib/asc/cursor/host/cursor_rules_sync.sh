#!/usr/bin/env bash

##
# Pull the ASC mother, then report Cursor rules on each local ASC instance.
#
# Cursor extension, subject host. Does not copy rules. Does not copy instance
# files into the mother. Does not scan remote hosts. A host list is not on disk.
#
# @example
#   scripts/asc/contrib/asc/cursor/host/cursor-rules-sync.sh
#   make host-cursor-rules-sync
#

. asc/bootstrap.sh

mother="$HOME/Documents/asc"

if [[ ! -f "$mother/asc/bootstrap.sh" ]]; then
  echo "Mother checkout is missing: $mother" >&2
  exit 1
fi

mother_status="$(git -C "$mother" status -sb)"
case "$mother_status" in
  '## main...origin/main')
    git -C "$mother" pull || exit 1
    ;;
  '## main...origin/main [ahead '[0-9]*)
    echo "Mother is ahead of origin. Skip pull."
    ;;
  *)
    echo "Mother checkout is not a clean main. Stop." >&2
    echo "$mother_status" >&2
    exit 1
    ;;
esac

echo "Mother $mother"
echo "HEAD $(git -C "$mother" rev-parse --short HEAD)"
echo

mother_rules="$mother/.cursor/rules"
if [[ -d "$mother_rules" ]]; then
  echo "Mother rules:"
  find "$mother_rules" -maxdepth 1 -type f -name '*.mdc' -printf '  %f\n' | sort
else
  echo "Mother rules: none"
fi
echo

echo "Local ASC instances (asc/bootstrap.sh, depth <= 5):"

found=0
while IFS= read -r bootstrap; do
  docroot="$(dirname "$(dirname "$bootstrap")")"
  if [[ "$docroot" == "$mother" ]]; then
    continue
  fi
  found=1
  echo "- $docroot"
  if [[ -d "$docroot/cwt" ]]; then
    echo "  cwt/ still present"
  fi
  rules="$docroot/.cursor/rules"
  if [[ ! -d "$rules" ]]; then
    echo "  .cursor/rules: absent"
    continue
  fi
  echo "  .cursor/rules:"
  find "$rules" -maxdepth 1 -type f -name '*.mdc' -printf '    %f\n' | sort
  if [[ -d "$mother_rules" ]]; then
    echo "  mother rules missing here:"
    missing=0
    while IFS= read -r name; do
      if [[ ! -f "$rules/$name" ]]; then
        echo "    $name"
        missing=1
      fi
    done < <(find "$mother_rules" -maxdepth 1 -type f -name '*.mdc' -printf '%f\n' | sort)
    if [[ "$missing" -eq 0 ]]; then
      echo "    (none)"
    fi
  fi
done < <(find "$HOME" -maxdepth 5 -path '*/asc/bootstrap.sh' \
  -not -path '*/.git/*' -not -path '*/.*/*')

if [[ "$found" -eq 0 ]]; then
  echo "(none)"
fi

echo
echo "Remote hosts: not scanned. No host list is on disk."
echo "This command does not copy bytes into the mother or into an instance."
