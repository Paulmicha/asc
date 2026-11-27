#!/usr/bin/env bash

##
# Implements hook -s 'cron' -a 'status' using crontab.
#

f_crontab_require_crontab || exit 1

f_crontab_project_marker 'marker'
begin="# ASC-CRON-BEGIN ${marker}"
end="# ASC-CRON-END ${marker}"

echo "Project : $marker"
echo "crontab : $(command -v crontab)"
echo

if [[ -d data/asc/crontab ]]; then
  echo "=== Generated entries ==="
  shopt -s nullglob
  for f in data/asc/crontab/*.sh; do
    # shellcheck disable=SC1090
    . "$f"
    echo "- $ASC_CRON_ENTRY  enabled=$ASC_CRON_ENABLED  preset=$ASC_CRON_PRESET  schedule=$ASC_CRON_SCHEDULE"
  done
  echo
else
  echo "(no generated data/asc/crontab yet)"
  echo
fi

echo "=== Host crontab managed block ==="
current="$(f_crontab_list)" || exit $?
if printf '%s\n' "$current" | grep -qxF "$begin"; then
  printf '%s\n' "$current" | awk -v b="$begin" -v e="$end" '
    $0 == b {show=1}
    show {print}
    $0 == e {show=0}
  '
else
  echo "(none)"
fi
