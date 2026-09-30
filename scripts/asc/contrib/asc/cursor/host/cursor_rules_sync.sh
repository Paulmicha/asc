#!/usr/bin/env bash

##
# Report Cursor user rules and project rules on local ASC instances.
#
# Cursor extension, subject host. Does not copy rules or scan remote hosts.
#
# @example
#   scripts/asc/contrib/asc/cursor/host/cursor_rules_sync.sh
#   make host-cursor-rules-sync
#

. asc/bootstrap.sh

user_rules="$HOME/.cursor/rules"
if [[ -d "$user_rules" ]]; then
  echo "Cursor user rules ($user_rules):"
  find "$user_rules" -maxdepth 1 -type f -name '*.mdc' -printf '  %f\n' | sort
else
  echo "Cursor user rules: none"
fi
echo

echo "Local ASC trees (asc/bootstrap.sh, depth <= 5):"

found=0
while IFS= read -r bootstrap; do
  docroot="$(dirname "$(dirname "$bootstrap")")"
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
done < <(find "$HOME" -maxdepth 5 -path '*/asc/bootstrap.sh' \
  -not -path '*/.git/*' -not -path '*/.*/*')

if [[ "$found" -eq 0 ]]; then
  echo "(none)"
fi

echo
echo "Remote hosts: not scanned. No host list is on disk."
echo "This command does not copy rules."
