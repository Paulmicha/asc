#!/usr/bin/env bash

##
# First-slice ASC DSL interpreter and make ds carrier tests.
#
# @requires asc/vendor/shunit2
# @see docs/specs/asc/dsl.md
# @see docs/plans/2026/09/22-make-ds.md
#
# @example
#   asc/test/core/dsl.test.sh
#

. asc/bootstrap.sh

oneTimeSetUp() {
  DSL_TEST_TMP="$(mktemp -d)"
}

oneTimeTearDown() {
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

  f_asc_dsl_resolve 'test-dsl-probe' || rc=$?
  assertEquals 'discovered probe resolves' 0 "$rc"
  assertEquals 'discovered probe path' 'asc/test/dsl_probe.sh' "$asc_dsl_script"

  rc=0
  asc_dsl_script=''
  f_asc_dsl_resolve 'setup' || rc=$?
  assertEquals 'eligible hardcoded setup resolves' 0 "$rc"
  assertEquals 'setup path' 'asc/instance/setup.sh' "$asc_dsl_script"

  rc=0
  f_asc_dsl_resolve 'globals-lp' || rc=$?
  assertEquals 'eligible hardcoded globals-lp resolves' 0 "$rc"
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
    f_asc_dsl "test-dsl-probe('a b','','p1',%%,%,p1,a,s1)" -- 'x y' 'z' 2>/dev/null \
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
  err="$(f_asc_dsl 'test-dsl-probe(p1)' 2>&1 >/dev/null)" || rc=$?
  assertEquals 'p1 without -- fails' 1 "$rc"
  assertTrue 'unbound diagnostic' "[[ \"$err\" == *'--'* ]]"

  rc=0
  argv_file="$DSL_TEST_TMP/argv_empty"
  rm -f "$argv_file"
  ASC_DSL_PROBE_ARGV="$argv_file" \
    f_asc_dsl 'test-dsl-probe(a)' -- 2>/dev/null || rc=$?
  assertEquals 'empty bound vector ok' 0 "$rc"
  assertEquals 'a with empty vector → empty file' '' "$(cat "$argv_file")"

  rc=0
  err="$(f_asc_dsl 'test-dsl-probe(p2)' -- only-one 2>&1 >/dev/null)" || rc=$?
  assertEquals 'out-of-range p2 fails' 1 "$rc"
  assertTrue 'range diagnostic' "[[ \"$err\" == *'out of range'* ]]"

  # p12abc / s12abc are literals, not bindings (entire-token numeric suffix).
  argv_file="$DSL_TEST_TMP/argv_lit_bind"
  rm -f "$argv_file"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" \
    f_asc_dsl 'test-dsl-probe(p12abc,s12abc)' 2>/dev/null || rc=$?
  assertEquals 'p12abc/s12abc as literals exit 0' 0 "$rc"
  lines="$(tr '\0' '\n' < "$argv_file")"
  assertEquals 'p12abc stays literal' 'p12abc' "$(printf '%s\n' "$lines" | sed -n '1p')"
  assertEquals 's12abc stays literal' 's12abc' "$(printf '%s\n' "$lines" | sed -n '2p')"
}

