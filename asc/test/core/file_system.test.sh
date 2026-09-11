#!/usr/bin/env bash

##
# ASC core file system related tests.
#
# @requires asc/vendor/shunit2
#
# This file may be dynamically executed.
# @see asc/test/core.sh
#
# @example
#   asc/test/asc/fsop.test.sh
#

. asc/bootstrap.sh

##
# Can ASC create directories in current dir ?
#
# @evol see asc/vendor/shunit2/examples/mkdir_test.sh
#
test_asc_can_create_dir() {
  mkdir '_asc_dir_test'
  assertTrue 'Directory missing (creation test failed)' "[ -d '_asc_dir_test' ]"
}

##
# Can ASC change permissions ?
#
test_asc_can_chmod() {
  local rtrn
  chmod 700 '_asc_dir_test'
  rtrn=$?
  assertEquals 'Chmod failed (returned non-zero code)' 0 $rtrn
}

##
# Can ASC create files in current dir ?
#
test_asc_can_create_file() {
  touch '_asc_dir_test/_asc_file_test.txt'
  assertTrue 'File missing (creation test failed)' "[ -f '_asc_dir_test/_asc_file_test.txt' ]"
}

##
# Can ASC change ownership ?
# Update : removed (would require sudoing, not enforceable).
#
# test_asc_can_chown() {
#   local rtrn
#   chown 81:81 '_asc_dir_test/_asc_file_test.txt'
#   rtrn=$?
#   assertEquals 'Chown failed (returned non-zero code)' 0 $rtrn
# }

##
# f_fs_get_file_contents must load exact file bytes into a caller var.
#
test_f_fs_get_file_contents() {
  mkdir -p '_asc_dir_test'
  local f='_asc_dir_test/get_file_contents.txt'
  local got=''
  local expected=$'alpha\nbeta gamma\n'

  printf '%s' "$expected" > "$f"
  f_fs_get_file_contents "$f" 'got'
  assertEquals 'f_fs_get_file_contents should preserve contents.' "$expected" "$got"

  printf 'no-trailing-newline' > "$f"
  f_fs_get_file_contents "$f" 'got'
  assertEquals 'f_fs_get_file_contents should preserve missing final newline.' \
    'no-trailing-newline' "$got"

  assertFalse 'missing file should fail.' \
    "f_fs_get_file_contents '_asc_dir_test/missing.txt' 'got' 2>/dev/null"
}

##
# f_fs_relative_path must compute paths without forking dirname.
#
test_f_fs_relative_path() {
  relative_path=''
  f_fs_relative_path '/var/www/html/yetetets/testtset/fdsf.fd' '/var/www/html'
  assertEquals 'child under source' 'yetetets/testtset/fdsf.fd' "$relative_path"

  relative_path=''
  f_fs_relative_path '/' '/var/www/html'
  assertEquals 'root from nested source' '../../../' "$relative_path"

  relative_path=''
  f_fs_relative_path '/var/www/yetetets/testtset/fdsf.fd' '/opt/app'
  assertEquals 'sibling trees' '../../var/www/yetetets/testtset/fdsf.fd' "$relative_path"

  relative_path=''
  f_fs_relative_path 'data/db-dumps/foo.sql' '/project'
  assertEquals 'project-relative target' 'data/db-dumps/foo.sql' "$relative_path"
}

##
# Dir / file listing (depth 1 bash path) and most-recent lookup.
#
test_f_fs_dir_file_list_and_most_recent() {
  mkdir -p '_asc_dir_test/list/sub'
  touch '_asc_dir_test/list/a.txt' '_asc_dir_test/list/b.sh' '_asc_dir_test/list/sub/c.txt'
  sleep 0.05
  touch '_asc_dir_test/list/b.sh'

  dir_list=''
  f_fs_dir_list '_asc_dir_test/list'
  assertTrue 'dir_list should include sub' "[[ \"$dir_list\" == *sub* ]]"

  file_list=''
  file_list_arr=()
  f_fs_file_list '_asc_dir_test/list' '*.sh'
  assertTrue 'file_list should include b.sh' "[[ \"$file_list\" == *b.sh* ]]"
  assertEquals 'file_list_arr length for *.sh' '1' "${#file_list_arr[@]}"

  local most_recent
  most_recent="$(f_fs_get_most_recent '_asc_dir_test/list' '' 1 1)"
  assertTrue 'most recent should be b.sh' "[[ \"$most_recent\" == *b.sh ]]"
}

