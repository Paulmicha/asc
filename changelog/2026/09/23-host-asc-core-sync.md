# Host core sync — report, then forward mirror

| Field | Value |
|-------|--------|
| **Date** | 2026-09-23 |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | Finish `asc/host/asc_core_sync.sh` (commit `4cf77f9`). Pivot `host-asc-core-sync`. |
| **Not this plan** | Writing instance files into the mother. Commits and pushes. Replacing `make core-upgrade`. Filling `asc/host/instance/discover.sh` (stub only; the 2026-09-22 path `asc/instance/discover.sh` is withdrawn). Copying `.cursor/rules`, `scripts/asc/extend/`, env, or gates. A README edit. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), except `$HOME`, `$ASC_MOTHER_DOCROOT`, and other shell names written inside code blocks.

Go-ahead is the `23-host-asc-core-sync` row in [`gates.core.yml`](../../../gates.core.yml). `go` stays `no`. Approving it authorizes the report and the forward `apply` mirror in the tasks below. It does not authorize a write into the mother.

Mother `main` was already up to date with `origin/main` when this note was written.

---

# Host core sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `host-asc-core-sync` prints how each instance’s managed directories differ from the local mother, and the word `apply` replaces those directories on the instance with the mother’s copies.

**Architecture:** One entry point, `asc/host/asc_core_sync.sh`. No new include. The invoking process bootstraps only its own docroot. Other trees are filesystem paths. The mother is `$ASC_MOTHER_DOCROOT` or else `$HOME/Documents/asc`. With no instance path, the script runs `$ASC_MOTHER_DOCROOT/asc/host/instance/discover.sh` and reads one docroot per line. The file is a stub (bootstrap and `# TODO`). A stub that prints nothing is not the catalog. A missing executable is a hard error, not an inlined `find`.

**Tech Stack:** Bash 4+, GNU `diff`, `realpath`, `cp -a`, shunit2 via `asc/test/core/host_asc_core_sync.test.sh`.

## Global Constraints

- Implement only after the gates row has `approved: "yes"` and `go: "yes"`. Discuss stays `go: "no"` until then.
- Managed directories are exactly `asc` and `scripts/asc/contrib/asc` (the pair `asc/core/upgrade.sh` deletes and replaces).
- Default mode prints a report and exits 0 when the report was produced, including when files differ.
- `apply` is a positional word (so `make` does not treat it as a make option). It mirrors those two directories from the mother work tree onto the instance. It deletes instance files inside those two directories.
- The script never writes into the mother, never runs `git`, and never sources another tree’s `asc/bootstrap.sh`.
- A target equal to the mother, or a path under the mother, is an error in both modes.
- Paths that contain a space are an error.
- No new `*.inc.sh`, `*.opt-inc.sh`, loader, hook implementation, or `env.yml` global. `ASC_MOTHER_DOCROOT` is a process environment override, same kind of knob as `ASC_BRANCH` on `core-upgrade`.
- Tests call the script. They do not use the real `$HOME/Documents/asc` tree. Run them from the mother docroot.
- Commits go through `$HOME/scripts/asc/extend/asc/git.sh` from `$HOME`. Leave `README.md` unchanged.

## What the stub is

`asc/host/asc_core_sync.sh` is sourced bootstrap plus a `# TODO`. The header says:

- default: backport improvements into the mother, then apply improvements to every instance on this host
- optional first argument: one instance docroot
- examples: `make host-asc-core-sync` and `make host-asc-core-sync path/to/foobar`

The filename already maps to the pivot `host-asc-core-sync` (`f_make_task_name` turns `_` into `-`). The make wrapper in `asc/make/call_wrap.make.sh` forwards extra words, so the path does not need a `--`. After a change to the file, `make reinit` refreshes `data/asc/pivots.mk` on a warm instance. Tests call the script path, so they do not need reinit.

## Completion

Report by default. `apply` mirrors forward. The stub’s backport-then-broadcast stays a human step outside this script: the report lists instance-only lines; a person copies a generic fix into the mother after that instance’s mother-guard search. The denylist stays in the instance. This script does not embed it and does not copy those bytes.

Stdout, one block per instance, then one summary. Relative labels:

```text
# /absolute/instance
Differ: asc/changed.txt
Only in mother: asc/onlym.txt
Only in instance: asc/sub/local.txt
Only in mother: scripts/asc/contrib/asc
host-asc-core-sync: 1 instance(s), 4 differing path(s)
```

A missing managed directory is one `Only in …` line. `diff -rq` runs only when both sides exist. Its lines are rewritten to the labels above. A whole directory that exists on only one side is `Only in mother: asc/extra` (GNU `diff -rq` names the directory, not each file inside it). A file inside a shared subdirectory is `Only in instance: asc/sub/local.txt`.

Summary with zero instances (discover printed nothing, or every discovered path was the mother and was skipped):

```text
host-asc-core-sync: 0 instance(s), 0 differing path(s)
```

Exit codes:

| Code | When |
|------|------|
| 0 | Report finished. `apply` finished and the following report has 0 differing paths. |
| 1 | Usage, missing mother, missing `asc/bootstrap.sh`, path under the mother, spaces in a path, discover missing or non-zero. |
| 2 | `diff` failed, a copy failed, or `apply` left a differing path. |