##
# §1 — status return; truncated / trailing-comma never execute.
#
test_dsl_status_and_no_exec_on_error() {
  local marker post=0 rc=0 err=''

  marker="$DSL_TEST_TMP/status_marker"
  rm -f "$marker"

  ASC_DSL_PROBE_MARKER="$marker" ASC_DSL_PROBE_STATUS=7 \
    f_asc_dsl 'test-dsl-probe()' 2>/dev/null || rc=$?
  post=1

  assertEquals 'f_asc_dsl returns probe status' 7 "$rc"
  assertEquals 'caller continues after failure' 1 "$post"
  assertTrue 'probe ran for status case' "[[ -f '$marker' ]]"

  rc=0
  ASC_DSL_PROBE_STATUS=5 asc/dsl.sh 'test-dsl-probe()' 2>/dev/null || rc=$?
  assertEquals 'asc/dsl.sh propagates status' 5 "$rc"

  marker="$DSL_TEST_TMP/no_exec"
  rm -f "$marker"
  rc=0
  err="$(ASC_DSL_PROBE_MARKER="$marker" f_asc_dsl 'test-dsl-probe(a;b)' 2>&1 >/dev/null)" || rc=$?
  assertEquals 'malformed combinator rejected' 1 "$rc"
  assertTrue 'no execution marker for malformed' "[[ ! -f '$marker' ]]"
  assertTrue 'malformed diagnostic' "[[ -n \"$err\" ]]"

  marker="$DSL_TEST_TMP/no_exec2"
  rm -f "$marker"
  rc=0
  ASC_DSL_PROBE_MARKER="$marker" f_asc_dsl '[echo(hi)]' 2>/dev/null || rc=$?
  assertEquals 'bracket form rejected' 1 "$rc"
  assertTrue 'no marker for bracket form' "[[ ! -f '$marker' ]]"

  marker="$DSL_TEST_TMP/no_exec3"
  rm -f "$marker"
  rc=0
  ASC_DSL_PROBE_MARKER="$marker" f_asc_dsl 'not-a-real-pivot-xyz()' 2>/dev/null || rc=$?
  assertEquals 'unknown rejected' 1 "$rc"
  assertTrue 'no marker for unknown' "[[ ! -f '$marker' ]]"

  marker="$DSL_TEST_TMP/trunc_comma"
  rm -f "$marker"
  rc=0
  err="$(ASC_DSL_PROBE_MARKER="$marker" f_asc_dsl 'test-dsl-probe(foo,' 2>&1 >/dev/null)" || rc=$?
  assertEquals 'trailing comma without ) rejected' 1 "$rc"
  assertTrue 'no marker for trailing comma' "[[ ! -f '$marker' ]]"
  assertTrue 'trailing comma diagnostic' "[[ \"$err\" == *'unclosed'* ]]"

  marker="$DSL_TEST_TMP/trunc_open"
  rm -f "$marker"
  rc=0
  err="$(ASC_DSL_PROBE_MARKER="$marker" f_asc_dsl 'test-dsl-probe(foo' 2>&1 >/dev/null)" || rc=$?
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
  out="$(ASC_DS_EXPR='slug(foobar)' make ds 2>/dev/null)" || rc=$?
  assertEquals 'ASC_DS_EXPR slug exits 0' 0 "$rc"
  assertEquals 'ASC_DS_EXPR slug stdout' 'foobar' "$out"

  # Spaces in expression via env (claimed Make carrier path).
  argv_file="$DSL_TEST_TMP/make_space_argv"
  marker="$DSL_TEST_TMP/make_space_marker"
  rm -f "$argv_file" "$marker"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" ASC_DSL_PROBE_MARKER="$marker" \
    ASC_DS_EXPR="test-dsl-probe('a b')" make ds 2>/dev/null || rc=$?
  assertEquals 'Make space expression exits 0' 0 "$rc"
  lines="$(tr '\0' '\n' < "$argv_file")"
  assertEquals 'Make delivers spaced argv' 'a b' "$(printf '%s\n' "$lines" | sed -n '1p')"

  # Semicolon would create marker if shell-interpreted.
  marker="$DSL_TEST_TMP/make_semi_marker"
  rm -f "$marker"
  rc=0
  err="$(ASC_DS_EXPR="true;touch $marker" make ds 2>&1 >/dev/null)" || rc=$?
  assertTrue 'semicolon marker absent' "[[ ! -f '$marker' ]]"
  assertFalse 'semicolon expression not success' "[[ $rc -eq 0 ]]"
  assertTrue 'semicolon expression reached interpreter' \
    "[[ \"$err\" == *'true;touch'* || \"$err\" == *'unsupported'* || \"$err\" == *'pivot'* ]]"

  # Plus operator — touch would run if shell split on +.
  marker="$DSL_TEST_TMP/make_plus_marker"
  rm -f "$marker"
  rc=0
  ASC_DS_EXPR="true+touch $marker" make ds 2>/dev/null || rc=$?
  assertTrue 'plus marker absent' "[[ ! -f '$marker' ]]"
  assertFalse 'plus expression not success' "[[ $rc -eq 0 ]]"

  # ;; unsupported grammar delivered as data then rejected (literal args, not bindings).
  marker="$DSL_TEST_TMP/make_dsemi_marker"
  rm -f "$marker"
  rc=0
  err="$(ASC_DS_EXPR="slug(x);;touch ${marker}" make ds 2>&1 >/dev/null)" || rc=$?
  assertTrue ';; marker absent' "[[ ! -f '$marker' ]]"
  assertFalse ';; failed recipe' "[[ $rc -eq 0 ]]"
  assertTrue ';; exact expression reached interpreter' \
    "[[ \"$err\" == *'slug(x);;touch'* ]]"

  argv_file="$DSL_TEST_TMP/make_argv"
  marker="$DSL_TEST_TMP/make_probe_marker"
  rm -f "$argv_file" "$marker"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" ASC_DSL_PROBE_MARKER="$marker" \
    ASC_DS_EXPR='test-dsl-probe(hello)' make ds 2>/dev/null || rc=$?
  assertEquals 'make ds probe exits 0' 0 "$rc"
  lines="$(tr '\0' '\n' < "$argv_file")"
  assertEquals 'make ds delivers probe argv' 'hello' "$(printf '%s\n' "$lines" | sed -n '1p')"

  rc=0
  make_err="$(ASC_DSL_PROBE_STATUS=9 ASC_DS_EXPR='test-dsl-probe()' make ds 2>&1 >/dev/null)" || rc=$?
  assertFalse 'make ds surfaces probe failure' "[[ $rc -eq 0 ]]"
  assertTrue 'make mentions recipe Error 9' "[[ \"$make_err\" == *'Error 9'* ]]"

  # Missing ASC_DS_EXPR fails closed.
  rc=0
  make ds 2>/dev/null || rc=$?
  assertFalse 'make ds without ASC_DS_EXPR fails' "[[ $rc -eq 0 ]]"
}

