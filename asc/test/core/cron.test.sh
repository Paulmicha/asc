#!/usr/bin/env bash

##
# Cron migration regression tests in a disposable ASC instance.
#
# @requires asc/vendor/shunit2
# @see asc/test/core.sh
#

. asc/bootstrap.sh

oneTimeSetUp() {
  cron_fixture="$(mktemp -d /tmp/asc-cron-test.XXXXXXXX)"
  cp -a asc scripts "$cron_fixture/"
  cp .asc_extensions_ignore "$cron_fixture/"
  sed -i -e '/^cron$/d' -e '/^asc\/crontab$/d' "$cron_fixture/.asc_extensions_ignore"
  mkdir -p "$cron_fixture/data" "$cron_fixture/home"
}

oneTimeTearDown() {
  rm -rf "$cron_fixture"
}

##
# A different backend can implement cron without requiring crontab.
#
test_cron_uses_an_alternative_backend() {
  local action output status
  mkdir -p "$cron_fixture/scripts/asc/extend/cron" "$cron_fixture/alternative-bin"
  printf '#!/usr/bin/env bash\nprintf "CRONTAB_CALLED\\n"\nexit 9\n' > "$cron_fixture/alternative-bin/crontab"
  chmod +x "$cron_fixture/alternative-bin/crontab"
  for action in sync settings start stop restart stop_all restart_all status run; do
    printf 'if declare -F f_crontab_sync >/dev/null; then echo BACKEND_LOADED; exit 9; fi\nprintf "ALTERNATIVE_BACKEND:%%s\\n" "$p_entry"\n' > "$cron_fixture/scripts/asc/extend/cron/$action.hook.sh"
    rm -rf "$cron_fixture/data/asc/cache"
    output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" PATH="$cron_fixture/alternative-bin:$PATH" bash "asc/extensions/cron/cron/$action.sh" example 2>&1)"
    status=$?
    assertEquals "alternative $action backend: $output" 0 "$status"
    assertTrue "$action receives entry" "[[ '$output' == *ALTERNATIVE_BACKEND:example* ]]"
    assertFalse "$action does not invoke crontab" "[[ '$output' == *CRONTAB_CALLED* ]]"
    rm -f "$cron_fixture/scripts/asc/extend/cron/$action.hook.sh"
  done
  rm -rf "$cron_fixture/data/asc/cache"
}

##
# The abstraction reports a missing backend without invoking host tools.
#
test_cron_without_backend_fails() {
  local output status
  printf '\nasc/crontab\n' >> "$cron_fixture/.asc_extensions_ignore"
  rm -rf "$cron_fixture/data/asc/cache"
  output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" PATH="$cron_fixture/alternative-bin:$PATH" bash asc/extensions/cron/cron/sync.sh 2>&1)"
  status=$?
  assertNotEquals 'missing backend fails' 0 "$status"
  assertTrue 'missing backend is explained' "[[ '$output' == *'no cron sync implementation found'* ]]"
  assertFalse 'missing backend does not invoke crontab' "[[ '$output' == *CRONTAB_CALLED* ]]"
  sed -i '/^asc\/crontab$/d' "$cron_fixture/.asc_extensions_ignore"
  rm -rf "$cron_fixture/data/asc/cache"
}

##
# Enabled inventory discovers shipped jobs; bad inputs preserve earlier output.
#
test_cron_settings_inventory_and_preservation() {
  local output status
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  status=$?
  assertEquals "settings should succeed: $output" 0 "$status"
  assertTrue 'log job generated' "[ -f '$cron_fixture/data/asc/crontab/log-rotate.sh' ]"
  assertTrue 'thread job generated' "[ -f '$cron_fixture/data/asc/crontab/thread-monitor.sh' ]"
  mkdir -p "$cron_fixture/asc/extensions/cron/log"
  printf 'enabled: true\n' > "$cron_fixture/asc/extensions/cron/log/rotate.invalid.cron.yml"
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  status=$?
  assertNotEquals 'bad preset must fail' 0 "$status"
  assertTrue 'earlier job retained' "[ -f '$cron_fixture/data/asc/crontab/log-rotate.sh' ]"
  rm -f "$cron_fixture/asc/extensions/cron/log/rotate.invalid.cron.yml"
}

