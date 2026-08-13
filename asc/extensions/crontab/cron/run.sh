#!/usr/bin/env bash

##
# Run a scheduled crontab entry (host crontab invokes this).
#
# @example
#   make cron-run e:insta-save
#   asc/extensions/crontab/cron/run.sh insta-save
#

. asc/bootstrap.sh

a_entry="${1:-}"
a_entry="${a_entry#e:}"

if [[ -z "$a_entry" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO - entry name required (e:<make-entry>)." >&2
  echo "Aborting (1)." >&2
  echo >&2
  exit 1
fi

if ! f_cron_entry_load "$a_entry"; then
  # Attempt regenerate once if missing.
  f_cron_settings_setup || true
  if ! f_cron_entry_load "$a_entry"; then
    echo >&2 "Error: no generated cron definition for '$a_entry'."
    echo >&2 "Add a {action}.{preset}.crontab.yml beside the entry script, then reinit."
    exit 1
  fi
fi

if [[ "${ASC_CRON_ENABLED}" != 'true' ]]; then
  echo "Cron entry '$a_entry' is disabled; skipping."
  exit 0
fi

hook_ms 'dry-run' -s 'cron' -a 'run' \
  -v 'STACK_VERSION PROVISION_USING HOST_TYPE HOST_OS'

if [[ ! -f "$most_specific_match" ]]; then
  echo >&2 "Error: no hook -s cron -a run implementation found."
  exit 1
fi

# shellcheck disable=SC1090
. "$most_specific_match"