`apply` checks the mother has a directory `asc/` before it deletes anything. For each managed relative path: if the mother lacks it, remove it on the instance when present; if the mother has it, `mkdir -p` the parent, `rm -rf` the instance path, `cp -a` from the mother. Then print the same report. Anything outside the two directories stays (`scripts/asc/extend/`, `.env`, `data/`).

Discovered paths that resolve to the mother are skipped. An explicit argument that resolves to the mother is exit 1.

## File structure

| File | Responsibility |
|------|----------------|
| `asc/host/asc_core_sync.sh` | Parse args, resolve mother and targets, report, optional mirror. |
| `asc/test/core/host_asc_core_sync.test.sh` | Temp docroots only. |
| `gates.core.yml` | This note’s approval row. Already added with `go: "no"`. |

No `host.opt-inc.sh`. Logic stays in the entry point (one caller).

## Gaps

1. **Backport is a review, not a writer.** The stub’s step 1 would copy an instance file into the public mother and step 2 would then copy that file to every other instance. Client names, ticket ids, hostnames, domains, and docroots live in instance trees. The mother-guard search for those strings lives in the instance rule, not in this repo. This script never becomes that writer.
2. **“Improvement” is not a property of `diff`.** The report is the check the header asked for. Two instances can each differ from the mother on the same path; the report does not diff them against each other, and `apply` would replace both with the mother bytes.
3. **`apply` uses the mother work tree,** including uncommitted files under the two directories. `make core-upgrade` (`asc/core/upgrade.sh`) is a different tool: it clones `https://github.com/Paulmicha/asc.git` at `ASC_BRANCH` (default `main`) into the **current** docroot only, prompts, and runs `hook -s core -a post_upgrade`. This script does not call it, does not prompt, and does not run `post_upgrade` (that would bootstrap the other tree).
4. **No-arg host-wide sync waits on discover.** [20-host-scan-project-instances.md](./20-host-scan-project-instances.md) is `go: yes` for a catalog only. Its row says the catalog does not copy or sync. `asc/host/instance/discover.sh` is a stub. This script calls that path and exits 1 until the body prints docroots. It does not grow a second `find`.
5. **README workflow proposal is a git contract,** still unaccepted ([22-gitflow.md](./22-gitflow.md), `go: no`). “A change every instance shares moves up into the mother” there means commits, not this mirror. This script does not commit or push. README also still has the non-goal of a self-organizing platform; this pivot lists paths and, only with `apply`, copies two directories.
6. **`asc/vendor` is inside `asc/` and is mirrored** with the rest of that directory, same as `core-upgrade`. The mother-guard search skips `asc/vendor/**` when scanning a mother diff; that skip is not a copy filter.
7. **Rules stay compare-only.** `make device-cursor-rules-sync` prints instance rules next to the mother and does not copy. This plan does not fold that copy in.
8. **No three-way merge, no rename detection, no `HEAD`-only apply.** A later row can add one of those. This note does not.
9. **Spaces in paths exit 1.** `diff -rq` lines are split on the first ` and ` and on `: `.
10. **The invoking docroot is irrelevant** except as the process that bootstraps and the cwd for a relative instance path. Identity of the mother is the path above, not “whichever tree contains this script”.

## Tasks

### Task 1: Report one instance

**Files:**
- Create: `asc/test/core/host_asc_core_sync.test.sh`
- Modify: `asc/host/asc_core_sync.sh`

**Interfaces:**
- Consumes: nothing from earlier tasks
- Produces: executable `asc/host/asc_core_sync.sh`. `f_host_asc_core_sync` reads `"$@"` and `ASC_MOTHER_DOCROOT`. Stdout labels `Differ:`, `Only in mother:`, `Only in instance:`, and a last line `host-asc-core-sync: N instance(s), M differing path(s)`. Exit 0 on a finished report, 1 on usage and path errors, 2 when `diff` itself fails.

- [ ] **Step 1: Write the failing test**

Create `asc/test/core/host_asc_core_sync.test.sh` with mode `0755`:

