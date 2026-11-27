#!/usr/bin/env bash

##
# Remote DB actions preserve database selection and stop on failure.
#
# @requires asc/vendor/shunit2
# @see asc/test/core.sh
#
# @example
#   asc/test/core/remote_db.test.sh
#

. asc/bootstrap.sh
. asc/extensions/db/db/db.opt-inc.sh
. asc/extensions/remote_asc/remote/db/db.opt-inc.sh

##
# Create a disposable tree for public actions; replace only external operations.
#
oneTimeSetUp() {
  REMOTE_DB_FIXTURE="$(mktemp -d)"
  cp -a asc "$REMOTE_DB_FIXTURE/asc"
  mkdir -p "$REMOTE_DB_FIXTURE/home" "$REMOTE_DB_FIXTURE/data/db/dumps/local/default" \
    "$REMOTE_DB_FIXTURE/data/db/dumps/local/separate"
  printf '%s\n' default > "$REMOTE_DB_FIXTURE/data/db/dumps/local/default/default.sql"
  printf '%s\n' separate > "$REMOTE_DB_FIXTURE/data/db/dumps/local/separate/separate.sql"

  cat >> "$REMOTE_DB_FIXTURE/asc/extensions/remote_asc/remote/db/db.opt-inc.sh" <<'EOF'
f_remote_instance_load() { REMOTE_INSTANCE_SSH_CONNECT_CMD=fixture; REMOTE_INSTANCE_DOCROOT=/remote; }
f_db_set() { [[ -z "$REMOTE_DB_SET_STATUS" ]] || return "$REMOTE_DB_SET_STATUS"; DB_ID="${1:-default}"; DB_NAME="$DB_ID"; }
f_db_exists() { return 0; }
f_remote_exec_wrapper() {
  printf 'remote %s\n' "$*" >> "$REMOTE_DB_LOG"
  case "$*" in *db-restore*) return "${REMOTE_DB_RESTORE_STATUS:-0}" ;; esac
  return "${REMOTE_DB_EXEC_STATUS:-0}"
}
f_remote_upload() { printf 'upload %s %s %s\n' "$1" "$2" "$3" >> "$REMOTE_DB_LOG"; }
f_remote_download() {
  printf 'download %s %s %s\n' "$1" "$2" "$3" >> "$REMOTE_DB_LOG"
  mkdir -p "${3%/*}"
  printf '%s\n' fixture > "$3"
}
f_db_routine_backup() {
  printf 'backup %s\n' "$1" >> "$REMOTE_DB_LOG"
  routine_dump_file="$ASC_DB_DUMPS_DIR/local/$1/new.sql"
  printf '%s\n' new > "$routine_dump_file"
}
f_fs_extract_in_place() { return 0; }
hook_ms() {
  case "$*" in
    *'-a clear'*) printf 'clear %s\n' "$DB_ID" >> "$REMOTE_DB_LOG"; return "${REMOTE_DB_CLEAR_STATUS:-0}" ;;
    *'-a exec'*) printf 'import %s %s\n' "$DB_ID" "$db_dump_file" >> "$REMOTE_DB_LOG"; return "${REMOTE_DB_IMPORT_STATUS:-0}" ;;
  esac
}
EOF

  cat > "$REMOTE_DB_FIXTURE/asc/extensions/remote/remote/exec.sh" <<'EOF'
#!/usr/bin/env bash
printf 'exec %s %s\n' "$1" "$2" >> "$REMOTE_DB_LOG"
printf '%s\n' '/remote/data/db/dumps/local/separate/remote.sql'
EOF
  chmod +x "$REMOTE_DB_FIXTURE/asc/extensions/remote/remote/exec.sh"
}