##
# §2 — colliding Make goals must not execute expression as shell (−k, both orders).
#
test_make_ds_collision_goals_no_shell() {
  local marker rc=0 err=''

  marker="$DSL_TEST_TMP/collide_marker"
  rm -f "$marker"
  rc=0
  err="$(make -k ds "true;touch $marker" debug 2>&1)" || rc=$?
  assertTrue 'order ds+expr+debug: marker absent' "[[ ! -f '$marker' ]]"
  assertTrue 'order ds+expr+debug: makefile refuses stray' \
    "[[ \"$err\" == *'must not be a Make goal'* || \"$err\" == *'refusing'* ]]"

  rm -f "$marker"
  rc=0
  err="$(make -k debug ds "true;touch $marker" 2>&1)" || rc=$?
  assertTrue 'order debug+ds+expr: marker absent' "[[ ! -f '$marker' ]]"
  assertTrue 'order debug+ds+expr: makefile refuses stray' \
    "[[ \"$err\" == *'must not be a Make goal'* || \"$err\" == *'refusing'* ]]"

  # Allowed combo: ds + debug with expression only in ASC_DS_EXPR.
  rm -f "$marker"
  rc=0
  ASC_DS_EXPR="true;touch $marker" make -k ds debug 2>/dev/null || rc=$?
  assertTrue 'ds+debug with ASC_DS_EXPR: shell marker absent' "[[ ! -f '$marker' ]]"
}

##
# §2 — literal ∓ / = / \$ not mutated by Make DSL carrier.
#
test_make_ds_no_legacy_unescape() {
  local argv_file lines='' rc=0

  argv_file="$DSL_TEST_TMP/lit_direct"
  rm -f "$argv_file"
  ASC_DSL_PROBE_ARGV="$argv_file" \
    f_asc_dsl "test-dsl-probe('a∓b','a=b','a\$b')" 2>/dev/null || rc=$?
  assertEquals 'direct literals exit 0' 0 "$rc"
  lines="$(tr '\0' '\n' < "$argv_file")"
  assertEquals 'direct keeps ∓' 'a∓b' "$(printf '%s\n' "$lines" | sed -n '1p')"
  assertEquals 'direct keeps =' 'a=b' "$(printf '%s\n' "$lines" | sed -n '2p')"
  assertEquals 'direct keeps $' 'a$b' "$(printf '%s\n' "$lines" | sed -n '3p')"

  argv_file="$DSL_TEST_TMP/lit_make"
  rm -f "$argv_file"
  rc=0
  ASC_DSL_PROBE_ARGV="$argv_file" \
    ASC_DS_EXPR="test-dsl-probe('a∓b','a=b','a\$b')" make ds 2>/dev/null || rc=$?
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

  # Collision with reserved hardcoded ds: discovered name must not become a recipe.
  # f_make_generate already filters via f_make_is_hardcoded_name; prove filter +
  # that a hand-written colliding recipe would override until regenerate.
  fixture="$DSL_TEST_TMP/gen_collide"
  mkdir -p "$fixture"
  cat > "$fixture/Makefile" <<EOF
include $PWD/asc/make/default.mk
include $fixture/stale_ds.mk
EOF
  cat > "$fixture/stale_ds.mk" <<'EOF'
.PHONY: ds
ds:
	@ asc/make/call_wrap.make.sh asc/instance/ds.sh $(MAKECMDGOALS)
EOF

  out="$(make -C "$fixture" -n ds 2>&1)"
  assertTrue 'collision fixture warns overriding recipe' \
    "[[ \"$out\" == *'overriding recipe'* || \"$out\" == *'ignoring old recipe'* ]]"

  # After filtering generate into stale_ds replacement path used as pivots include:
  gen_mk="$fixture/stale_ds.mk"
  ASC_MAKE_GENERATE_PIVOTS_MK="$gen_mk" \
    ASC_MAKE_GENERATE_PIVOTS_SH="$fixture/pivots.sh" \
    ASC_MAKE_GENERATE_TEST_CASES="$fixture/test-cases.sh" \
    f_make_generate >/dev/null

  assertEquals 'collision resolved: generated include has no ds recipe' \
    0 "$(grep -c '^\.PHONY: ds$' "$gen_mk" || true)"
  out="$(make -C "$fixture" -n ASC_DS_EXPR='slug(x)' ds 2>&1)"
  assertFalse 'after regenerate: no overriding warning' \
    "[[ \"$out\" == *'overriding recipe'* ]]"
}

. asc/vendor/shunit2/shunit2