```bash
#!/usr/bin/env bash

##
# host-asc-core-sync: report managed dirs against a fixture mother.
#
# @requires asc/vendor/shunit2
#
# @example
#   asc/test/core/host_asc_core_sync.test.sh
#

. asc/bootstrap.sh

f_host_asc_core_sync_test_docroot() {
  local root="$1"
  mkdir -p "$root/asc/sub" "$root/scripts/asc/contrib/asc" "$root/scripts/asc/extend"
  printf '%s\n' 'echo SHOULD_NOT_RUN' > "$root/asc/bootstrap.sh"
  printf '%s\n' 'same' > "$root/asc/same.txt"
  printf '%s\n' 'same' > "$root/asc/sub/keep.txt"
  printf '%s\n' 'contrib' > "$root/scripts/asc/contrib/asc/marker.txt"
  printf '%s\n' 'extend-keep' > "$root/scripts/asc/extend/keep.txt"
}

f_host_asc_core_sync_test_run() {
  local mother="$1"
  shift
  set +e
  host_asc_core_sync_test_out="$(
    ASC_MOTHER_DOCROOT="$mother" asc/host/asc_core_sync.sh "$@" \
      2>"$host_asc_core_sync_test_err"
  )"
  host_asc_core_sync_test_status=$?
  set -e
}

test_report_names_drift_and_does_not_copy() {
  local dir mother instance
  dir="$(mktemp -d)"
  mother="$dir/mother"
  instance="$dir/instance"
  host_asc_core_sync_test_err="$dir/err"
  f_host_asc_core_sync_test_docroot "$mother"
  f_host_asc_core_sync_test_docroot "$instance"
  printf '%s\n' 'from-mother' > "$mother/asc/changed.txt"
  printf '%s\n' 'from-instance' > "$instance/asc/changed.txt"
  printf '%s\n' 'only-mother' > "$mother/asc/onlym.txt"
  printf '%s\n' 'only-instance' > "$instance/asc/sub/local.txt"
  rm -rf "$instance/scripts/asc/contrib/asc"

  f_host_asc_core_sync_test_run "$mother" "$instance"

  assertEquals 'report exits 0 when files differ.' 0 "$host_asc_core_sync_test_status"
  grep -q 'Differ: asc/changed.txt' <<< "$host_asc_core_sync_test_out"
  assertEquals 'changed file is labeled Differ.' 0 "$?"
  grep -q 'Only in mother: asc/onlym.txt' <<< "$host_asc_core_sync_test_out"
  assertEquals 'mother-only file is labeled.' 0 "$?"
  grep -q 'Only in instance: asc/sub/local.txt' <<< "$host_asc_core_sync_test_out"
  assertEquals 'instance-only nested file is labeled.' 0 "$?"
  grep -q 'Only in mother: scripts/asc/contrib/asc' <<< "$host_asc_core_sync_test_out"
  assertEquals 'missing managed dir is one line.' 0 "$?"
  grep -q 'host-asc-core-sync: 1 instance(s), 4 differing path(s)' <<< "$host_asc_core_sync_test_out"
  assertEquals 'summary counts four differences.' 0 "$?"
  grep -q 'SHOULD_NOT_RUN' <<< "$host_asc_core_sync_test_out$(cat "$host_asc_core_sync_test_err")"
  assertEquals 'fixture bootstrap was not sourced.' 1 "$?"
  assertTrue 'instance file was not replaced.' "[ \"\$(cat '$instance/asc/changed.txt')\" = 'from-instance' ]"
  assertTrue 'extend file stayed.' "[ -f '$instance/scripts/asc/extend/keep.txt' ]"

  rm -rf "$dir"
}

test_unknown_option_exits_1() {
  local dir mother instance
  dir="$(mktemp -d)"
  mother="$dir/mother"
  instance="$dir/instance"
  host_asc_core_sync_test_err="$dir/err"
  f_host_asc_core_sync_test_docroot "$mother"
  f_host_asc_core_sync_test_docroot "$instance"

  f_host_asc_core_sync_test_run "$mother" --not-a-mode "$instance"

  assertEquals 'unknown option exits 1.' 1 "$host_asc_core_sync_test_status"
  grep -q 'unknown option' "$host_asc_core_sync_test_err"
  assertEquals 'stderr names the unknown option.' 0 "$?"
  rm -rf "$dir"
}

test_missing_bootstrap_exits_1() {
  local dir mother instance
  dir="$(mktemp -d)"
  mother="$dir/mother"
  instance="$dir/instance"
  host_asc_core_sync_test_err="$dir/err"
  f_host_asc_core_sync_test_docroot "$mother"
  mkdir -p "$instance"

  f_host_asc_core_sync_test_run "$mother" "$instance"

  assertEquals 'path without bootstrap exits 1.' 1 "$host_asc_core_sync_test_status"
  grep -q 'asc/bootstrap.sh' "$host_asc_core_sync_test_err"
  assertEquals 'stderr mentions bootstrap.sh.' 0 "$?"
  rm -rf "$dir"
}

test_explicit_mother_path_exits_1() {
  local dir mother
  dir="$(mktemp -d)"
  mother="$dir/mother"
  host_asc_core_sync_test_err="$dir/err"
  f_host_asc_core_sync_test_docroot "$mother"

  f_host_asc_core_sync_test_run "$mother" "$mother"

  assertEquals 'syncing the mother onto itself exits 1.' 1 "$host_asc_core_sync_test_status"
  grep -q 'mother' "$host_asc_core_sync_test_err"
  assertEquals 'stderr mentions the mother.' 0 "$?"
  rm -rf "$dir"
}

test_default_mother_is_home_documents_asc() {
  local dir home mother instance
  dir="$(mktemp -d)"
  home="$dir/home"
  mother="$home/Documents/asc"
  instance="$dir/instance"
  host_asc_core_sync_test_err="$dir/err"
  f_host_asc_core_sync_test_docroot "$mother"
  f_host_asc_core_sync_test_docroot "$instance"
  printf '%s\n' 'only-mother' > "$mother/asc/onlym.txt"

  set +e
  host_asc_core_sync_test_out="$(
    env -u ASC_MOTHER_DOCROOT HOME="$home" asc/host/asc_core_sync.sh "$instance" \
      2>"$host_asc_core_sync_test_err"
  )"
  host_asc_core_sync_test_status=$?
  set -e

  assertEquals 'default mother path exits 0.' 0 "$host_asc_core_sync_test_status"
  grep -q 'Only in mother: asc/onlym.txt' <<< "$host_asc_core_sync_test_out"
  assertEquals 'default mother is $HOME/Documents/asc.' 0 "$?"
  rm -rf "$dir"
}

. asc/vendor/shunit2/shunit2
```