##
# Disabled extensions are excluded; enabled contrib jobs are discovered.
#
test_cron_enabled_inventory_and_duplicates() {
  local output status
  mkdir -p "$cron_fixture/asc/extensions/nftcronoff/log" \
    "$cron_fixture/scripts/asc/contrib/nft/cronfixture/example"
  printf 'nftcronoff\n' >> "$cron_fixture/.asc_extensions_ignore"
  printf 'enabled: true\n' > "$cron_fixture/asc/extensions/nftcronoff/log/rotate.every-1m.cron.yml"
  printf 'enabled: true\n' > "$cron_fixture/scripts/asc/contrib/nft/cronfixture/example/check.every-1m.cron.yml"
  rm -rf "$cron_fixture/data/asc/cache"
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  status=$?
  assertEquals "enabled inventory: $output" 0 "$status"
  assertTrue 'enabled contrib job generated' "[ -f '$cron_fixture/data/asc/crontab/example-check.sh' ]"
  assertTrue 'shipped log source retained' "grep -q 'cron/log/rotate.at-03h00.cron.yml' '$cron_fixture/data/asc/crontab/log-rotate.sh'"
  printf 'enabled: true\n' > "$cron_fixture/asc/extensions/cron/log/rotate.every-5m.cron.yml"
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  status=$?
  assertNotEquals "duplicate must fail: $output" 0 "$status"
  assertTrue 'original definition preserved' "grep -q 'cron/log/rotate.at-03h00.cron.yml' '$cron_fixture/data/asc/crontab/log-rotate.sh'"
  rm -f "$cron_fixture/asc/extensions/cron/log/rotate.every-5m.cron.yml"
  printf 'log\n' > "$cron_fixture/asc/extensions/cron/.asc_subjects_ignore"
  rm -rf "$cron_fixture/data/asc/cache"
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  status=$?
  assertEquals "disabled subject: $output" 0 "$status"
  assertFalse 'disabled subject job excluded' "[ -f '$cron_fixture/data/asc/crontab/log-rotate.sh' ]"
  rm -f "$cron_fixture/asc/extensions/cron/.asc_subjects_ignore"
}

##
# Contrib post-init propagates generation and host sync failures.
#
test_cron_post_init_propagates_failure() {
  local output status
  mkdir -p "$cron_fixture/stub/scripts/asc/contrib/asc/crontab/cron"
  cp "$cron_fixture/scripts/asc/contrib/asc/crontab/instance/post_init.hook.sh" "$cron_fixture/stub/post_init.hook.sh"
  cat > "$cron_fixture/stub/scripts/asc/contrib/asc/crontab/cron/cron.opt-inc.sh" <<'STUB'
f_crontab_settings_setup() { return "${GEN_STATUS:-0}"; }
f_crontab_sync() { echo SYNC_REACHED; return "${SYNC_STATUS:-0}"; }
STUB
  output="$(cd "$cron_fixture/stub" && env ASC_CRON_SYNC_ON_INIT=true GEN_STATUS=7 bash post_init.hook.sh 2>&1)"
  status=$?
  assertEquals 'generation status' 7 "$status"
  assertFalse 'sync not called' "[[ '$output' == *SYNC_REACHED* ]]"
  assertFalse 'no success' "[[ '$output' == *done* ]]"
  output="$(cd "$cron_fixture/stub" && env ASC_CRON_SYNC_ON_INIT=true SYNC_STATUS=8 bash post_init.hook.sh 2>&1)"
  status=$?
  assertEquals 'sync status' 8 "$status"
  assertFalse 'no success after sync failure' "[[ '$output' == *done* ]]"
}

##
# A failed crontab write reaches the sync caller.
#
test_cron_sync_propagates_crontab_write_failure() {
  local output status
  mkdir -p "$cron_fixture/bin"
  cat > "$cron_fixture/bin/crontab" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == '-l' ]]; then exit 0; fi
