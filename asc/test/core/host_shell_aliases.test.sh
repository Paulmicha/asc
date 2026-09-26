#!/usr/bin/env bash

##
# Host shell alias map: closest instance script, plug written once.
#
# @requires asc/vendor/shunit2
# @see asc/host/shell/write_aliases.sh
# @see changelog/2026/09/26-host-shell-aliases-asc.md
#
# @example
#   asc/test/core/host_shell_aliases.test.sh
#

. asc/bootstrap.sh

oneTimeSetUp() {
  HOST_SHELL_ALIASES_TMP="$(mktemp -d)"
}

oneTimeTearDown() {
  if [[ -n "${HOST_SHELL_ALIASES_TMP:-}" && -d "$HOST_SHELL_ALIASES_TMP" ]]; then
    chmod -R u+rwx "$HOST_SHELL_ALIASES_TMP" 2>/dev/null || true
    rm -rf "$HOST_SHELL_ALIASES_TMP"
  fi
}

_host_shell_script() {
  local path="$1"
  local word="$2"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' '#!/usr/bin/env bash' "printf '%s\n' \"${word}\" \"\$PWD\" >> \"\$OUT\"" 'if [[ $# -gt 0 ]]; then printf "%s\n" "$*" >> "$OUT"; fi' >"$path"
  chmod 755 "$path"
}

test_writer_map_and_plug_once() {
  local home plug map needle count
  home="$HOST_SHELL_ALIASES_TMP/writer"
  mkdir -p "$home"
  plug="$home/.bash_aliases"
  map="$home/.bash_aliases_asc"
  printf '%s\n' "alias keep='true'" >"$plug"
  needle='[ -f ~/.bash_aliases_asc ] && . ~/.bash_aliases_asc'

  HOME="$home" asc/host/shell/write_aliases.sh
  assertEquals 'writer exits 0' 0 $?
  assertTrue 'map has the walker' "grep -q 'closest_asc_docroot_exec()' '$map'"
  assertTrue 'gacp alias calls the walker' \
    "grep -qx \"alias gacp='closest_asc_docroot_exec asc/instance/gacp.sh'\" '$map'"
  assertTrue 'plug keeps the existing alias' "grep -qx \"alias keep='true'\" '$plug'"
  count="$(grep -F -c -e "$needle" "$plug")"
  assertEquals 'plug sources the map once' 1 "$count"

  HOME="$home" asc/host/shell/write_aliases.sh
  count="$(grep -F -c -e "$needle" "$plug")"
  assertEquals 'second run does not add another source line' 1 "$count"
}

test_writer_does_not_create_a_missing_plug() {
  local home
  home="$HOST_SHELL_ALIASES_TMP/noplug"
  mkdir -p "$home"

  HOME="$home" asc/host/shell/write_aliases.sh
  assertEquals 'writer exits 0 when the plug is absent' 0 $?
  assertTrue 'map is written' "[[ -f '$home/.bash_aliases_asc' ]]"
  assertTrue 'plug is not created' "[[ ! -e '$home/.bash_aliases' ]]"
}

test_writer_rejects_a_plug_outside_the_allowlist() {
  local home
  home="$HOST_SHELL_ALIASES_TMP/badplug"
  mkdir -p "$home"

  HOME="$home" asc/host/shell/write_aliases.sh '../outside'
  assertFalse 'a path plug is rejected' "[[ $? -eq 0 ]]"
  assertTrue 'no map was written for a rejected plug' "[[ ! -e '$home/../outside_asc' ]]"
}