- [ ] **Step 2: Run the test to verify it fails**

Run from the mother docroot:

```bash
asc/test/core/host_asc_core_sync.test.sh
```

Expected: FAIL. The current script prints no `Differ:` line (it bootstraps and stops at the TODO).

- [ ] **Step 3: Replace the script with the report implementation**

Write `asc/host/asc_core_sync.sh` (keep it executable):

```bash
#!/usr/bin/env bash

##
# Compare ASC project instances on this host to the local mother tree.
#
# Managed directories, the same pair as asc/core/upgrade.sh:
#   asc
#   scripts/asc/contrib/asc
#
# Default is a report. The report does not copy, delete, commit, or push.
# Instance files are not written into the mother.
#
# @param 1 [optional] String : one instance docroot. A relative path is
#   resolved from the current working directory. When omitted, paths are
#   read from the mother's asc/host/instance/discover.sh (Task 3).
#
# Mother docroot: $ASC_MOTHER_DOCROOT, or $HOME/Documents/asc when unset.
#
# @example
#   make host-asc-core-sync path/to/one
#   asc/host/asc_core_sync.sh path/to/one
#

f_host_asc_core_sync_fail() {
  local p_msg="$1"
  local p_code="${2:-1}"
  echo >&2
  echo "Error in ${BASH_SOURCE[0]} line ${BASH_LINENO[0]}: ${p_msg}" >&2
  echo "-> Aborting (${p_code})." >&2
  echo >&2
  exit "$p_code"
}

f_host_asc_core_sync_managed_dirs() {
  printf '%s\n' 'asc' 'scripts/asc/contrib/asc'
}

f_host_asc_core_sync_normalize_line() {
  local p_line="$1"
  local p_left="$2"
  local p_right="$3"
  local p_rel="$4"
  local tail dir name rest left_file rel_file

  case "$p_line" in
    "Only in ${p_left}: "*)
      name="${p_line#Only in ${p_left}: }"
      echo "Only in mother: ${p_rel}/${name}"
      ;;
    "Only in ${p_left}/"*)
      tail="${p_line#Only in ${p_left}/}"
      dir="${tail%%: *}"
      name="${tail#*: }"
      echo "Only in mother: ${p_rel}/${dir}/${name}"
      ;;
    "Only in ${p_right}: "*)
      name="${p_line#Only in ${p_right}: }"
      echo "Only in instance: ${p_rel}/${name}"
      ;;
    "Only in ${p_right}/"*)
      tail="${p_line#Only in ${p_right}/}"
      dir="${tail%%: *}"
      name="${tail#*: }"
      echo "Only in instance: ${p_rel}/${dir}/${name}"
      ;;
    "Files "*)
      rest="${p_line#Files }"
      rest="${rest% differ}"
      left_file="${rest%% and *}"
      rel_file="${left_file#"${p_left}/"}"
      echo "Differ: ${p_rel}/${rel_file}"
      ;;
    *)
      f_host_asc_core_sync_fail "unrecognized diff line: ${p_line}" 2
      ;;
  esac
}

f_host_asc_core_sync_reject_target() {
  local p_mother_real="$1"
  local p_target_real="$2"
  case "$p_target_real" in
    "$p_mother_real"|"$p_mother_real"/*)
      f_host_asc_core_sync_fail "refusing to sync the mother tree: ${p_target_real}"
      ;;
  esac
  if [[ ! -f "$p_target_real/asc/bootstrap.sh" ]]; then
    f_host_asc_core_sync_fail "not an ASC project docroot (missing asc/bootstrap.sh): ${p_target_real}"
  fi
}

f_host_asc_core_sync_report_one() {
  local p_mother="$1"
  local p_instance="$2"
  local rel left right diff_out diff_status line
  host_asc_core_sync_diff_n=0

  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    left="$p_mother/$rel"
    right="$p_instance/$rel"
    if [[ ! -e "$left" && ! -e "$right" ]]; then
      continue
    fi
    if [[ -e "$left" && ! -e "$right" ]]; then
      echo "Only in mother: ${rel}"
      host_asc_core_sync_diff_n=$((host_asc_core_sync_diff_n + 1))
      continue
    fi
    if [[ ! -e "$left" && -e "$right" ]]; then
      echo "Only in instance: ${rel}"
      host_asc_core_sync_diff_n=$((host_asc_core_sync_diff_n + 1))
      continue
    fi
    diff_status=0
    diff_out="$(diff -rq "$left" "$right")" || diff_status=$?
    if [[ "$diff_status" -gt 1 ]]; then
      f_host_asc_core_sync_fail "diff failed for ${rel} (${diff_status})." 2
    fi
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      f_host_asc_core_sync_normalize_line "$line" "$left" "$right" "$rel"
      host_asc_core_sync_diff_n=$((host_asc_core_sync_diff_n + 1))
    done <<< "$diff_out"
  done < <(f_host_asc_core_sync_managed_dirs)
}

f_host_asc_core_sync() {
  local p_only=''
  local arg mother mother_real target_real
  local n_inst=0
  local n_diff=0

  while [[ $# -gt 0 ]]; do
    arg="$1"
    case "$arg" in
      --)
        shift
        ;;
      -*)
        f_host_asc_core_sync_fail "unknown option: ${arg}"
        ;;
      *)
        if [[ -n "$p_only" ]]; then
          f_host_asc_core_sync_fail "too many paths: ${arg}"
        fi
        p_only="$arg"
        shift
        ;;
    esac
  done

  if [[ -z "$p_only" ]]; then
    f_host_asc_core_sync_fail "instance path is required until asc/host/instance/discover.sh exists."
  fi
  case "$p_only" in
    *' '*)
      f_host_asc_core_sync_fail "paths with spaces are unsupported: ${p_only}"
      ;;
  esac

  mother="${ASC_MOTHER_DOCROOT:-$HOME/Documents/asc}"
  case "$mother" in
    *' '*)
      f_host_asc_core_sync_fail "paths with spaces are unsupported: ${mother}"
      ;;
  esac
  if [[ ! -d "$mother" ]]; then
    f_host_asc_core_sync_fail "mother docroot is not a directory: ${mother}"
  fi
  mother_real="$(realpath "$mother")" || f_host_asc_core_sync_fail "cannot resolve mother docroot: ${mother}"
  if [[ ! -f "$mother_real/asc/bootstrap.sh" ]]; then
    f_host_asc_core_sync_fail "mother docroot has no asc/bootstrap.sh: ${mother_real}"
  fi
  if [[ ! -d "$p_only" ]]; then
    f_host_asc_core_sync_fail "instance path is not a directory: ${p_only}"
  fi
  target_real="$(realpath "$p_only")" || f_host_asc_core_sync_fail "cannot resolve instance path: ${p_only}"
  f_host_asc_core_sync_reject_target "$mother_real" "$target_real"

  echo "# ${target_real}"
  f_host_asc_core_sync_report_one "$mother_real" "$target_real"
  n_inst=1
  n_diff="$host_asc_core_sync_diff_n"
  echo "host-asc-core-sync: ${n_inst} instance(s), ${n_diff} differing path(s)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  . asc/bootstrap.sh
  f_host_asc_core_sync "$@"
fi
```

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
asc/test/core/host_asc_core_sync.test.sh
```

Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

From `$HOME`:

```bash
scripts/asc/extend/asc/git.sh add asc/host/asc_core_sync.sh asc/test/core/host_asc_core_sync.test.sh
scripts/asc/extend/asc/git.sh commit -m "$(cat <<'EOF'
Report asc core drift against the local mother.

