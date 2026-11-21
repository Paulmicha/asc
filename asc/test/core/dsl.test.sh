#!/usr/bin/env bash

##
# ASC DSL interpreter and make ds carrier tests.
#
# @requires asc/vendor/shunit2
# @see docs/specs/asc/dsl.md
# @see docs/plans/2026/09/22-make-ds.md
# @see docs/plans/2026/11/19-dsl-line-breaks-and-dsl-txt.md
#
# @example
#   asc/test/core/dsl.test.sh
#

. asc/bootstrap.sh

##
# Build a disposable project root that owns probe/ds action files and its own
# discovery cache. Shipped ASC code is symlinked from the real checkout.
#
dsl_test_root_prepare() {
  local entry base ignore

  DSL_ROOT="$DSL_TEST_TMP/root"
  mkdir -p "$DSL_ROOT/asc/instance" "$DSL_ROOT/data/asc/cache" "$DSL_ROOT/scripts" \
    || return 1

  for entry in "$DSL_SRC"/asc/*; do
    base="${entry##*/}"
    case "$base" in
      instance)
        continue
        ;;
      *)
        ln -s "$entry" "$DSL_ROOT/asc/$base" || return 1
        ;;
    esac
  done

  for ignore in "$DSL_SRC"/asc/.asc_*; do
    if [[ -e "$ignore" ]]; then
      ln -s "$ignore" "$DSL_ROOT/asc/${ignore##*/}" || return 1
    fi
  done

  # Real instance dir: link shipped actions. Skip the probe name so a later
  # regular-file install cannot write through a symlink into the real checkout.
  for entry in "$DSL_SRC"/asc/instance/* "$DSL_SRC"/asc/instance/.[!.]*; do
    if [[ -e "$entry" ]]; then
      base="${entry##*/}"
      case "$base" in
        dsl_probe.sh)
          continue
          ;;
        *)
          ln -s "$entry" "$DSL_ROOT/asc/instance/$base" || return 1
          ;;
      esac
    fi
  done

  cp -f "$DSL_SRC/asc/test/core/dsl_probe.fixture.sh" "$DSL_ROOT/$DSL_PROBE_SCRIPT" \
    || return 1
  chmod +x "$DSL_ROOT/$DSL_PROBE_SCRIPT" || return 1

  ln -s "$DSL_SRC/Makefile" "$DSL_ROOT/Makefile" || return 1
  if [[ -e "$DSL_SRC/.asc_extensions_ignore" ]]; then
    ln -s "$DSL_SRC/.asc_extensions_ignore" "$DSL_ROOT/.asc_extensions_ignore" \
      || return 1
  fi
  if [[ -d "$DSL_SRC/scripts/asc" ]]; then
    ln -s "$DSL_SRC/scripts/asc" "$DSL_ROOT/scripts/asc" || return 1
  fi

  cd "$DSL_ROOT" || return 1

  # Cold primitives cache inside the disposable root only.
  f_asc_primitives_cache_ensure
}

##
# shUnit2 ignores oneTimeSetUp's return status — exit the process on failure.
#
dsl_test_setup_abort() {
  local p_reason="$1"

  echo >&2
  echo "Error in dsl.test.sh fixture setup: ${p_reason}" >&2
  echo "-> Aborting suite." >&2
  echo >&2

  if [[ -n "${DSL_SRC:-}" && -d "$DSL_SRC" ]]; then
    cd "$DSL_SRC" || true
  fi
  if [[ -n "${DSL_TEST_TMP:-}" && -d "$DSL_TEST_TMP" ]]; then
    rm -rf "$DSL_TEST_TMP"
  fi

  exit 1
}

oneTimeSetUp() {
  DSL_SRC="$PWD"
  DSL_TEST_TMP="$(mktemp -d)" || dsl_test_setup_abort 'mktemp failed'
  DSL_PROBE_SP='instance/dsl_probe'
  DSL_PROBE_SCRIPT='asc/instance/dsl_probe.sh'
  # f_make_task_name sanitizes '_' to '-'.
  DSL_PROBE_PIVOT='dsl-probe'
  # Drop inherited Make command-line assignments so a parent
  # `make … ASC_DS_EXPR=…` cannot override expressions this suite sets.
  # (Do not `env -u ASC_DS_EXPR` here — that would wipe per-invocation exports.)
  DSL_MAKE=(env -u MAKEFLAGS make --no-print-directory)

  if ! dsl_test_root_prepare; then
    dsl_test_setup_abort 'disposable project root prepare failed'
  fi

  if [[ "$PWD" != "$DSL_ROOT" || ! -d "$DSL_ROOT/asc/instance" ]]; then
    dsl_test_setup_abort "cwd is not the verified fixture root ($DSL_ROOT)"
  fi

  DSL_INSTANCE_DS="$DSL_ROOT/asc/instance/ds.sh"
}

oneTimeTearDown() {
  if [[ -n "${DSL_SRC:-}" && -d "$DSL_SRC" ]]; then
    cd "$DSL_SRC" || true
  fi

  if [[ -n "${DSL_TEST_TMP:-}" && -d "$DSL_TEST_TMP" ]]; then
    rm -rf "$DSL_TEST_TMP"
  fi
}

##
# §1 — slug dispatch via direct script.
#
test_dsl_slug_literal_dispatch() {
  local out rc=0

  out="$(asc/dsl.sh 'slug(foobar)' 2>/dev/null)" || rc=$?
  assertEquals 'slug(foobar) exits 0' 0 "$rc"
  assertEquals 'slug(foobar) stdout' 'foobar' "$out"
}

##
# §1 — discovered probe pivot + eligible hardcoded path resolution.
#
test_dsl_resolve_discovered_and_hardcoded() {
  local asc_dsl_script=''
  local rc=0
  local argv_file

  f_asc_dsl_resolve "$DSL_PROBE_PIVOT" || rc=$?
  assertEquals 'discovered probe resolves' 0 "$rc"
  assertEquals 'discovered probe path' "$DSL_PROBE_SCRIPT" "$asc_dsl_script"

  rc=0
  asc_dsl_script=''
  f_asc_dsl_resolve 'setup' || rc=$?
  assertEquals 'eligible hardcoded setup resolves' 0 "$rc"
  assertEquals 'setup path' 'asc/instance/setup.sh' "$asc_dsl_script"

  rc=0
  f_asc_dsl_resolve 'globals-lp' || rc=$?
  assertEquals 'eligible hardcoded globals-lp resolves' 0 "$rc"

  # Spec: exact final-name match, independent of the caller's nocasematch.
  shopt -s nocasematch
  rc=0
  err="$(f_asc_dsl 'SLUG(foobar)' 2>&1 >/dev/null)" || rc=$?
  assertEquals 'nocasematch does not fold pivot names' 1 "$rc"

  # Token 'A' must stay a literal (not binding 'a') under nocasematch.
  # Use the probe: slug() lowercases, which would hide a correct literal.
  argv_file="$DSL_TEST_TMP/nocase_A"
  rm -f "$argv_file"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" \
    f_asc_dsl "${DSL_PROBE_PIVOT}(A)" 2>/dev/null || rc=$?
  shopt -u nocasematch
  assertEquals 'nocasematch does not fold token A to binding a' 0 "$rc"
  assertEquals 'literal A preserved' 'A' "$(tr '\0' '\n' < "$argv_file")"
}

