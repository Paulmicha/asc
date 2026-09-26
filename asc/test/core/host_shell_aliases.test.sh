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

test_writer_bashrc_map_follows_the_plug() {
  local home needle
  home="$HOST_SHELL_ALIASES_TMP/bashrc"
  mkdir -p "$home"
  : >"$home/.bashrc"
  needle='[ -f ~/.bashrc_asc ] && . ~/.bashrc_asc'

  HOME="$home" asc/host/shell/write_aliases.sh .bashrc
  assertEquals 'bashrc plug writer exits 0' 0 $?
  assertTrue 'map is .bashrc_asc' "[[ -f '$home/.bashrc_asc' ]]"
  assertTrue 'default map is not written for this plug' "[[ ! -e '$home/.bash_aliases_asc' ]]"
  assertEquals 'plug sources its own map once' 1 "$(grep -F -c -e "$needle" "$home/.bashrc")"
}

test_writer_rejects_a_plug_outside_the_allowlist() {
  local home
  home="$HOST_SHELL_ALIASES_TMP/badplug"
  mkdir -p "$home"

  HOME="$home" asc/host/shell/write_aliases.sh '../outside'
  assertFalse 'a path plug is rejected' "[[ $? -eq 0 ]]"
  assertTrue 'no map was written for a rejected plug' "[[ ! -e '$home/../outside_asc' ]]"
}

# Not asc/instance/gacp.sh. A wrong PWD must not run this repo's gacp.
_host_shell_rel='asc/instance/host_shell_alias_fixture.sh'

_host_shell_walk() {
  local start="$1"
  local home="$2"
  local out="$3"
  shift 3
  (
    cd "$start" || exit 9
    export HOME="$home" OUT="$out"
    # shellcheck disable=SC1090
    . "$HOST_SHELL_ALIASES_TMP/writer/.bash_aliases_asc"
    closest_asc_docroot_exec "$_host_shell_rel" "$@"
  )
}

test_closest_script_prefers_the_nearer_tree() {
  local home out stay rc
  home="$HOST_SHELL_ALIASES_TMP/walk"
  out="$HOST_SHELL_ALIASES_TMP/out"
  stay="$PWD"
  mkdir -p "$home/proj/sub"
  _host_shell_script "$home/$_host_shell_rel" home
  _host_shell_script "$home/proj/$_host_shell_rel" proj
  : >"$out"

  _host_shell_walk "$home/proj/sub" "$home" "$out" one two
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
  _host_shell_script "$home/real/$_host_shell_rel" real
  ln -sfn real/sub "$home/link"
  : >"$out"

  _host_shell_walk "$home/link" "$home" "$out"
  rc=$?
  assertEquals 'logical walk exits 0' 0 "$rc"
  assertEquals 'symlink path uses its logical parent, not the physical project' \
    "home"$'\n'"$home" "$(cat "$out")"
}

test_closest_script_checks_home_last_when_outside_it() {
  local home out elsewhere rc
  home="$HOST_SHELL_ALIASES_TMP/walk"
  out="$HOST_SHELL_ALIASES_TMP/out"
  elsewhere="$HOST_SHELL_ALIASES_TMP/elsewhere"
  mkdir -p "$elsewhere"
  : >"$out"

  _host_shell_walk "$elsewhere" "$home" "$out"
  rc=$?
  assertEquals 'outside home still finds the home script' 0 "$rc"
  assertEquals 'home script runs last' "home"$'\n'"$home" "$(cat "$out")"
}

test_closest_script_does_not_climb_above_home() {
  local root home out rc
  root="$HOST_SHELL_ALIASES_TMP/above"
  home="$root/home"
  out="$HOST_SHELL_ALIASES_TMP/out"
  mkdir -p "$home/proj/sub"
  _host_shell_script "$root/$_host_shell_rel" above
  : >"$out"

  _host_shell_walk "$home/proj/sub" "$home" "$out"
  rc=$?
  assertFalse 'a script above HOME is not run' "[[ $rc -eq 0 ]]"
  assertEquals 'nothing above HOME ran' '' "$(cat "$out")"
}

test_closest_script_skips_an_unreadable_directory() {
  local home out rc
  home="$HOST_SHELL_ALIASES_TMP/walk"
  out="$HOST_SHELL_ALIASES_TMP/out"
  mkdir -p "$home/proj/blocked"
  chmod 000 "$home/proj/blocked"
  : >"$out"

  (
    cd "$home/proj" || exit 9
    export HOME="$home" OUT="$out"
    PWD="$home/proj/blocked"
    # shellcheck disable=SC1090
    . "$HOST_SHELL_ALIASES_TMP/writer/.bash_aliases_asc"
    closest_asc_docroot_exec "$_host_shell_rel"
  )
  rc=$?
  chmod 755 "$home/proj/blocked"
  assertEquals 'unreadable directory is skipped' 0 "$rc"
  assertEquals 'parent project script runs' "proj"$'\n'"$home/proj" "$(cat "$out")"
}

. asc/vendor/shunit2/shunit2