##
# Run real direct actions with an empty option and a non-default DB.
#
test_direct_actions_keep_database_and_failures() {
  local output status log
  log="$REMOTE_DB_FIXTURE/operations.log"
  : > "$log"

  output="$(cd "$REMOTE_DB_FIXTURE" && env HOME="$PWD/home" PROJECT_DOCROOT="$PWD" \
    ASC_DB_DUMPS_DIR=data/db/dumps REMOTE_DB_LOG="$log" \
    bash asc/extensions/remote_asc/remote/db/sync_to.sh fixture '' separate 2>&1)"
  status=$?
  assertEquals 'direct sync-to succeeds' 0 "$status"
  assertTrue 'direct sync-to uploads selected dump' "grep -q 'upload fixture data/db/dumps/local/separate/separate.sql' '$log'"
  assertTrue 'direct sync-to passes DB to restore' "grep -q 'db-restore .* separate' '$log'"

  : > "$log"
  output="$(cd "$REMOTE_DB_FIXTURE" && env HOME="$PWD/home" PROJECT_DOCROOT="$PWD" \
    ASC_DB_DUMPS_DIR=data/db/dumps REMOTE_DB_LOG="$log" \
    bash asc/extensions/remote_asc/remote/db/sync_to.sh fixture new separate 2>&1)"
  status=$?
  assertEquals 'new sync-to succeeds' 0 "$status"
  assertTrue 'new backup receives selected DB' "grep -q '^backup separate$' '$log'"
  assertTrue 'new backup path uploaded' "grep -q 'upload fixture data/db/dumps/local/separate/new.sql' '$log'"
  assertTrue 'new restore receives selected DB' "grep -q 'db-restore .* separate' '$log'"

  : > "$log"
  output="$(cd "$REMOTE_DB_FIXTURE" && env HOME="$PWD/home" PROJECT_DOCROOT="$PWD" \
    ASC_DB_DUMPS_DIR=data/db/dumps REMOTE_DB_LOG="$log" \
    bash asc/extensions/remote_asc/remote/db/sync_from.sh fixture '' separate 2>&1)"
  status=$?
  assertEquals 'direct sync-from succeeds' 0 "$status"
  assertTrue 'remote lookup receives selected DB' "grep -q 'get_dump.sh last separate' '$log'"
  assertTrue 'clear receives selected DB' "grep -q '^clear separate$' '$log'"
  assertTrue 'import receives selected DB' "grep -q '^import separate .*remote.sql' '$log'"

  : > "$log"
  output="$(cd "$REMOTE_DB_FIXTURE" && env HOME="$PWD/home" PROJECT_DOCROOT="$PWD" \
    ASC_DB_DUMPS_DIR=data/db/dumps REMOTE_DB_LOG="$log" \
    bash asc/extensions/remote_asc/remote/db/dl_from.sh fixture new separate 2>&1)"
  status=$?
  assertEquals 'direct download succeeds' 0 "$status"
  assertTrue 'new lookup receives selected DB' "grep -q 'get_dump.sh new separate' '$log'"
  assertTrue 'download targets selected DB path' "grep -q 'download fixture .*data/db/dumps/fixture/separate/remote.sql' '$log'"
  assertFalse 'download does not clear DB' "grep -q '^clear ' '$log'"

  : > "$log"
  output="$(cd "$REMOTE_DB_FIXTURE" && env HOME="$PWD/home" PROJECT_DOCROOT="$PWD" \
    ASC_DB_DUMPS_DIR=data/db/dumps REMOTE_DB_LOG="$log" REMOTE_DB_CLEAR_STATUS=7 \
    bash asc/extensions/remote_asc/remote/db/sync_from.sh fixture '' separate 2>&1)"
  status=$?
  assertEquals 'clear failure reaches public action' 7 "$status"
  assertFalse 'clear failure prevents import' "grep -q '^import ' '$log'"
  assertFalse 'clear failure suppresses restore success' "[[ \"\$output\" == *'Restoring it locally : done.'* ]]"

  : > "$log"
  output="$(cd "$REMOTE_DB_FIXTURE" && env HOME="$PWD/home" PROJECT_DOCROOT="$PWD" \
    ASC_DB_DUMPS_DIR=data/db/dumps REMOTE_DB_LOG="$log" REMOTE_DB_IMPORT_STATUS=8 \
    bash asc/extensions/remote_asc/remote/db/sync_from.sh fixture '' separate 2>&1)"
  status=$?
  assertEquals 'import failure reaches public action' 8 "$status"
  assertFalse 'import failure suppresses restore success' "[[ \"\$output\" == *'Restoring it locally : done.'* ]]"

  : > "$log"
  output="$(cd "$REMOTE_DB_FIXTURE" && env HOME="$PWD/home" PROJECT_DOCROOT="$PWD" \
    ASC_DB_DUMPS_DIR=data/db/dumps REMOTE_DB_LOG="$log" REMOTE_DB_EXEC_STATUS=9 \
    bash asc/extensions/remote_asc/remote/db/sync_to.sh fixture '' separate 2>&1)"
  status=$?
  assertEquals 'failed remote prerequisite reaches public action' 9 "$status"
  assertFalse 'failed prerequisite prevents upload' "grep -q '^upload ' '$log'"
  assertFalse 'failed prerequisite prevents restore' "grep -q 'db-restore' '$log'"

  : > "$log"
  output="$(cd "$REMOTE_DB_FIXTURE" && env HOME="$PWD/home" PROJECT_DOCROOT="$PWD" \
    ASC_DB_DUMPS_DIR=data/db/dumps REMOTE_DB_LOG="$log" REMOTE_DB_RESTORE_STATUS=13 \
    bash asc/extensions/remote_asc/remote/db/sync_to.sh fixture '' separate 2>&1)"
  status=$?
  assertEquals 'remote restore failure reaches public action' 13 "$status"
  assertFalse 'remote restore failure suppresses success' "[[ \"\$output\" == *'Restoring '*': done.'* ]]"

  : > "$log"
  output="$(cd "$REMOTE_DB_FIXTURE" && env HOME="$PWD/home" PROJECT_DOCROOT="$PWD" \
    ASC_DB_DUMPS_DIR=data/db/dumps REMOTE_DB_LOG="$log" REMOTE_DB_SET_STATUS=11 \
    bash asc/extensions/remote_asc/remote/db/sync_from.sh fixture '' separate 2>&1)"
  status=$?
  assertEquals 'failed database selection reaches public action' 11 "$status"
  assertFalse 'failed database selection prevents download' "grep -q '^download ' '$log'"
  assertFalse 'failed database selection prevents restore' "grep -q '^clear ' '$log'"
}