##
# §1 — exact final-name lookup; reserved / compound names rejected.
#
test_dsl_reject_reserved_and_unknown() {
  local rc=0
  local err=''

  err="$(f_asc_dsl 'ds' 2>&1 >/dev/null)" || rc=$?
  assertEquals 'ds reserved exits nonzero' 1 "$rc"
  assertTrue 'ds diagnostic' "[[ \"$err\" == *'not eligible'* || \"$err\" == *'reserved'* ]]"

  rc=0
  err="$(f_asc_dsl 'debug' 2>&1 >/dev/null)" || rc=$?
  assertEquals 'debug rejected' 1 "$rc"

  rc=0
  err="$(f_asc_dsl 'hook-debug' 2>&1 >/dev/null)" || rc=$?
  assertEquals 'hook-debug rejected' 1 "$rc"

  rc=0
  err="$(f_asc_dsl 'init-debug' 2>&1 >/dev/null)" || rc=$?
  assertEquals 'init-debug rejected' 1 "$rc"

  rc=0
  err="$(f_asc_dsl 'definitely-not-a-pivot-zz' 2>&1 >/dev/null)" || rc=$?
  assertEquals 'unknown pivot rejected' 1 "$rc"
  assertTrue 'unknown diagnostic' "[[ \"$err\" == *'unknown pivot'* ]]"
}

##
# §1 — argv vector: literals, quotes, %, bindings; binding spellings exact.
#
test_dsl_argv_vector_and_bindings() {
  local argv_file marker err rc=0 lines=''

  argv_file="$DSL_TEST_TMP/argv1"
  marker="$DSL_TEST_TMP/marker1"
  rm -f "$argv_file" "$marker"

  ASC_DSL_PROBE_ARGV="$argv_file" ASC_DSL_PROBE_MARKER="$marker" \
    f_asc_dsl "${DSL_PROBE_PIVOT}('a b','','p1',%%,%,p1,a,s1)" -- 'x y' 'z' 2>/dev/null \
    || rc=$?

  assertEquals 'probe call exits 0' 0 "$rc"
  assertTrue 'marker written' "[[ -f '$marker' ]]"

  lines="$(tr '\0' '\n' < "$argv_file")"
  assertEquals 'argv[1] quoted with space' 'a b' "$(printf '%s\n' "$lines" | sed -n '1p')"
  assertEquals 'argv[2] empty' '' "$(printf '%s\n' "$lines" | sed -n '2p')"
  assertEquals 'argv[3] quoted reserved' 'p1' "$(printf '%s\n' "$lines" | sed -n '3p')"
  assertEquals 'argv[4] %%' '**' "$(printf '%s\n' "$lines" | sed -n '4p')"
  assertEquals 'argv[5] %' '*' "$(printf '%s\n' "$lines" | sed -n '5p')"
  assertEquals 'argv[6] p1' 'x y' "$(printf '%s\n' "$lines" | sed -n '6p')"
  assertEquals 'argv[7] a→first' 'x y' "$(printf '%s\n' "$lines" | sed -n '7p')"
  assertEquals 'argv[8] a→second' 'z' "$(printf '%s\n' "$lines" | sed -n '8p')"
  assertEquals 'argv[9] s1→first remaining' 'z' "$(printf '%s\n' "$lines" | sed -n '9p')"

  rc=0
  err="$(f_asc_dsl "${DSL_PROBE_PIVOT}(p1)" 2>&1 >/dev/null)" || rc=$?
  assertEquals 'p1 without -- fails' 1 "$rc"
  assertTrue 'unbound diagnostic' "[[ \"$err\" == *'--'* ]]"

  rc=0
  argv_file="$DSL_TEST_TMP/argv_empty"
  rm -f "$argv_file"
  ASC_DSL_PROBE_ARGV="$argv_file" \
    f_asc_dsl "${DSL_PROBE_PIVOT}(a)" -- 2>/dev/null || rc=$?
  assertEquals 'empty bound vector ok' 0 "$rc"
  assertEquals 'a with empty vector → empty file' '' "$(cat "$argv_file")"

  rc=0
  err="$(f_asc_dsl "${DSL_PROBE_PIVOT}(p2)" -- only-one 2>&1 >/dev/null)" || rc=$?
  assertEquals 'out-of-range p2 fails' 1 "$rc"
  assertTrue 'range diagnostic' "[[ \"$err\" == *'out of range'* ]]"

  # p12abc / s12abc are literals, not bindings (entire-token numeric suffix).
  argv_file="$DSL_TEST_TMP/argv_lit_bind"
  rm -f "$argv_file"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" \
    f_asc_dsl "${DSL_PROBE_PIVOT}(p12abc,s12abc)" 2>/dev/null || rc=$?
  assertEquals 'p12abc/s12abc as literals exit 0' 0 "$rc"
  lines="$(tr '\0' '\n' < "$argv_file")"
  assertEquals 'p12abc stays literal' 'p12abc' "$(printf '%s\n' "$lines" | sed -n '1p')"
  assertEquals 's12abc stays literal' 's12abc' "$(printf '%s\n' "$lines" | sed -n '2p')"

  # Leading-zero / oversized suffixes must not reach Bash arithmetic or dispatch.
  marker="$DSL_TEST_TMP/bind_octal"
  rm -f "$marker"
  rc=0
  err="$(ASC_DSL_PROBE_MARKER="$marker" \
    f_asc_dsl "${DSL_PROBE_PIVOT}(s08)" -- a b 2>&1 >/dev/null)" || rc=$?
  assertEquals 's08 rejected' 1 "$rc"
  assertTrue 's08 no dispatch' "[[ ! -f '$marker' ]]"
  assertTrue 's08 diagnostic' \
    "[[ \"$err\" == *'unsupported'* || \"$err\" == *'binding'* ]]"

  marker="$DSL_TEST_TMP/bind_huge"
  rm -f "$marker"
  rc=0
  err="$(ASC_DSL_PROBE_MARKER="$marker" \
    f_asc_dsl "${DSL_PROBE_PIVOT}(p18446744073709551617)" -- a b 2>&1 >/dev/null)" || rc=$?
  assertEquals 'huge pN rejected' 1 "$rc"
  assertTrue 'huge pN no dispatch' "[[ ! -f '$marker' ]]"
  assertTrue 'huge pN diagnostic' "[[ \"$err\" == *'out of range'* ]]"
}