exit 9
STUB
  chmod +x "$cron_fixture/bin/crontab"
  output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" PATH="$cron_fixture/bin:$PATH" bash asc/extensions/cron/cron/sync.sh 2>&1)"
  status=$?
  assertEquals "crontab failure: $output" 9 "$status"
  assertFalse 'sync does not report success' "[[ '$output' == *'Host crontab synced'* ]]"
}

##
# The crontab backend preserves unrelated lines while syncing and stopping.
#
test_crontab_backend_manages_only_its_block() {
  local output status
  mkdir -p "$cron_fixture/fake-crontab"
  cat > "$cron_fixture/fake-crontab/crontab" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == '-l' ]]; then cat "$FAKE_CRONTAB_FILE"; else cp "$1" "$FAKE_CRONTAB_FILE"; fi
STUB
  chmod +x "$cron_fixture/fake-crontab/crontab"
  printf 'MAILTO=other@example.invalid\n' > "$cron_fixture/crontab-state"
  output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" PATH="$cron_fixture/fake-crontab:$PATH" FAKE_CRONTAB_FILE="$cron_fixture/crontab-state" bash asc/extensions/cron/cron/sync.sh 2>&1)"
  status=$?
  assertEquals "sync succeeds: $output" 0 "$status"
  assertTrue 'unrelated line remains' "grep -q '^MAILTO=other@example.invalid$' '$cron_fixture/crontab-state'"
  assertTrue 'managed block installed' "grep -q '^# ASC-CRON-BEGIN ' '$cron_fixture/crontab-state'"
  assertTrue 'generated job installed' "grep -q 'make cron-run' '$cron_fixture/crontab-state'"
  output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" PATH="$cron_fixture/fake-crontab:$PATH" FAKE_CRONTAB_FILE="$cron_fixture/crontab-state" bash asc/extensions/cron/cron/stop_all.sh 2>&1)"
  status=$?
  assertEquals "stop-all succeeds: $output" 0 "$status"
  assertTrue 'unrelated line survives stop-all' "grep -q '^MAILTO=other@example.invalid$' '$cron_fixture/crontab-state'"
  assertFalse 'managed job removed' "grep -q 'make cron-run' '$cron_fixture/crontab-state'"
}

##
# Every host mutation action must stop and report a failed crontab write.
#
test_cron_host_actions_propagate_write_failures() {
  local action output status
  mkdir -p "$cron_fixture/bin" "$cron_fixture/data/asc/crontab"
  cat > "$cron_fixture/bin/crontab" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == '-l' ]]; then exit 0; fi
printf 'write\n' >> "$CRON_TEST_WRITES"
exit 9
STUB
  chmod +x "$cron_fixture/bin/crontab"
  cat > "$cron_fixture/data/asc/crontab/fixture-run.sh" <<'JOB'
ASC_CRON_ENABLED=true
ASC_CRON_ENTRY=fixture-run
ASC_CRON_SCHEDULE='* * * * *'
JOB

  for action in start stop restart stop_all restart_all; do
    : > "$cron_fixture/writes"
    output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" PATH="$cron_fixture/bin:$PATH" \
      CRON_TEST_WRITES="$cron_fixture/writes" bash "asc/extensions/cron/cron/$action.sh" fixture-run 2>&1)"
    status=$?
    assertEquals "$action propagates write failure: $output" 9 "$status"
    assertEquals "$action stops after first failed write" 1 "$(wc -l < "$cron_fixture/writes")"
    assertFalse "$action does not print success" "[[ \"\$output\" == *'synced'* || \"\$output\" == *'Stopped cron'* || \"\$output\" == *'Removed all'* || \"\$output\" == *'Restarted all'* ]]"
  done
}