test_closest_script_prefers_the_nearer_tree() {
  local home out stay rc
  home="$HOST_SHELL_ALIASES_TMP/walk"
  out="$HOST_SHELL_ALIASES_TMP/out"
  stay="$PWD"
  mkdir -p "$home/proj/sub"
  _host_shell_script "$home/asc/instance/gacp.sh" home
  _host_shell_script "$home/proj/asc/instance/gacp.sh" proj
  : >"$out"

  (
    cd "$home/proj/sub" || exit 9
    HOME="$home" OUT="$out" . "$HOST_SHELL_ALIASES_TMP/writer/.bash_aliases_asc"
    closest_asc_docroot_exec asc/instance/gacp.sh one two
  )
  rc=$?
  assertEquals 'walker exits 0' 0 "$rc"
  assertEquals 'nearer script runs' "proj"$'\n'"$home/proj"$'\n'"one two" "$(cat "$out")"
  assertEquals 'caller directory stays' "$stay" "$PWD"
}

test_closest_script_uses_the_logical_symlink_path() {
  local home out rc
  home="$HOST_SHELL_ALIASES_TMP/walk"
  out="$HOST_SHELL_ALIASES_TMP/out"
  mkdir -p "$home/real/sub"
  _host_shell_script "$home/real/asc/instance/gacp.sh" real
  ln -s real/sub "$home/link"
  : >"$out"

  (
    cd "$home/link" || exit 9
    HOME="$home" OUT="$out" . "$HOST_SHELL_ALIASES_TMP/writer/.bash_aliases_asc"
    closest_asc_docroot_exec asc/instance/gacp.sh
  )
  rc=$?
  assertEquals 'logical walk exits 0' 0 "$rc"
  assertEquals 'symlink path uses its logical parent, not the physical project' \
    "home"$'\n'"$home" "$(cat "$out")"
}

test_closest_script_checks_home_last_when_outside_it() {
  local home out elsewhere
  home="$HOST_SHELL_ALIASES_TMP/walk"
  out="$HOST_SHELL_ALIASES_TMP/out"
  elsewhere="$HOST_SHELL_ALIASES_TMP/elsewhere"
  mkdir -p "$elsewhere"
  : >"$out"

  (
    cd "$elsewhere" || exit 9
    HOME="$home" OUT="$out" . "$HOST_SHELL_ALIASES_TMP/writer/.bash_aliases_asc"
    closest_asc_docroot_exec asc/instance/gacp.sh
  )
  assertEquals 'outside home still finds the home script' 0 $?
  assertEquals 'home script runs last' "home"$'\n'"$home"$'\n' "$(cat "$out")"
}

test_closest_script_does_not_climb_above_home() {
  local root home out
  root="$HOST_SHELL_ALIASES_TMP/above"
  home="$root/home"
  out="$HOST_SHELL_ALIASES_TMP/out"
  mkdir -p "$home/proj/sub"
  _host_shell_script "$root/asc/instance/gacp.sh" above
  : >"$out"

  (
    cd "$home/proj/sub" || exit 9
    HOME="$home" OUT="$out" . "$HOST_SHELL_ALIASES_TMP/writer/.bash_aliases_asc"
    closest_asc_docroot_exec asc/instance/gacp.sh
  )
  assertFalse 'a script above HOME is not run' "[[ $? -eq 0 ]]"
  assertEquals 'nothing above HOME ran' '' "$(cat "$out")"
}

test_closest_script_skips_an_unreadable_directory() {
  local home out
  home="$HOST_SHELL_ALIASES_TMP/walk"
  out="$HOST_SHELL_ALIASES_TMP/out"
  mkdir -p "$home/proj/blocked"
  chmod 000 "$home/proj/blocked"
  : >"$out"

  (
    HOME="$home" OUT="$out" PWD="$home/proj/blocked" \
      . "$HOST_SHELL_ALIASES_TMP/writer/.bash_aliases_asc"
    closest_asc_docroot_exec asc/instance/gacp.sh
  )
  local rc=$?
  chmod 755 "$home/proj/blocked"
  assertEquals 'unreadable directory is skipped' 0 "$rc"
  assertEquals 'parent project script runs' "proj"$'\n'"$home/proj"$'\n' "$(cat "$out")"
}

. asc/vendor/shunit2/shunit2