EOF
)"
```

### Task 2: Forward mirror (`apply`)

**Files:**
- Modify: `asc/test/core/host_asc_core_sync.test.sh` (append tests before the shunit2 source line)
- Modify: `asc/host/asc_core_sync.sh`

**Interfaces:**
- Consumes: Task 1 stdout labels and `f_host_asc_core_sync_report_one`
- Produces: positional word `apply` (alone or beside one path). After a successful mirror the summary is `host-asc-core-sync: 1 instance(s), 0 differing path(s)`. Exit 2 when the copy fails or the follow-up report is not clean.

- [ ] **Step 1: Add the failing tests**

Insert these functions before the `. asc/vendor/shunit2/shunit2` line:

```bash
test_apply_mirrors_managed_dirs_and_leaves_extend() {
  local dir mother instance
  dir="$(mktemp -d)"
  mother="$dir/mother"
  instance="$dir/instance"
  host_asc_core_sync_test_err="$dir/err"
  f_host_asc_core_sync_test_docroot "$mother"
  f_host_asc_core_sync_test_docroot "$instance"
  printf '%s\n' 'from-mother' > "$mother/asc/changed.txt"
  printf '%s\n' 'from-instance' > "$instance/asc/changed.txt"
  printf '%s\n' 'only-instance' > "$instance/asc/local-only.txt"
  printf '%s\n' 'secret' > "$instance/.env"

  f_host_asc_core_sync_test_run "$mother" apply "$instance"

  assertEquals 'apply exits 0.' 0 "$host_asc_core_sync_test_status"
  grep -q 'host-asc-core-sync: 1 instance(s), 0 differing path(s)' <<< "$host_asc_core_sync_test_out"
  assertEquals 'apply summary is clean.' 0 "$?"
  assertTrue 'changed file matches the mother.' "[ \"\$(cat '$instance/asc/changed.txt')\" = 'from-mother' ]"
  assertTrue 'instance-only managed file was removed.' "[ ! -e '$instance/asc/local-only.txt' ]"
  assertTrue 'extend file stayed.' "[ \"\$(cat '$instance/scripts/asc/extend/keep.txt')\" = 'extend-keep' ]"
  assertTrue '.env stayed.' "[ \"\$(cat '$instance/.env')\" = 'secret' ]"
  rm -rf "$dir"
}