##
# Merge dirs, change_line, trim compression extension.
#
test_f_fs_merge_change_trim() {
  mkdir -p '_asc_dir_test/merge_src/nested' '_asc_dir_test/merge_dst'
  echo 'from-src' > '_asc_dir_test/merge_src/nested/item.txt'
  echo 'keep' > '_asc_dir_test/merge_dst/keep.txt'

  f_fs_merge_dirs '_asc_dir_test/merge_src' '_asc_dir_test/merge_dst' 'yes' 'yes'
  assertTrue 'merged nested file' "[ -f '_asc_dir_test/merge_dst/nested/item.txt' ]"
  assertFalse 'source removed after merge' "[ -d '_asc_dir_test/merge_src' ]"
  assertEquals 'merged content' 'from-src' "$(<'_asc_dir_test/merge_dst/nested/item.txt')"

  echo 'OLD line value' > '_asc_dir_test/change_line.txt'
  f_fs_change_line 'OLD' 'NEW line value' '_asc_dir_test/change_line.txt'
  assertEquals 'change_line' 'NEW line value' "$(<'_asc_dir_test/change_line.txt')"

  local uncompressed_file=''
  f_fs_trim_compression_ext 'path/to/dump.sql.gz'
  assertEquals 'trim .gz' 'path/to/dump.sql' "$uncompressed_file"
  f_fs_trim_compression_ext 'archive.tar.gz' 'uncompressed_file'
  assertEquals 'trim .tar.gz' 'archive' "$uncompressed_file"
}

##
# f_fs_compress / f_fs_extract (folder arg = containing dir of the leaf).
#
test_f_fs_compress_and_extract() {
  mkdir -p '_asc_dir_test/archive_src' '_asc_dir_test/extract_dst'
  echo 'payload' > '_asc_dir_test/archive_src/payload.txt'

  # compress "$leaf_path" "$parent_dir" → tar -C "$parent_dir" … "$leaf"
  f_fs_compress '_asc_dir_test/archive_src' '_asc_dir_test'
  assertTrue 'compress should create tgz in parent' \
    "[ -f '_asc_dir_test/archive_src.tgz' ]"

  f_fs_extract '_asc_dir_test/archive_src.tgz' '_asc_dir_test/extract_dst'
  assertTrue 'extract should restore payload under archive leaf dir' \
    "[ -f '_asc_dir_test/extract_dst/archive_src/payload.txt' ]"
}

##
# f_fs_watch_poll: one change detection then exit via callback.
#
test_f_fs_watch_poll() {
  mkdir -p '_asc_dir_test/watch'
  rm -f '_asc_dir_test/watch_fired'
  (
    f_fs_watch_poll '_asc_dir_test/watch' \
      'touch _asc_dir_test/watch_fired; exit 0' '' 1
  ) >/dev/null 2>&1 &
  local poll_pid=$!
  sleep 0.3
  echo x > '_asc_dir_test/watch/changed.txt'
  local i
  for ((i=0; i<20; i++)); do
    [[ -f '_asc_dir_test/watch_fired' ]] && break
    sleep 0.2
  done
  kill "$poll_pid" 2>/dev/null || true
  wait "$poll_pid" 2>/dev/null || true
  assertTrue 'watch_poll should fire on change' "[ -f '_asc_dir_test/watch_fired' ]"
}

##
# Cleans up any leftovers from previous tests.
#
# (Internal shunit2 function called after all tests have run.)
#
oneTimeTearDown() {
  rm -fr '_asc_dir_test'
}

# Load and run shUnit2.
. asc/vendor/shunit2/shunit2