##
# §1 — unsupported reserved tokens rejected; quoted forms stay literals.
#
test_dsl_reject_unsupported_reserved_tokens() {
  local marker err rc=0 argv_file lines=''

  for token in 'v-PROJECT_DOCROOT' 'd0' 'bb-oneline'; do
    marker="$DSL_TEST_TMP/reserved_${token}"
    rm -f "$marker"
    rc=0
    err="$(ASC_DSL_PROBE_MARKER="$marker" \
      f_asc_dsl "${DSL_PROBE_PIVOT}(${token})" 2>&1 >/dev/null)" || rc=$?
    assertEquals "unquoted ${token} rejected" 1 "$rc"
    assertTrue "unquoted ${token} no dispatch" "[[ ! -f '$marker' ]]"
    assertTrue "unquoted ${token} diagnostic" \
      "[[ \"$err\" == *'unsupported reserved'* || \"$err\" == *'${token}'* ]]"
  done

  argv_file="$DSL_TEST_TMP/quoted_reserved"
  rm -f "$argv_file"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" \
    f_asc_dsl "${DSL_PROBE_PIVOT}('v-PROJECT_DOCROOT','d0','bb-oneline')" 2>/dev/null \
    || rc=$?
  assertEquals 'quoted reserved forms exit 0' 0 "$rc"
  lines="$(tr '\0' '\n' < "$argv_file")"
  assertEquals 'quoted v- form' 'v-PROJECT_DOCROOT' "$(printf '%s\n' "$lines" | sed -n '1p')"
  assertEquals 'quoted d0' 'd0' "$(printf '%s\n' "$lines" | sed -n '2p')"
  assertEquals 'quoted bb-oneline' 'bb-oneline' "$(printf '%s\n' "$lines" | sed -n '3p')"
}

##
# §1 — status return; truncated / trailing-comma never execute.
#
test_dsl_status_and_no_exec_on_error() {
  local marker post=0 rc=0 err=''

  marker="$DSL_TEST_TMP/status_marker"
  rm -f "$marker"

  ASC_DSL_PROBE_MARKER="$marker" ASC_DSL_PROBE_STATUS=7 \
    f_asc_dsl "${DSL_PROBE_PIVOT}()" 2>/dev/null || rc=$?
  post=1

  assertEquals 'f_asc_dsl returns probe status' 7 "$rc"
  assertEquals 'caller continues after failure' 1 "$post"
  assertTrue 'probe ran for status case' "[[ -f '$marker' ]]"

  rc=0
  ASC_DSL_PROBE_STATUS=5 asc/dsl.sh "${DSL_PROBE_PIVOT}()" 2>/dev/null || rc=$?
  assertEquals 'asc/dsl.sh propagates status' 5 "$rc"

  marker="$DSL_TEST_TMP/no_exec"
  rm -f "$marker"
  rc=0
  err="$(ASC_DSL_PROBE_MARKER="$marker" f_asc_dsl "${DSL_PROBE_PIVOT}(a;b)" 2>&1 >/dev/null)" || rc=$?
  assertEquals 'malformed combinator rejected' 1 "$rc"
  assertTrue 'no execution marker for malformed' "[[ ! -f '$marker' ]]"
  assertTrue 'malformed diagnostic' "[[ -n \"$err\" ]]"

  marker="$DSL_TEST_TMP/no_exec2"
  rm -f "$marker"
  rc=0
  err="$(ASC_DSL_PROBE_MARKER="$marker" f_asc_dsl '[echo(hi)]' 2>&1 >/dev/null)" || rc=$?
  assertEquals 'bracket form rejected' 1 "$rc"
  assertTrue 'no marker for bracket form' "[[ ! -f '$marker' ]]"

  marker="$DSL_TEST_TMP/no_exec3"
  rm -f "$marker"
  rc=0
  err="$(ASC_DSL_PROBE_MARKER="$marker" f_asc_dsl 'not-a-real-pivot-xyz()' 2>&1 >/dev/null)" || rc=$?
  assertEquals 'unknown rejected' 1 "$rc"
  assertTrue 'no marker for unknown' "[[ ! -f '$marker' ]]"

  marker="$DSL_TEST_TMP/trunc_comma"
  rm -f "$marker"
  rc=0
  err="$(ASC_DSL_PROBE_MARKER="$marker" f_asc_dsl "${DSL_PROBE_PIVOT}(foo," 2>&1 >/dev/null)" || rc=$?
  assertEquals 'trailing comma without ) rejected' 1 "$rc"
  assertTrue 'no marker for trailing comma' "[[ ! -f '$marker' ]]"
  assertTrue 'trailing comma diagnostic' "[[ \"$err\" == *'unclosed'* ]]"

  marker="$DSL_TEST_TMP/trunc_open"
  rm -f "$marker"
  rc=0
  err="$(ASC_DSL_PROBE_MARKER="$marker" f_asc_dsl "${DSL_PROBE_PIVOT}(foo" 2>&1 >/dev/null)" || rc=$?
  assertEquals 'truncated open paren rejected' 1 "$rc"
  assertTrue 'no marker for truncated' "[[ ! -f '$marker' ]]"
}

##
# Hardcoded Make list hygiene (init path, ds present, debug args).
#
test_make_list_hardcoded_hygiene() {
  local pivots_arr=()
  local real_scripts_arr=()
  local i
  local init_path='' ds_path='' init_debug_path=''

  f_make_list_hardcoded

  for i in "${!pivots_arr[@]}"; do
    case "${pivots_arr[i]}" in
      init) init_path="${real_scripts_arr[i]}" ;;
      ds) ds_path="${real_scripts_arr[i]}" ;;
      init-debug) init_debug_path="${real_scripts_arr[i]}" ;;
    esac
  done

  assertEquals 'init path matches default.mk' 'asc/instance/init.sh' "$init_path"
  assertEquals 'ds is listed' 'asc/dsl.sh' "$ds_path"
  assertEquals 'init-debug keeps recipe args' 'asc/instance/init.sh -d -r' "$init_debug_path"
  assertTrue 'ds is hardcoded reserved' 'f_make_is_hardcoded_name ds'
}