test_apply_removes_contrib_absent_from_mother() {
  local dir mother instance
  dir="$(mktemp -d)"
  mother="$dir/mother"
  instance="$dir/instance"
  host_asc_core_sync_test_err="$dir/err"
  f_host_asc_core_sync_test_docroot "$mother"
  f_host_asc_core_sync_test_docroot "$instance"
  rm -rf "$mother/scripts/asc/contrib/asc"

  f_host_asc_core_sync_test_run "$mother" "$instance" apply

  assertEquals 'apply with missing contrib exits 0.' 0 "$host_asc_core_sync_test_status"
  assertTrue 'instance contrib dir was removed.' "[ ! -e '$instance/scripts/asc/contrib/asc' ]"
  assertTrue 'mother asc dir was not deleted.' "[ -f '$mother/asc/bootstrap.sh' ]"
  rm -rf "$dir"
}

test_apply_refuses_path_under_mother() {
  local dir mother nested
  dir="$(mktemp -d)"
  mother="$dir/mother"
  nested="$mother/nested-instance"
  host_asc_core_sync_test_err="$dir/err"
  f_host_asc_core_sync_test_docroot "$mother"
  f_host_asc_core_sync_test_docroot "$nested"
  printf '%s\n' 'keep' > "$mother/asc/changed.txt"

  f_host_asc_core_sync_test_run "$mother" apply "$nested"

  assertEquals 'path under the mother exits 1.' 1 "$host_asc_core_sync_test_status"
  assertTrue 'mother file stayed.' "[ \"\$(cat '$mother/asc/changed.txt')\" = 'keep' ]"
  rm -rf "$dir"
}
```

- [ ] **Step 2: Run the test to verify the new cases fail**

Run:

```bash
asc/test/core/host_asc_core_sync.test.sh
```

Expected: FAIL in `test_apply_mirrors_managed_dirs_and_leaves_extend`. The word `apply` is still parsed as a second path (`too many paths`) or as the only path (`not a directory`).

- [ ] **Step 3: Accept the word `apply` and mirror**

In `f_host_asc_core_sync`, add `local b_apply=0` next to `p_only`. In the argument loop, before the `*)` path arm, handle the word `apply`:

```bash
      apply)
        b_apply=1
        shift
        ;;
```

Replace the empty-path error and the single-target body with the version below. Keep `f_host_asc_core_sync_report_one` and the normalizer. Add `f_host_asc_core_sync_apply_one` immediately above `f_host_asc_core_sync`. Update the header examples to include `make host-asc-core-sync apply path/to/one` and `asc/host/asc_core_sync.sh path/to/one apply`.

```bash
f_host_asc_core_sync_apply_one() {
  local p_mother="$1"
  local p_instance="$2"
  local rel parent

  if [[ ! -d "$p_mother/asc" ]]; then
    f_host_asc_core_sync_fail "mother has no asc/ directory: ${p_mother}"
  fi

  while IFS= read -r rel; do
    [[ -z "$rel" ]] && continue
    if [[ ! -e "$p_mother/$rel" ]]; then
      if [[ -e "$p_instance/$rel" ]]; then
        command rm -rf "$p_instance/$rel" || f_host_asc_core_sync_fail "failed to remove ${p_instance}/${rel}" 2
      fi
      continue
    fi
    parent="$(dirname "$p_instance/$rel")"
    mkdir -p "$parent" || f_host_asc_core_sync_fail "failed to create ${parent}" 2
    command rm -rf "$p_instance/$rel" || f_host_asc_core_sync_fail "failed to remove ${p_instance}/${rel}" 2
    command cp -a "$p_mother/$rel" "$p_instance/$rel" || f_host_asc_core_sync_fail "failed to copy ${rel} onto ${p_instance}" 2
  done < <(f_host_asc_core_sync_managed_dirs)
}
```

The main function’s target section becomes:

```bash
  if [[ -z "$p_only" ]]; then
    f_host_asc_core_sync_fail "instance path is required until asc/host/instance/discover.sh exists."
  fi
  case "$p_only" in
    *' '*)
      f_host_asc_core_sync_fail "paths with spaces are unsupported: ${p_only}"
      ;;
  esac

  mother="${ASC_MOTHER_DOCROOT:-$HOME/Documents/asc}"
  case "$mother" in
    *' '*)
      f_host_asc_core_sync_fail "paths with spaces are unsupported: ${mother}"
      ;;
  esac
  if [[ ! -d "$mother" ]]; then
    f_host_asc_core_sync_fail "mother docroot is not a directory: ${mother}"
  fi
  mother_real="$(realpath "$mother")" || f_host_asc_core_sync_fail "cannot resolve mother docroot: ${mother}"
  if [[ ! -f "$mother_real/asc/bootstrap.sh" ]]; then
    f_host_asc_core_sync_fail "mother docroot has no asc/bootstrap.sh: ${mother_real}"
  fi
  if [[ "$b_apply" -eq 1 && ! -d "$mother_real/asc" ]]; then
    f_host_asc_core_sync_fail "mother has no asc/ directory: ${mother_real}"
  fi
  if [[ ! -d "$p_only" ]]; then
    f_host_asc_core_sync_fail "instance path is not a directory: ${p_only}"
  fi
  target_real="$(realpath "$p_only")" || f_host_asc_core_sync_fail "cannot resolve instance path: ${p_only}"
  f_host_asc_core_sync_reject_target "$mother_real" "$target_real"

  if [[ "$b_apply" -eq 1 ]]; then
    f_host_asc_core_sync_apply_one "$mother_real" "$target_real"
  fi

  echo "# ${target_real}"
  f_host_asc_core_sync_report_one "$mother_real" "$target_real"
  n_inst=1
  n_diff="$host_asc_core_sync_diff_n"
  if [[ "$b_apply" -eq 1 && "$n_diff" -ne 0 ]]; then
    f_host_asc_core_sync_fail "apply left ${n_diff} differing path(s) on ${target_real}." 2
  fi
  echo "host-asc-core-sync: ${n_inst} instance(s), ${n_diff} differing path(s)"