##
# Explicit source paths stay inside the selected destination DB directory.
#
test_explicit_paths_cannot_escape_dump_directories() {
  local output status log action
  log="$REMOTE_DB_FIXTURE/operations.log"
  printf '%s\n' fixture > "$REMOTE_DB_FIXTURE/outside.sql"
  : > "$log"
  output="$(cd "$REMOTE_DB_FIXTURE" && env HOME="$PWD/home" PROJECT_DOCROOT="$PWD" \
    ASC_DB_DUMPS_DIR=data/db/dumps REMOTE_DB_LOG="$log" \
    bash asc/extensions/remote_asc/remote/db/sync_to.sh fixture "$REMOTE_DB_FIXTURE/outside.sql" separate 2>&1)"
  status=$?
  assertEquals "explicit sync-to succeeds: $output" 0 "$status"
  assertTrue 'upload targets selected remote DB directory' "grep -Fq 'data/db/dumps/manually-uploaded-sync/separate/outside.sql' '$log'"

  for action in sync_from dl_from; do
    : > "$log"
    output="$(cd "$REMOTE_DB_FIXTURE" && env HOME="$PWD/home" PROJECT_DOCROOT="$PWD" \
      ASC_DB_DUMPS_DIR=data/db/dumps REMOTE_DB_LOG="$log" \
      bash "asc/extensions/remote_asc/remote/db/$action.sh" fixture /tmp/../../outside.sql separate 2>&1)"
    status=$?
    assertEquals "$action explicit path succeeds: $output" 0 "$status"
    assertTrue "$action targets selected local DB directory" "grep -Fq 'download fixture /tmp/../../outside.sql data/db/dumps/fixture/separate/outside.sql' '$log'"

    : > "$log"
    output="$(cd "$REMOTE_DB_FIXTURE" && env HOME="$PWD/home" PROJECT_DOCROOT="$PWD" \
      ASC_DB_DUMPS_DIR=data/db/dumps REMOTE_DB_LOG="$log" \
      bash "asc/extensions/remote_asc/remote/db/$action.sh" fixture /tmp/.. separate 2>&1)"
    status=$?
    assertNotEquals "$action rejects directory traversal basename" 0 "$status"
    assertFalse "$action rejects unsafe basename before download" "grep -q '^download ' '$log'"
  done
}