##
# The real dispatcher selects the Debian hook and reports a missing runner.
#
test_cron_run_dispatch_and_missing_hook() {
  local output status
  mkdir -p "$cron_fixture/data/asc/crontab"
  cat > "$cron_fixture/data/asc/crontab/fixture-run.sh" <<'JOB'
ASC_CRON_ENABLED=true
ASC_CRON_ENTRY=fixture-run
ASC_CRON_LOCK=none
ASC_CRON_CMD='printf "JOB_EXECUTED\\n"'
JOB
  sed -i '/^\. scripts\/asc\/contrib\/asc\/crontab\/cron\/run.hook.sh/i echo DEBIAN_HOOK_SELECTED' \
    "$cron_fixture/scripts/asc/contrib/asc/crontab/cron/run.debian-13.hook.sh"
  rm -rf "$cron_fixture/data/asc/cache"
  output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" HOST_OS=debian-13 bash asc/extensions/cron/cron/run.sh fixture-run 2>&1)"
  status=$?
  assertEquals "cron dispatch: $output" 0 "$status"
  assertTrue 'Debian hook selected' "[[ '$output' == *DEBIAN_HOOK_SELECTED* ]]"
  assertTrue 'job executed' "[[ '$output' == *JOB_EXECUTED* ]]"
  output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" HOST_OS=fixture-os bash asc/extensions/cron/cron/run.sh fixture-run 2>&1)"
  status=$?
  assertEquals "default dispatch: $output" 0 "$status"
  assertTrue 'default runner executed job' "[[ '$output' == *JOB_EXECUTED* ]]"
  assertFalse 'Debian hook not selected' "[[ '$output' == *DEBIAN_HOOK_SELECTED* ]]"
  mkdir -p "$cron_fixture/scripts/asc/extend/cron"
  printf '%s\n' 'echo OVERRIDE_SELECTED' "hook_ms -s 'nftnonexistent' -a 'missing'" > "$cron_fixture/scripts/asc/extend/cron/run.hook.sh"
  rm -rf "$cron_fixture/data/asc/cache"
  output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" HOST_OS=debian-13 bash asc/extensions/cron/cron/run.sh fixture-run 2>&1)"
  status=$?
  assertEquals "override dispatch: $output" 0 "$status"
  assertTrue 'project hook selected' "[[ '$output' == *OVERRIDE_SELECTED* ]]"
  rm -f "$cron_fixture/scripts/asc/extend/cron/run.hook.sh"
  rm -f "$cron_fixture/scripts/asc/contrib/asc/crontab/cron/run.hook.sh" \
    "$cron_fixture/scripts/asc/contrib/asc/crontab/cron/run.debian-13.hook.sh"
  rm -rf "$cron_fixture/data/asc/cache"
  output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" HOST_OS=debian-13 bash asc/extensions/cron/cron/run.sh fixture-run 2>&1)"
  status=$?
  assertNotEquals 'missing runner fails' 0 "$status"
  assertTrue 'missing runner diagnostic' "[[ '$output' == *'no hook -s cron -a run'* ]]"
}

##
# A failed install restores the complete previously generated definitions.
#
test_cron_failed_install_preserves_previous_generation() {
  local output status before_job before_index
  rm -rf "$cron_fixture/data/asc/cache"
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  status=$?
  assertEquals "initial generation: $output" 0 "$status"
  before_job="$(cat "$cron_fixture/data/asc/crontab/log-rotate.sh")"
  before_index="$(cat "$cron_fixture/data/asc/crontab.sh")"
  mkdir -p "$cron_fixture/fail-bin"
  cat > "$cron_fixture/fail-bin/cp" <<'STUB'
#!/usr/bin/env bash
exit 9
STUB
  cat > "$cron_fixture/fail-bin/mv" <<'STUB'
#!/usr/bin/env bash
case "$1:$2" in
  data/asc/crontab:*.crontab-staging.*/previous-cron)
    [[ "${CRON_FAIL_BACKUP:-0}" == 1 ]] && exit 9
    ;;
  *.crontab-staging.*/cron.sh:data/asc/crontab.sh)
    [[ "${CRON_FAIL_BACKUP:-0}" == 1 ]] || exit 9
    ;;