##
# §2 — ASC_DS_EXPR carrier: deliver expression; shell ops do not run; spaces.
#
test_make_ds_expr_carrier_safety() {
  local marker out rc=0 argv_file lines='' make_err='' err=''

  rc=0
  out="$(ASC_DS_EXPR='slug(foobar)' "${DSL_MAKE[@]}" ds 2>/dev/null)" || rc=$?
  assertEquals 'ASC_DS_EXPR slug exits 0' 0 "$rc"
  assertEquals 'ASC_DS_EXPR slug stdout' 'foobar' "$out"

  # Spaces in expression via env (claimed Make carrier path).
  argv_file="$DSL_TEST_TMP/make_space_argv"
  marker="$DSL_TEST_TMP/make_space_marker"
  rm -f "$argv_file" "$marker"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" ASC_DSL_PROBE_MARKER="$marker" \
    ASC_DS_EXPR="${DSL_PROBE_PIVOT}('a b')" "${DSL_MAKE[@]}" ds 2>/dev/null || rc=$?
  assertEquals 'Make space expression exits 0' 0 "$rc"
  lines="$(tr '\0' '\n' < "$argv_file")"
  assertEquals 'Make delivers spaced argv' 'a b' "$(printf '%s\n' "$lines" | sed -n '1p')"

  # Semicolon would create marker if shell-interpreted.
  marker="$DSL_TEST_TMP/make_semi_marker"
  rm -f "$marker"
  rc=0
  err="$(ASC_DS_EXPR="true;touch $marker" "${DSL_MAKE[@]}" ds 2>&1 >/dev/null)" || rc=$?
  assertTrue 'semicolon marker absent' "[[ ! -f '$marker' ]]"
  assertFalse 'semicolon expression not success' "[[ $rc -eq 0 ]]"
  assertTrue 'semicolon expression reached interpreter' \
    "[[ \"$err\" == *'true;touch'* || \"$err\" == *'unsupported'* || \"$err\" == *'pivot'* ]]"

  # Plus operator — touch would run if shell split on +.
  marker="$DSL_TEST_TMP/make_plus_marker"
  rm -f "$marker"
  rc=0
  ASC_DS_EXPR="true+touch $marker" "${DSL_MAKE[@]}" ds 2>/dev/null || rc=$?
  assertTrue 'plus marker absent' "[[ ! -f '$marker' ]]"
  assertFalse 'plus expression not success' "[[ $rc -eq 0 ]]"

  # ;; unsupported grammar delivered as data then rejected (literal args, not bindings).
  marker="$DSL_TEST_TMP/make_dsemi_marker"
  rm -f "$marker"
  rc=0
  err="$(ASC_DS_EXPR="slug(x);;touch ${marker}" "${DSL_MAKE[@]}" ds 2>&1 >/dev/null)" || rc=$?
  assertTrue ';; marker absent' "[[ ! -f '$marker' ]]"
  assertFalse ';; failed recipe' "[[ $rc -eq 0 ]]"
  assertTrue ';; exact expression reached interpreter' \
    "[[ \"$err\" == *'slug(x);;touch'* ]]"

  argv_file="$DSL_TEST_TMP/make_argv"
  marker="$DSL_TEST_TMP/make_probe_marker"
  rm -f "$argv_file" "$marker"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" ASC_DSL_PROBE_MARKER="$marker" \
    ASC_DS_EXPR="${DSL_PROBE_PIVOT}(hello)" "${DSL_MAKE[@]}" ds 2>/dev/null || rc=$?
  assertEquals 'make ds probe exits 0' 0 "$rc"
  lines="$(tr '\0' '\n' < "$argv_file")"
  assertEquals 'make ds delivers probe argv' 'hello' "$(printf '%s\n' "$lines" | sed -n '1p')"

  rc=0
  make_err="$(ASC_DSL_PROBE_STATUS=9 ASC_DS_EXPR="${DSL_PROBE_PIVOT}()" \
    "${DSL_MAKE[@]}" ds 2>&1 >/dev/null)" || rc=$?
  assertFalse 'make ds surfaces probe failure' "[[ $rc -eq 0 ]]"
  assertTrue 'make mentions recipe Error 9' "[[ \"$make_err\" == *'Error 9'* ]]"

  # Missing ASC_DS_EXPR fails closed (do not inherit env or MAKEFLAGS values).
  rc=0
  err="$(env -u ASC_DS_EXPR -u MAKEFLAGS make --no-print-directory ds 2>&1 >/dev/null)" || rc=$?
  assertFalse 'make ds without ASC_DS_EXPR fails' "[[ $rc -eq 0 ]]"
  assertTrue 'missing ASC_DS_EXPR diagnostic' "[[ \"$err\" == *'ASC_DS_EXPR'* ]]"
}

##
# §2 — colliding Make goals must not execute expression as shell (−k, both orders).
#
test_make_ds_collision_goals_no_shell() {
  local marker rc=0 err=''

  marker="$DSL_TEST_TMP/collide_marker"
  rm -f "$marker"
  rc=0
  err="$("${DSL_MAKE[@]}" -k ds "true;touch $marker" debug 2>&1)" || rc=$?
  assertTrue 'order ds+expr+debug: marker absent' "[[ ! -f '$marker' ]]"
  assertTrue 'order ds+expr+debug: makefile refuses companions' \
    "[[ \"$err\" == *'do not combine with other Make goals'* || \"$err\" == *'refusing'* ]]"

  rm -f "$marker"
  rc=0
  err="$("${DSL_MAKE[@]}" -k debug ds "true;touch $marker" 2>&1)" || rc=$?
  assertTrue 'order debug+ds+expr: marker absent' "[[ ! -f '$marker' ]]"
  assertTrue 'order debug+ds+expr: makefile refuses companions' \
    "[[ \"$err\" == *'do not combine with other Make goals'* || \"$err\" == *'refusing'* ]]"

  # Mixed hardcoded goals with ds are refused explicitly (debug's wrapper would
  # otherwise treat ds as a reserved MAKECMDGOALS value).
  rm -f "$marker"
  rc=0
  err="$(ASC_DS_EXPR="true;touch $marker" "${DSL_MAKE[@]}" -k ds debug 2>&1)" || rc=$?
  assertTrue 'ds+debug: shell marker absent' "[[ ! -f '$marker' ]]"
  assertTrue 'ds+debug refused at parse time' \
    "[[ \"$err\" == *'do not combine with other Make goals'* || \"$err\" == *'refusing'* ]]"
  assertFalse 'ds+debug is not success' "[[ $rc -eq 0 ]]"
}