##
# Sync-to selects the requested database's latest dump and restore target.
#
test_sync_to_selects_database_dump_and_restore_target() {
  local fixture_dir output status
  fixture_dir="$(mktemp -d)"
  mkdir -p "$fixture_dir/local/default" "$fixture_dir/local/separate"
  printf '%s\n' default > "$fixture_dir/local/default/default.sql"
  printf '%s\n' separate > "$fixture_dir/local/separate/separate.sql"

  output="$(
    ASC_DB_DUMPS_DIR="$fixture_dir"
    f_remote_instance_load() { REMOTE_INSTANCE_SSH_CONNECT_CMD=fixture; }
    f_db_set() { DB_ID="${1:-default}"; }
    f_remote_upload() { printf 'UPLOAD:%s\n' "$2"; }
    f_remote_exec_wrapper() { printf 'REMOTE:%s\n' "$*"; }
    f_remote_sync_db_to fixture '' separate
  )"
  status=$?

  assertEquals 'sync-to succeeds' 0 "$status"
  assertTrue 'uploads separate database dump' "[[ \"\$output\" == *'local/separate/separate.sql'* ]]"
  assertTrue 'remote restore receives separate database ID' "[[ \"\$output\" == *'separate.sql separate'* ]]"
  rm -rf -- "$fixture_dir"
}

##
# A failed clear must prevent import and reach the caller.
#
test_restore_stops_after_clear_failure() {
  local fixture_file marker status
  fixture_file="$(mktemp)"
  marker="${fixture_file}.import"
  (
    f_db_clear() { return 7; }
    f_db_exec() { touch "$marker"; }
    f_db_restore "$fixture_file" separate
  )
  status=$?

  assertEquals 'clear failure propagates' 7 "$status"
  assertFalse 'failed clear prevents import' "[ -e '$marker' ]"
  rm -f -- "$fixture_file" "$marker"
}

##
# Real backup helper returns the full path created for the selected database.
#
test_routine_backup_returns_database_scoped_path() {
  local fixture_dir result
  fixture_dir="$(mktemp -d)"
  result="$(
    ASC_DB_DUMPS_DIR="$fixture_dir"
    ASC_DB_DUMPS_LOCAL_PATTERN=fixture
    f_db_set() { DB_ID="$1"; DB_NAME="$1"; }
    f_str_convert_tokens() { printf -v "$2" '%s' 'fixture.sql'; }
    f_db_dump() { mkdir -p "${1%/*}"; : > "$1.gz"; }
    f_db_routine_backup separate || exit $?
    printf '%s' "$routine_dump_file"
  )"
  assertEquals 'routine path includes selected database' "$fixture_dir/local/separate/fixture.sql.gz" "$result"
  assertTrue 'routine path exists' "[ -f '$result' ]"
  rm -rf -- "$fixture_dir"
}

##
# Failed remote enumeration must not fall through to a local restore.
#
test_restore_any_stops_when_remote_inventory_fails() {
  local fixture_dir status
  fixture_dir="$(mktemp -d)"
  mkdir -p "$fixture_dir/local/separate"
  : > "$fixture_dir/local/separate/dump.sql.gz"
  (
    ASC_DB_DUMPS_DIR="$fixture_dir"
    f_db_set() { DB_ID="$1"; }
    f_remote_get_instances() { return 12; }
    f_db_restore() { touch "$fixture_dir/restored"; }
    f_db_restore_any separate
  )
  status=$?
  assertEquals 'failed remote inventory propagates' 12 "$status"
  assertFalse 'local restore does not run after inventory failure' "[ -e '$fixture_dir/restored' ]"
  rm -rf -- "$fixture_dir"
}