```

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
asc/test/core/host_asc_core_sync.test.sh
```

Expected: PASS (8 tests).

- [ ] **Step 5: Commit**

From `$HOME`:

```bash
scripts/asc/extend/asc/git.sh add asc/host/asc_core_sync.sh asc/test/core/host_asc_core_sync.test.sh
scripts/asc/extend/asc/git.sh commit -m "$(cat <<'EOF'
Mirror mother core directories onto one instance when apply is set.

EOF
)"
```

### Task 3: No-arg list from discover

**Files:**
- Modify: `asc/test/core/host_asc_core_sync.test.sh`
- Modify: `asc/host/asc_core_sync.sh`

**Interfaces:**
- Consumes: Task 2 `apply` and the report labels
- Produces: with no path, execute `"$mother_real/asc/host/instance/discover.sh"` with no arguments. Non-zero status from that script is exit 1. Blank lines ignored. A printed path that resolves to the mother is skipped. Any other printed path uses `f_host_asc_core_sync_reject_target` and then the same report or `apply` as an explicit path. A missing or non-executable discover script is exit 1 and stderr contains `asc/host/instance/discover.sh`.

- [ ] **Step 1: Add the failing tests**

Insert before the shunit2 source line:

```bash
test_missing_discover_exits_1() {
  local dir mother
  dir="$(mktemp -d)"
  mother="$dir/mother"
  host_asc_core_sync_test_err="$dir/err"
  f_host_asc_core_sync_test_docroot "$mother"

  f_host_asc_core_sync_test_run "$mother"

  assertEquals 'missing discover exits 1.' 1 "$host_asc_core_sync_test_status"
  grep -q 'asc/host/instance/discover.sh' "$host_asc_core_sync_test_err"
  assertEquals 'stderr names discover.sh.' 0 "$?"
  rm -rf "$dir"
}

test_discover_skips_mother_and_reports_two() {
  local dir mother a b
  dir="$(mktemp -d)"
  mother="$dir/mother"
  a="$dir/a"
  b="$dir/b"
  host_asc_core_sync_test_err="$dir/err"
  f_host_asc_core_sync_test_docroot "$mother"
  f_host_asc_core_sync_test_docroot "$a"
  f_host_asc_core_sync_test_docroot "$b"
  printf '%s\n' 'only-a' > "$a/asc/only-a.txt"
  mkdir -p "$mother/asc/instance"
  cat > "$mother/asc/host/instance/discover.sh" <<EOF
#!/usr/bin/env bash
printf '%s\n' '$mother' '$a' '' '$b'
EOF
  chmod 0755 "$mother/asc/host/instance/discover.sh"

  f_host_asc_core_sync_test_run "$mother"

  assertEquals 'discover report exits 0.' 0 "$host_asc_core_sync_test_status"
  grep -q 'Only in instance: asc/only-a.txt' <<< "$host_asc_core_sync_test_out"
  assertEquals 'instance a drift is reported.' 0 "$?"
  grep -q "host-asc-core-sync: 2 instance(s), 1 differing path(s)" <<< "$host_asc_core_sync_test_out"
  assertEquals 'mother path from discover is skipped.' 0 "$?"
  rm -rf "$dir"
}

test_apply_stops_before_the_second_instance_on_copy_failure() {
  local dir mother a b
  dir="$(mktemp -d)"
  mother="$dir/mother"
  a="$dir/a"
  b="$dir/b"
  host_asc_core_sync_test_err="$dir/err"
  f_host_asc_core_sync_test_docroot "$mother"
  f_host_asc_core_sync_test_docroot "$a"
  f_host_asc_core_sync_test_docroot "$b"
  printf '%s\n' 'from-mother' > "$mother/asc/changed.txt"
  chmod 0555 "$a"
  mkdir -p "$mother/asc/instance"
  cat > "$mother/asc/host/instance/discover.sh" <<EOF
#!/usr/bin/env bash
printf '%s\n' '$a' '$b'
EOF
  chmod 0755 "$mother/asc/host/instance/discover.sh"

  f_host_asc_core_sync_test_run "$mother" apply

  assertEquals 'copy failure exits 2.' 2 "$host_asc_core_sync_test_status"
  assertTrue 'second instance was not given the mother file.' "[ ! -e '$b/asc/changed.txt' ]"
  chmod 0755 "$a"
  rm -rf "$dir"
}
```

- [ ] **Step 2: Run the test to verify the new cases fail**

Run:

```bash
asc/test/core/host_asc_core_sync.test.sh
```

Expected: FAIL in `test_missing_discover_exits_1` or `test_discover_skips_mother_and_reports_two`. No-arg still exits 1 with the Task 1 sentence, or does not print `2 instance(s)`.