##
# §2 — literal ∓ / = / \$ not mutated by Make DSL carrier.
#
test_make_ds_no_legacy_unescape() {
  local argv_file lines='' rc=0

  argv_file="$DSL_TEST_TMP/lit_direct"
  rm -f "$argv_file"
  ASC_DSL_PROBE_ARGV="$argv_file" \
    f_asc_dsl "${DSL_PROBE_PIVOT}('a∓b','a=b','a\$b')" 2>/dev/null || rc=$?
  assertEquals 'direct literals exit 0' 0 "$rc"
  lines="$(tr '\0' '\n' < "$argv_file")"
  assertEquals 'direct keeps ∓' 'a∓b' "$(printf '%s\n' "$lines" | sed -n '1p')"
  assertEquals 'direct keeps =' 'a=b' "$(printf '%s\n' "$lines" | sed -n '2p')"
  assertEquals 'direct keeps $' 'a$b' "$(printf '%s\n' "$lines" | sed -n '3p')"

  argv_file="$DSL_TEST_TMP/lit_make"
  rm -f "$argv_file"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" \
    ASC_DS_EXPR="${DSL_PROBE_PIVOT}('a∓b','a=b','a\$b')" "${DSL_MAKE[@]}" ds 2>/dev/null || rc=$?
  assertEquals 'make literals exit 0' 0 "$rc"
  lines="$(tr '\0' '\n' < "$argv_file")"
  assertEquals 'make keeps ∓' 'a∓b' "$(printf '%s\n' "$lines" | sed -n '1p')"
  assertEquals 'make keeps =' 'a=b' "$(printf '%s\n' "$lines" | sed -n '2p')"
  assertEquals 'make keeps $' 'a$b' "$(printf '%s\n' "$lines" | sed -n '3p')"
}

##
# §2 — generate into disposable fixtures: clean, upgrade, reserved collision.
#
test_make_ds_pivots_generation_fixtures() {
  local fixture gen_mk gen_sh gen_tc
  local stale_mk
  local out=''
  local saved_actions
  local ds_count=0

  . asc/make/generate.sh

  fixture="$DSL_TEST_TMP/gen_clean"
  mkdir -p "$fixture/data/asc/cache"
  gen_mk="$fixture/data/asc/pivots.mk"
  gen_sh="$fixture/data/asc/cache/pivots.sh"
  gen_tc="$fixture/data/asc/cache/test-cases.sh"

  ASC_MAKE_GENERATE_PIVOTS_MK="$gen_mk" \
    ASC_MAKE_GENERATE_PIVOTS_SH="$gen_sh" \
    ASC_MAKE_GENERATE_TEST_CASES="$gen_tc" \
    f_make_generate >/dev/null

  assertEquals 'clean fixture: no generated .PHONY ds' \
    0 "$(grep -c '^\.PHONY: ds$' "$gen_mk" || true)"
  assertEquals 'clean fixture: no instance/ds.sh' \
    '' "$(grep -E 'asc/instance/ds\.sh' "$gen_mk" "$gen_sh" || true)"
  assertTrue 'clean fixture cache has hardcoded dsl.sh' \
    "grep -q \"real_scripts_arr+=('asc/dsl.sh')\" '$gen_sh'"
  assertTrue 'clean fixture cache lists ds once from hardcoded' \
    "grep -q \"pivots_arr+=('ds')\" '$gen_sh'"

  # Upgrade fixture: former generated ds recipe overwritten by generate.
  fixture="$DSL_TEST_TMP/gen_upgrade"
  mkdir -p "$fixture/data/asc/cache"
  gen_mk="$fixture/data/asc/pivots.mk"
  gen_sh="$fixture/data/asc/cache/pivots.sh"
  gen_tc="$fixture/data/asc/cache/test-cases.sh"
  stale_mk="$gen_mk"

  cat > "$stale_mk" <<'EOF'

.PHONY: ds
ds:
	@ asc/make/call_wrap.make.sh asc/instance/ds.sh $(MAKECMDGOALS)

EOF

  assertTrue 'upgrade fixture starts with old ds recipe' \
    "grep -q 'asc/instance/ds.sh' '$stale_mk'"

  ASC_MAKE_GENERATE_PIVOTS_MK="$gen_mk" \
    ASC_MAKE_GENERATE_PIVOTS_SH="$gen_sh" \
    ASC_MAKE_GENERATE_TEST_CASES="$gen_tc" \
    f_make_generate >/dev/null

  assertEquals 'upgrade fixture: no .PHONY ds after generate' \
    0 "$(grep -c '^\.PHONY: ds$' "$gen_mk" || true)"
  assertEquals 'upgrade fixture: old instance/ds.sh removed' \
    '' "$(grep -E 'asc/instance/ds\.sh' "$gen_mk" "$gen_sh" || true)"

  # Discovered instance/ds collision: reservation filter must drop the recipe
  # and keep a single hardcoded ds cache record.
  fixture="$DSL_TEST_TMP/gen_collide"
  mkdir -p "$fixture/data/asc/cache"
  gen_mk="$fixture/data/asc/pivots.mk"
  gen_sh="$fixture/data/asc/cache/pivots.sh"
  gen_tc="$fixture/data/asc/cache/test-cases.sh"

  # Absolute path under the verified fixture root only.
  if [[ -z "${DSL_INSTANCE_DS:-}" || "$DSL_INSTANCE_DS" != "$DSL_ROOT/asc/instance/ds.sh" ]]; then
    fail 'collision test requires DSL_INSTANCE_DS under the fixture root'
    return
  fi

  rm -f "$DSL_INSTANCE_DS"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$DSL_INSTANCE_DS"
  chmod +x "$DSL_INSTANCE_DS"
  saved_actions="$ASC_ACTIONS"
  case " $ASC_ACTIONS " in
    *" instance/ds "*) ;;
    *) ASC_ACTIONS="${ASC_ACTIONS} instance/ds" ;;
  esac

  ASC_MAKE_GENERATE_PIVOTS_MK="$gen_mk" \
    ASC_MAKE_GENERATE_PIVOTS_SH="$gen_sh" \
    ASC_MAKE_GENERATE_TEST_CASES="$gen_tc" \
    f_make_generate >/dev/null

  ASC_ACTIONS="$saved_actions"
  rm -f "$DSL_INSTANCE_DS"

  assertEquals 'discovered ds collision: no generated .PHONY ds' \
    0 "$(grep -c '^\.PHONY: ds$' "$gen_mk" || true)"
  assertEquals 'discovered ds collision: no instance/ds.sh recipe path' \
    '' "$(grep -E 'asc/instance/ds\.sh' "$gen_mk" || true)"
  ds_count="$(grep -c "pivots_arr+=('ds')" "$gen_sh" || true)"
  assertEquals 'discovered ds collision: exactly one cached ds' 1 "$ds_count"
  assertTrue 'discovered ds collision: cached path is hardcoded dsl.sh' \
    "grep -q \"real_scripts_arr+=('asc/dsl.sh')\" '$gen_sh'"
}