esac
exec /usr/bin/mv "$@"
STUB
  chmod +x "$cron_fixture/fail-bin/cp" "$cron_fixture/fail-bin/mv"
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" PATH="$cron_fixture/fail-bin:$PATH" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  status=$?
  assertNotEquals "install failure propagates: $output" 0 "$status"
  assertEquals 'previous job preserved' "$before_job" "$(cat "$cron_fixture/data/asc/crontab/log-rotate.sh" 2>/dev/null)"
  assertEquals 'previous index preserved' "$before_index" "$(cat "$cron_fixture/data/asc/crontab.sh" 2>/dev/null)"
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" CRON_FAIL_BACKUP=1 PATH="$cron_fixture/fail-bin:$PATH" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  status=$?
  assertNotEquals "backup failure propagates: $output" 0 "$status"
  assertEquals 'backup failure preserves previous job' "$before_job" "$(cat "$cron_fixture/data/asc/crontab/log-rotate.sh" 2>/dev/null)"
  assertEquals 'backup failure restores previous index' "$before_index" "$(cat "$cron_fixture/data/asc/crontab.sh" 2>/dev/null)"
}

##
# An interrupted swap leaves the previous files available for recovery.
#
test_cron_interrupted_swap_preserves_backup() {
  local output status before_index backup
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  assertEquals "initial generation: $output" 0 "$?"
  before_index="$(cat "$cron_fixture/data/asc/crontab.sh")"
  mkdir -p "$cron_fixture/interrupt-bin"
  cat > "$cron_fixture/interrupt-bin/mv" <<'STUB'
#!/usr/bin/env bash
case "$1:$2" in
  data/asc/crontab:*.crontab-staging.*/previous-cron)
    kill -TERM "$PPID"
    exit 1
    ;;
esac
exec /usr/bin/mv "$@"
STUB
  chmod +x "$cron_fixture/interrupt-bin/mv"
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" PATH="$cron_fixture/interrupt-bin:$PATH" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  status=$?
  assertNotEquals 'interrupted refresh fails' 0 "$status"
  backup="$(find "$cron_fixture/data/asc" -path '*/.crontab-staging.*/previous-cron.sh' -print -quit)"
  assertTrue 'previous index remains in staging' "[ -f '$backup' ]"
  assertEquals 'staged index is unchanged' "$before_index" "$(cat "$backup" 2>/dev/null)"
  assertTrue 'previous jobs remain available' "[ -f '$cron_fixture/data/asc/crontab/log-rotate.sh' ]"
  assertTrue 'interrupted swap retains the refresh lock' "[ -d '$cron_fixture/data/asc/.crontab-refresh.lock' ]"
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  assertNotEquals 'another refresh cannot discard recovery files' 0 "$?"
}

##
# A failed crontab read must not be followed by a successful write.
#
test_crontab_read_failure_does_not_replace_unrelated_jobs() {
  local output status
  mkdir -p "$cron_fixture/cron-read-bin"
  rm -rf "$cron_fixture/data/asc/.crontab-refresh.lock"
  cat > "$cron_fixture/cron-read-bin/crontab" <<'STUB'
#!/usr/bin/env bash
if [[ "$1" == '-l' ]]; then
  case "${CRON_LIST_MODE:-ok}" in
    deny)
      echo 'crontab: Permission denied' >&2
      exit 1
      ;;
    missing)
      echo 'no crontab for fixture' >&2
      exit 1
      ;;
  esac
  cat "$FAKE_CRONTAB_FILE"
  exit 0