##
# remote-db-dl-from new must download the path from a real dump hook.
#
# External database commands are stubbed. Dump progress stays off that path.
#
test_new_dump_path_excludes_hook_progress() {
  local fixture bin output err status log source
  fixture="$(mktemp -d)"
  bin="$fixture/bin"
  log="$fixture/scp.log"
  cp -a asc scripts .asc_extensions_ignore "$fixture/"
  sed -i -e '/^db$/d' -e '/^remote$/d' -e '/^remote_asc$/d' -e '/^asc\/mysql$/d' \
    "$fixture/.asc_extensions_ignore"
  chmod +x "$fixture/asc/extensions/remote/remote/exec.sh" \
    "$fixture/asc/extensions/db/db/get_dump.sh"
  mkdir -p "$bin" "$fixture/home" "$fixture/data/instance/remote" "$fixture/data/db/dumps"

  cat > "$bin/mysqldump" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' '-- stub dump'
STUB
  cat > "$bin/scp" <<'STUB'
#!/usr/bin/env bash
printf '%q\n' "$1" >> "$DUMP_SCP_LOG"
dest="${!#}"
mkdir -p -- "${dest%/*}"
printf '%s\n' downloaded > "$dest"
STUB
  cat > "$bin/local-ssh" <<STUB
#!/usr/bin/env bash
cd '$fixture' || exit 1
exec bash -c "\$1"
STUB
  chmod +x "$bin/mysqldump" "$bin/scp" "$bin/local-ssh"

  cat > "$fixture/data/instance/remote/fixture.sh" <<STUB
#!/usr/bin/env bash
# ASC generated remote instance
export REMOTE_INSTANCE_ID='fixture'
export REMOTE_INSTANCE_DOCROOT='$fixture'
export REMOTE_INSTANCE_SSH_CONNECT_CMD='$bin/local-ssh'
export REMOTE_INSTANCE_PREFIX='dump@example.invalid'
export REMOTE_INSTANCE_HOST='example.invalid'
export REMOTE_INSTANCE_SSH_USER='dump'
STUB

  output="$(
    cd "$fixture" && env -i \
      HOME="$fixture/home" \
      PATH="$bin:/usr/bin:/bin" \
      PWD="$fixture" \
      PROJECT_DOCROOT="$fixture" \
      DUMP_SCP_LOG="$log" \
      ASC_DB_MODE=none \
      ASC_DB_DUMPS_DIR=data/db/dumps \
      ASC_DB_DUMPS_LOCAL_PATTERN='new-dump.{{ DUMP_FILE_EXTENSION }}' \
      SEPARATE_DB_NAME=separate \
      SEPARATE_DB_USER=sepuser \
      SEPARATE_DB_PASS=seppass \
      SEPARATE_DB_DRIVER=mysql \
      SEPARATE_DB_HOST=127.0.0.1 \
      SEPARATE_DB_PORT=3306 \
      bash asc/extensions/remote_asc/remote/db/dl_from.sh fixture new separate \
      2>"$fixture/err"
  )"
  status=$?
  err="$(cat "$fixture/err")"
  source="$(cat "$log" 2>/dev/null)"

  assertEquals "download succeeds: $output $err" 0 "$status"
  assertEquals 'download source is only the dump path' \
    "dump@example.invalid:$fixture/data/db/dumps/local/separate/new-dump.sql.gz" \
    "$source"
  assertTrue 'dump progress stays visible' "[[ \"\$err\" == *'Creating separate DB mysql dump'* ]]"
  rm -rf -- "$fixture"
}

##
# Remove the disposable action tree.
#
oneTimeTearDown() {
  rm -rf -- "$REMOTE_DB_FIXTURE"
}

. asc/vendor/shunit2/shunit2