##
# Line-break / *.dsl.txt slice — sequencing (append-only log + statuses).
#
test_dsl_newline_sequencing_log_and_status() {
  local log rc=0 err='' prog

  log="$DSL_TEST_TMP/seq_log"
  prog="$DSL_TEST_TMP/seq_inline.dsl.txt"

  # 7 → 0 : both IDs in order; status 0.
  rm -f "$log"
  rc=0
  ASC_DSL_PROBE_LOG="$log" ASC_DSL_PROBE_STATUS_ARGV=2 \
    f_asc_dsl "${DSL_PROBE_PIVOT}('call-a','7')
${DSL_PROBE_PIVOT}('call-b','0')" 2>/dev/null || rc=$?
  assertEquals '7→0 status is 0' 0 "$rc"
  assertEquals '7→0 exact log' $'call-a\ncall-b' "$(cat "$log")"

  # 0 → 7 : both IDs; status 7.
  rm -f "$log"
  rc=0
  ASC_DSL_PROBE_LOG="$log" ASC_DSL_PROBE_STATUS_ARGV=2 \
    f_asc_dsl "${DSL_PROBE_PIVOT}('call-a','0')
${DSL_PROBE_PIVOT}('call-b','7')" 2>/dev/null || rc=$?
  assertEquals '0→7 status is 7' 7 "$rc"
  assertEquals '0→7 exact log' $'call-a\ncall-b' "$(cat "$log")"

  # Intervening blank line : same as two-call sequence.
  rm -f "$log"
  rc=0
  ASC_DSL_PROBE_LOG="$log" ASC_DSL_PROBE_STATUS_ARGV=2 \
    f_asc_dsl "${DSL_PROBE_PIVOT}('call-a','0')

${DSL_PROBE_PIVOT}('call-b','0')" 2>/dev/null || rc=$?
  assertEquals 'blank line status 0' 0 "$rc"
  assertEquals 'blank line exact log' $'call-a\ncall-b' "$(cat "$log")"

  # bash -e child runs the interpreter (shebang ignored when bash runs the file).
  rm -f "$log"
  printf '%s\n' \
    "${DSL_PROBE_PIVOT}('call-a','7')" \
    "${DSL_PROBE_PIVOT}('call-b','0')" > "$prog"
  rc=0
  ASC_DSL_PROBE_LOG="$log" ASC_DSL_PROBE_STATUS_ARGV=2 \
    bash -e asc/dsl.sh "$prog" 2>/dev/null || rc=$?
  assertEquals 'bash -e 7→0 child status 0' 0 "$rc"
  assertEquals 'bash -e 7→0 exact log' $'call-a\ncall-b' "$(cat "$log")"
}

