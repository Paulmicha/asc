#!/usr/bin/env bash

##
# Show managed crontab status vs generated intent.
#
# @example
#   make cron-status
#

. asc/bootstrap.sh

u_cron_require_crontab || exit 1

marker="$(u_cron_project_marker)"
begin="# ASC-CRON-BEGIN ${marker}"
end="# ASC-CRON-END ${marker}"

echo "Project : $marker"
echo "crontab : $(command -v crontab)"
echo

if [[ -d scripts/asc/local/cron ]]; then
  echo "=== Generated entries ==="
  shopt -s nullglob
  for f in scripts/asc/local/cron/*.sh; do
    # shellcheck disable=SC1090
    . "$f"
    echo "- $ASC_CRON_ENTRY  enabled=$ASC_CRON_ENABLED  preset=$ASC_CRON_PRESET  schedule=$ASC_CRON_SCHEDULE"
  done
  echo
else
  echo "(no generated scripts/asc/local/cron yet)"
  echo
fi

echo "=== Host crontab managed block ==="
current="$(u_cron_crontab_list)"
if printf '%s\n' "$current" | grep -qxF "$begin"; then
  printf '%s\n' "$current" | awk -v b="$begin" -v e="$end" '
    $0 == b {show=1}
    show {print}
    $0 == e {show=0}
  '
else
  echo "(none)"
fi