- [ ] **Step 3: Read discover when the path is omitted**

Add this function above `f_host_asc_core_sync`:

```bash
f_host_asc_core_sync_one_target() {
  local p_mother_real="$1"
  local p_path="$2"
  local resolved

  case "$p_path" in
    *' '*)
      f_host_asc_core_sync_fail "paths with spaces are unsupported: ${p_path}"
      ;;
  esac
  if [[ ! -d "$p_path" ]]; then
    f_host_asc_core_sync_fail "instance path is not a directory: ${p_path}"
  fi
  resolved="$(realpath "$p_path")" || f_host_asc_core_sync_fail "cannot resolve instance path: ${p_path}"
  f_host_asc_core_sync_reject_target "$p_mother_real" "$resolved"
  host_asc_core_sync_targets_arr+=("$resolved")
}

f_host_asc_core_sync_targets() {
  local p_mother_real="$1"
  local p_only="$2"
  local discover discover_out discover_status line resolved
  host_asc_core_sync_targets_arr=()

  if [[ -n "$p_only" ]]; then
    f_host_asc_core_sync_one_target "$p_mother_real" "$p_only"
    return 0
  fi

  discover="$p_mother_real/asc/host/instance/discover.sh"
  if [[ ! -x "$discover" ]]; then
    f_host_asc_core_sync_fail "no instance path given and ${discover} is not executable."
  fi
  discover_status=0
  discover_out="$("$discover")" || discover_status=$?
  if [[ "$discover_status" -ne 0 ]]; then
    f_host_asc_core_sync_fail "instance discover failed (${discover_status}): ${discover}"
  fi
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    case "$line" in
      *' '*)
        f_host_asc_core_sync_fail "paths with spaces are unsupported: ${line}"
        ;;
    esac
    if [[ ! -d "$line" ]]; then
      f_host_asc_core_sync_fail "instance path is not a directory: ${line}"
    fi
    resolved="$(realpath "$line")" || f_host_asc_core_sync_fail "cannot resolve instance path: ${line}"
    case "$resolved" in
      "$p_mother_real"|"$p_mother_real"/*)
        continue
        ;;
    esac
    f_host_asc_core_sync_reject_target "$p_mother_real" "$resolved"
    host_asc_core_sync_targets_arr+=("$resolved")
  done <<< "$discover_out"
}
```

Replace the single-target tail of `f_host_asc_core_sync` with the loop below. Delete the “instance path is required…” error, the `case` on `$p_only` for spaces, and the block that checks `[[ ! -d "$p_only" ]]`, resolves one `target_real`, rejects it, applies, and reports once. An empty `$p_only` must reach `f_host_asc_core_sync_targets`. Keep the mother resolution and the `apply` check that the mother has `asc/`. `f_host_asc_core_sync_one_target` resolves an explicit path and rejects the mother. The discover loop skips a printed mother path before it rejects other paths.

```bash
  f_host_asc_core_sync_targets "$mother_real" "$p_only"

  if [[ "${#host_asc_core_sync_targets_arr[@]}" -eq 0 ]]; then
    echo "host-asc-core-sync: 0 instance(s), 0 differing path(s)"
    return 0
  fi

  for target_real in "${host_asc_core_sync_targets_arr[@]}"; do
    if [[ "$b_apply" -eq 1 ]]; then
      f_host_asc_core_sync_apply_one "$mother_real" "$target_real"
    fi
    echo "# ${target_real}"
    f_host_asc_core_sync_report_one "$mother_real" "$target_real"
    n_inst=$((n_inst + 1))
    n_diff=$((n_diff + host_asc_core_sync_diff_n))
    if [[ "$b_apply" -eq 1 && "$host_asc_core_sync_diff_n" -ne 0 ]]; then
      f_host_asc_core_sync_fail "apply left ${host_asc_core_sync_diff_n} differing path(s) on ${target_real}." 2
    fi
  done

  echo "host-asc-core-sync: ${n_inst} instance(s), ${n_diff} differing path(s)"
```

Explicit paths still go through `f_host_asc_core_sync_targets`, which does not skip the mother for an explicit argument: it calls `f_host_asc_core_sync_reject_target`. Discover skips the mother before that reject. Update the header: omitting the path reads discover; `make host-asc-core-sync` and `make host-asc-core-sync apply` are the host-wide forms.

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
asc/test/core/host_asc_core_sync.test.sh
```

Expected: PASS (11 tests).

- [ ] **Step 5: Commit**

From `$HOME`:

```bash
scripts/asc/extend/asc/git.sh add asc/host/asc_core_sync.sh asc/test/core/host_asc_core_sync.test.sh
scripts/asc/extend/asc/git.sh commit -m "$(cat <<'EOF'
Read host instance paths for core sync from discover.

EOF
)"
```

## Open decisions

- [ ] Approve the gates row when this report-and-forward-mirror contract is the one to build.
- [ ] Keep instance-to-mother copies out of this script until a later row names a single-file, guard-checked writer.
- [ ] After `asc/host/instance/discover.sh` exists, re-run `asc/test/core/host_asc_core_sync.test.sh` against the fixture discover, then `make host-asc-core-sync` on a real host only as a report.