##
# Line-break slice — layout newlines, empty list, quoted newline, unclosed quote.
#
test_dsl_layout_quotes_and_empty_list() {
  local argv_file log rc=0 err=''

  argv_file="$DSL_TEST_TMP/layout_argv"
  rm -f "$argv_file"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" f_asc_dsl "${DSL_PROBE_PIVOT}(
  'a',
  'b'
)" 2>/dev/null || rc=$?
  assertEquals 'wrapped arg list exits 0' 0 "$rc"
  printf 'a\0b\0' > "$DSL_TEST_TMP/layout_expected"
  assertTrue 'wrapped arg list NUL argv' \
    "cmp -s '$argv_file' '$DSL_TEST_TMP/layout_expected'"

  # Whitespace-only empty list is valid (same as name()).
  log="$DSL_TEST_TMP/empty_list_log"
  rm -f "$log"
  rc=0
  ASC_DSL_PROBE_LOG="$log" f_asc_dsl "${DSL_PROBE_PIVOT}(
)" 2>/dev/null || rc=$?
  assertEquals 'empty list with newline exits 0' 0 "$rc"
  assertEquals 'empty list log' 'ran' "$(cat "$log")"

  # Quoted newline : one argv field containing LF.
  argv_file="$DSL_TEST_TMP/quoted_nl_argv"
  rm -f "$argv_file"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" \
    f_asc_dsl "${DSL_PROBE_PIVOT}('line1
line2')" 2>/dev/null || rc=$?
  assertEquals 'quoted newline exits 0' 0 "$rc"
  printf 'line1\nline2\0' > "$DSL_TEST_TMP/quoted_nl_expected"
  assertTrue 'quoted newline single NUL field' \
    "cmp -s '$argv_file' '$DSL_TEST_TMP/quoted_nl_expected'"

  # Unclosed quote spanning a newline : no dispatch.
  log="$DSL_TEST_TMP/unclosed_quote_log"
  rm -f "$log"
  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" f_asc_dsl "${DSL_PROBE_PIVOT}('open
" 2>&1 >/dev/null)" || rc=$?
  assertEquals 'unclosed quote nonzero' 1 "$rc"
  assertTrue 'unclosed quote diagnostic' "[[ \"$err\" == *'unclosed'* ]]"
  assertEquals 'unclosed quote empty log' '' "$(cat "$log" 2>/dev/null || true)"
}

##
# Line-break slice — preparse-all (syntax, resolve, bindings fail before dispatch).
#
test_dsl_preparse_all_no_dispatch() {
  local log rc=0 err=''

  log="$DSL_TEST_TMP/preparse_log"

  rm -f "$log"
  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" f_asc_dsl "${DSL_PROBE_PIVOT}('call-a')
not-a-real-pivot-zz()" 2>&1 >/dev/null)" || rc=$?
  assertEquals 'unknown second pivot nonzero' 1 "$rc"
  assertTrue 'unknown second pivot diagnostic' "[[ \"$err\" == *'unknown pivot'* ]]"
  assertEquals 'unknown second pivot empty log' '' "$(cat "$log" 2>/dev/null || true)"

  rm -f "$log"
  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" f_asc_dsl "${DSL_PROBE_PIVOT}('call-a')
${DSL_PROBE_PIVOT}(foo" 2>&1 >/dev/null)" || rc=$?
  assertEquals 'truncated second call nonzero' 1 "$rc"
  assertTrue 'truncated second call diagnostic' "[[ \"$err\" == *'unclosed'* ]]"
  assertEquals 'truncated second call empty log' '' "$(cat "$log" 2>/dev/null || true)"

  rm -f "$log"
  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" f_asc_dsl "${DSL_PROBE_PIVOT}('call-a')
${DSL_PROBE_PIVOT}(p2)" -- only-one 2>&1 >/dev/null)" || rc=$?
  assertEquals 'binding error on second call nonzero' 1 "$rc"
  assertTrue 'binding error diagnostic' "[[ \"$err\" == *'out of range'* ]]"
  assertEquals 'binding error empty log' '' "$(cat "$log" 2>/dev/null || true)"
}

##
# Line-break slice — *.dsl.txt file mode, Make carrier, NUL/CRLF, bound argv.
#
test_dsl_file_mode_and_make_carrier() {
  local log argv_file rc=0 err='' prog out=''
  local missing nonreg unread nul_prog crlf_prog eq_prog

  log="$DSL_TEST_TMP/file_seq_log"
  prog="$DSL_TEST_TMP/multi.dsl.txt"
  printf '%s\n' \
    "${DSL_PROBE_PIVOT}('call-a','0')" \
    "${DSL_PROBE_PIVOT}('call-b','0')" > "$prog"

  rm -f "$log"
  rc=0
  ASC_DSL_PROBE_LOG="$log" ASC_DSL_PROBE_STATUS_ARGV=2 \
    asc/dsl.sh "$prog" 2>/dev/null || rc=$?
  assertEquals 'dsl.sh file program exits 0' 0 "$rc"
  assertEquals 'dsl.sh file exact log' $'call-a\ncall-b' "$(cat "$log")"

  rm -f "$log"
  rc=0
  ASC_DSL_PROBE_LOG="$log" ASC_DSL_PROBE_STATUS_ARGV=2 \
    ASC_DS_EXPR="$prog" "${DSL_MAKE[@]}" ds 2>/dev/null || rc=$?
  assertEquals 'make ds file program exits 0' 0 "$rc"
  assertEquals 'make ds file exact log' $'call-a\ncall-b' "$(cat "$log")"

  # Inline regression via Make still works.
  rc=0
  out="$(ASC_DS_EXPR='slug(foobar)' "${DSL_MAKE[@]}" ds 2>/dev/null)" || rc=$?
  assertEquals 'ASC_DS_EXPR inline slug exits 0' 0 "$rc"
  assertEquals 'ASC_DS_EXPR inline slug stdout' 'foobar' "$out"

  # Missing ASC_DS_EXPR still fails closed.
  rc=0
  err="$(env -u ASC_DS_EXPR -u MAKEFLAGS make --no-print-directory ds 2>&1 >/dev/null)" || rc=$?
  assertFalse 'make ds without ASC_DS_EXPR fails' "[[ $rc -eq 0 ]]"
  assertTrue 'missing ASC_DS_EXPR diagnostic' "[[ \"$err\" == *'ASC_DS_EXPR'* ]]"

  # File errors : missing / non-regular / unreadable.
  missing="$DSL_TEST_TMP/missing-no-such.dsl.txt"
  rm -f "$missing" "$log"
  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" f_asc_dsl "$missing" 2>&1 >/dev/null)" || rc=$?
  assertEquals 'missing .dsl.txt nonzero' 1 "$rc"
  assertTrue 'missing .dsl.txt diagnostic' "[[ \"$err\" == *'not found'* ]]"
  assertEquals 'missing .dsl.txt empty log' '' "$(cat "$log" 2>/dev/null || true)"

  nonreg="$DSL_TEST_TMP/dir.dsl.txt"
  rm -rf "$nonreg" "$log"
  mkdir -p "$nonreg"
  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" f_asc_dsl "$nonreg" 2>&1 >/dev/null)" || rc=$?
  assertEquals 'non-regular .dsl.txt nonzero' 1 "$rc"
  assertTrue 'non-regular diagnostic' "[[ \"$err\" == *'not a regular file'* ]]"
  assertEquals 'non-regular empty log' '' "$(cat "$log" 2>/dev/null || true)"
  rmdir "$nonreg"

  unread="$DSL_TEST_TMP/unreadable.dsl.txt"
  printf '%s\n' "${DSL_PROBE_PIVOT}()" > "$unread"
  chmod a-r "$unread"
  rm -f "$log"
  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" f_asc_dsl "$unread" 2>&1 >/dev/null)" || rc=$?
  chmod u+r "$unread"
  assertEquals 'unreadable .dsl.txt nonzero' 1 "$rc"
  assertTrue 'unreadable diagnostic' "[[ \"$err\" == *'not readable'* ]]"
  assertEquals 'unreadable empty log' '' "$(cat "$log" 2>/dev/null || true)"

  # Embedded NUL rejected before parse/dispatch.
  nul_prog="$DSL_TEST_TMP/nul.dsl.txt"
  printf '%s\0%s\n' "${DSL_PROBE_PIVOT}('call-a')" "${DSL_PROBE_PIVOT}('call-b')" \
    > "$nul_prog"
  rm -f "$log"
  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" f_asc_dsl "$nul_prog" 2>&1 >/dev/null)" || rc=$?
  assertEquals 'embedded NUL nonzero' 1 "$rc"
  assertTrue 'embedded NUL diagnostic' "[[ \"$err\" == *'NUL'* ]]"
  assertEquals 'embedded NUL empty log' '' "$(cat "$log" 2>/dev/null || true)"

  # CRLF between top-level calls; quoted CR+LF preserved in argv.
  crlf_prog="$DSL_TEST_TMP/crlf.dsl.txt"
  printf "%s\r\n%s\r\n" \
    "${DSL_PROBE_PIVOT}('call-a','0')" \
    "${DSL_PROBE_PIVOT}('call-b','0')" > "$crlf_prog"
  rm -f "$log"
  rc=0
  ASC_DSL_PROBE_LOG="$log" ASC_DSL_PROBE_STATUS_ARGV=2 \
    f_asc_dsl "$crlf_prog" 2>/dev/null || rc=$?
  assertEquals 'CRLF sequencing exits 0' 0 "$rc"
  assertEquals 'CRLF sequencing exact log' $'call-a\ncall-b' "$(cat "$log")"

  argv_file="$DSL_TEST_TMP/crlf_quoted_argv"
  printf "%s\n" "${DSL_PROBE_PIVOT}('x"$'\r\n'"y')" > "$crlf_prog"
  rm -f "$argv_file"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" f_asc_dsl "$crlf_prog" 2>/dev/null || rc=$?
  assertEquals 'quoted CRLF exits 0' 0 "$rc"
  # Avoid $(...) NUL stripping : compare files with cmp.
  printf 'x\r\ny\0' > "$DSL_TEST_TMP/crlf_quoted_expected"
  assertTrue 'quoted CRLF preserved byte-for-byte' \
    "cmp -s '$argv_file' '$DSL_TEST_TMP/crlf_quoted_expected'"

  # Bound argv with file form.
  eq_prog="$DSL_TEST_TMP/bound.dsl.txt"
  printf '%s\n' "${DSL_PROBE_PIVOT}(p1)" > "$eq_prog"
  argv_file="$DSL_TEST_TMP/bound_file_argv"
  rm -f "$argv_file"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" \
    asc/dsl.sh "$eq_prog" -- 'bound' 2>/dev/null || rc=$?
  assertEquals 'file + bound argv exits 0' 0 "$rc"
  printf 'bound\0' > "$DSL_TEST_TMP/bound_expected"
  assertTrue 'file expands p1' "cmp -s '$argv_file' '$DSL_TEST_TMP/bound_expected'"

  # Path may contain '=' (file mode by suffix; not parsed as inline).
  eq_prog="$DSL_TEST_TMP/release=2.dsl.txt"
  printf '%s\n' \
    "${DSL_PROBE_PIVOT}('call-a','0')" \
    "${DSL_PROBE_PIVOT}('call-b','0')" > "$eq_prog"
  rm -f "$log"
  rc=0
  ASC_DSL_PROBE_LOG="$log" ASC_DSL_PROBE_STATUS_ARGV=2 \
    f_asc_dsl "$eq_prog" 2>/dev/null || rc=$?
  assertEquals 'path with = exits 0' 0 "$rc"
  assertEquals 'path with = exact log' $'call-a\ncall-b' "$(cat "$log")"
}

##
# Gap fixes — single-snapshot load, bare CR, exact .dsl.txt suffix.
#
test_dsl_load_snapshot_bare_cr_suffix() {
  local log rc=0 err='' prog loaded size
  local upper_path

  log="$DSL_TEST_TMP/gap_log"

  # Happy path : loaded byte length matches pre-copy file size.
  prog="$DSL_TEST_TMP/snap_ok.dsl.txt"
  printf '%s\n' "${DSL_PROBE_PIVOT}('call-a')" "${DSL_PROBE_PIVOT}('call-b')" > "$prog"
  size=$(stat -c '%s' -- "$prog")
  rc=0
  f_asc_dsl_load_file "$prog" || rc=$?
  assertEquals 'snapshot load exits 0' 0 "$rc"
  loaded=$(printf '%s' "$asc_dsl_program" | wc -c)
  loaded="${loaded#"${loaded%%[![:space:]]*}"}"
  assertEquals 'snapshot loaded length matches file size' "$size" "$loaded"

  # Concurrent truncate during capture : mutate the snapshot between copy and
  # validation (test hook). Old loaders that only inspected the snap would
  # accept the shortened buffer and dispatch; size mismatch must fail closed.
  prog="$DSL_TEST_TMP/snap_race.dsl.txt"
  printf '%s\n' \
    "${DSL_PROBE_PIVOT}('call-a')" \
    "${DSL_PROBE_PIVOT}('call-b')" > "$prog"
  rm -f "$log"

  f_asc_dsl_test_after_snap_copy() {
    local p_snap="$1"
    local partial="$DSL_TEST_TMP/snap_race.partial"

    # Keep only the first call — same shape as truncate-during-cat.
    head -n 1 "$p_snap" > "$partial" || return 1
    mv -f "$partial" "$p_snap" || return 1
  }

  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" f_asc_dsl "$prog" 2>&1 >/dev/null)" || rc=$?
  unset -f f_asc_dsl_test_after_snap_copy
  assertEquals 'mid-capture truncate nonzero' 1 "$rc"
  assertTrue 'mid-capture truncate diagnostic' \
    "[[ \"$err\" == *'changed during read'* || \"$err\" == *'mismatch'* ]]"
  assertEquals 'mid-capture truncate empty log' '' "$(cat "$log" 2>/dev/null || true)"

  # Validation command failure must not compare empty-equal as success.
  prog="$DSL_TEST_TMP/snap_unreadable_snap.dsl.txt"
  printf '%s\n' "${DSL_PROBE_PIVOT}('call-a')" > "$prog"
  rm -f "$log"

  f_asc_dsl_test_after_snap_copy() {
    chmod a-r "$1" || return 1
  }

  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" f_asc_dsl "$prog" 2>&1 >/dev/null)" || rc=$?
  unset -f f_asc_dsl_test_after_snap_copy
  # Restore in case the snap path leaked; temp files are under DSL_TEST_TMP.
  assertEquals 'validation cmd failure nonzero' 1 "$rc"
  assertTrue 'validation cmd failure diagnostic' \
    "[[ \"$err\" == *'could not be validated'* || \"$err\" == *'snapshot'* ]]"
  assertEquals 'validation cmd failure empty log' '' "$(cat "$log" 2>/dev/null || true)"

  # NUL after a valid call : fail closed, no partial dispatch of the prefix.
  prog="$DSL_TEST_TMP/snap_nul.dsl.txt"
  printf '%s\0%s\n' "${DSL_PROBE_PIVOT}('call-a')" "${DSL_PROBE_PIVOT}('call-b')" \
    > "$prog"
  rm -f "$log"
  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" f_asc_dsl "$prog" 2>&1 >/dev/null)" || rc=$?
  assertEquals 'snapshot NUL nonzero' 1 "$rc"
  assertTrue 'snapshot NUL diagnostic' "[[ \"$err\" == *'NUL'* ]]"
  assertEquals 'snapshot NUL empty log' '' "$(cat "$log" 2>/dev/null || true)"

  # Bare CR between calls must not sequence : fail closed, no dispatch.
  rm -f "$log"
  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" ASC_DSL_PROBE_STATUS_ARGV=2 \
    f_asc_dsl "${DSL_PROBE_PIVOT}('call-a','0')"$'\r'"${DSL_PROBE_PIVOT}('call-b','0')" \
    2>&1 >/dev/null)" || rc=$?
  assertFalse 'bare CR does not succeed' "[[ $rc -eq 0 ]]"
  assertEquals 'bare CR empty log' '' "$(cat "$log" 2>/dev/null || true)"

  # Exact suffix : .DSL.TXT is not file mode even under nocasematch.
  upper_path="$DSL_TEST_TMP/upper.DSL.TXT"
  printf '%s\n' "${DSL_PROBE_PIVOT}()" > "$upper_path"
  rm -f "$log"
  shopt -s nocasematch
  rc=0
  err="$(ASC_DSL_PROBE_LOG="$log" f_asc_dsl "$upper_path" 2>&1 >/dev/null)" || rc=$?
  shopt -u nocasematch
  assertEquals 'nocasematch .DSL.TXT not file mode (nonzero)' 1 "$rc"
  assertTrue 'nocasematch .DSL.TXT treated as inline' \
    "[[ \"$err\" == *'unsupported'* || \"$err\" == *'pivot'* || \"$err\" == *'expected'* || \"$err\" == *'syntax'* ]]"
  assertEquals 'nocasematch .DSL.TXT empty log' '' "$(cat "$log" 2>/dev/null || true)"
}

. asc/vendor/shunit2/shunit2