fi
cp "$1" "$FAKE_CRONTAB_FILE"
STUB
  chmod +x "$cron_fixture/cron-read-bin/crontab"
  printf '%s\n' 'MAILTO=other@example.invalid' > "$cron_fixture/crontab-state"
  output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" \
    PATH="$cron_fixture/cron-read-bin:$PATH" \
    FAKE_CRONTAB_FILE="$cron_fixture/crontab-state" \
    CRON_LIST_MODE=deny \
    bash asc/extensions/cron/cron/sync.sh 2>&1)"
  status=$?
  assertNotEquals "read failure reaches sync: $output" 0 "$status"
  assertEquals 'unrelated crontab preserved' 'MAILTO=other@example.invalid' \
    "$(cat "$cron_fixture/crontab-state")"
  assertTrue 'read failure is reported' "[[ \"\$output\" == *'failed to read the user crontab'* ]]"

  : > "$cron_fixture/crontab-state"
  output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" \
    PATH="$cron_fixture/cron-read-bin:$PATH" \
    FAKE_CRONTAB_FILE="$cron_fixture/crontab-state" \
    CRON_LIST_MODE=missing \
    bash asc/extensions/cron/cron/sync.sh 2>&1)"
  status=$?
  assertEquals "missing crontab can be initialized: $output" 0 "$status"
  assertTrue 'managed block installed on first write' \
    "grep -q '^# ASC-CRON-BEGIN ' '$cron_fixture/crontab-state'"
}

##
# A sub-minute preset runs once per advertised slot inside the minute tick.
#
test_subminute_preset_runs_at_advertised_frequency() {
  local output status runs sleeps
  mkdir -p "$cron_fixture/asc/extensions/cron/pulse" "$cron_fixture/cron-run-bin"
  rm -rf "$cron_fixture/data/asc/.crontab-refresh.lock" "$cron_fixture/data/asc/cache"
  cat > "$cron_fixture/asc/extensions/cron/pulse/tick.2x-per-m.cron.yml" <<'YAML'
includes: defaults
enabled: true
wrap: direct
lock: skip
YAML
  cat > "$cron_fixture/cron-run-bin/make" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CRON_MAKE_LOG"
STUB
  cat > "$cron_fixture/cron-run-bin/sleep" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$CRON_SLEEP_LOG"
STUB
  chmod +x "$cron_fixture/cron-run-bin/make" "$cron_fixture/cron-run-bin/sleep"
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  status=$?
  assertEquals "2x-per-m generation: $output" 0 "$status"
  assertTrue 'generated interval is 30 seconds' \
    "grep -q \"ASC_CRON_SUBMINUTE='30'\" '$cron_fixture/data/asc/crontab/pulse-tick.sh'"

  cp scripts/asc/contrib/asc/crontab/cron/run.hook.sh \
    "$cron_fixture/scripts/asc/contrib/asc/crontab/cron/run.hook.sh"
  rm -rf "$cron_fixture/data/asc/cache"
  : > "$cron_fixture/make.log"
  : > "$cron_fixture/sleep.log"
  output="$(cd "$cron_fixture" && env HOME="$cron_fixture/home" \
    PATH="$cron_fixture/cron-run-bin:$PATH" \
    CRON_MAKE_LOG="$cron_fixture/make.log" \
    CRON_SLEEP_LOG="$cron_fixture/sleep.log" \
    bash asc/extensions/cron/cron/run.sh pulse-tick 2>&1)"
  status=$?
  runs="$(wc -l < "$cron_fixture/make.log")"
  sleeps="$(cat "$cron_fixture/sleep.log")"
  assertEquals "sub-minute run: $output" 0 "$status"
  assertEquals 'command runs twice per minute' 2 "$runs"
  assertEquals 'second run waits one interval' 30 "$sleeps"

  printf 'enabled: true\n' > "$cron_fixture/asc/extensions/cron/pulse/other.45x-per-m.cron.yml"
  rm -rf "$cron_fixture/data/asc/cache"
  output="$(cd "$cron_fixture" && HOME="$cron_fixture/home" bash asc/extensions/cron/cron/settings.sh 2>&1)"
  status=$?
  assertNotEquals "non-divisor sub-minute preset is rejected: $output" 0 "$status"
  assertTrue 'previous interval preserved' \
    "grep -q \"ASC_CRON_SUBMINUTE='30'\" '$cron_fixture/data/asc/crontab/pulse-tick.sh'"
}

. asc/vendor/shunit2/shunit2
