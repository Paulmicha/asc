# `*.manual-inc.sh` — hardcoded includes that loaders never derive

| Field | Value |
|-------|--------|
| **Date** | 2026-09-21 |
| **Status** | **proposed.** No rename of the kernel/hub/`global`/`str` files until this is accepted. `fs.opt-inc.sh` is **already** split on disk (see Wave 0). |
| **Scope** | Every `*.inc.sh` / `*.opt-inc.sh` that is sourced by a hardcoded include and is **not** derived by an ASC loader. New double-ext: `*.manual-inc.sh`. Rewrite each of those files’ **file-level** docblock to the templates below (same slice as the `git mv`). |
| **Supersedes** | [20-two-include-kinds.md](./20-two-include-kinds.md) “two kinds only / no third suffix”. `private-inc` stays **rejected** (reads as “don’t call me”). |
| **Related** | [19-eager-vs-lazy-include-cases.md](./19-eager-vs-lazy-include-cases.md) (the two **loaders**). [21-utils-under-core.md](./21-utils-under-core.md). Kernel hub [21-kernel-utils-inc.md](./21-kernel-utils-inc.md). |
| **Not this plan** | A fourth loader / `ASC_MANUAL_INC` glob. Renaming files that **are** `$subject/$subject.inc.sh` or caller/hook `*.opt-inc.sh`. Filling `utils/test/*.sh`. Wave C shrinking `git.inc.sh` off `ASC_INC`. |

`$` in this file is the ASC docs placeholder, not a shell variable.

---

## Why a third spelling

The two **loaders** stay two ([19-eager-vs-lazy-include-cases.md](./19-eager-vs-lazy-include-cases.md)):

| Loader | Derives |
|--------|---------|
| **Eager** | `$subject/$subject.inc.sh` in an *active dir*; `$extension/$extension.inc.sh` in an *extension point*; plus `scripts/asc/*.inc.sh` if any exist |
| **Lazy** | caller `<dir>/<subject>.opt-inc.sh` + `<dir>/<action>.opt-inc.sh`; hook colocated `*.opt-inc.sh` |

A third **filename** is not a third loader. Loaders never look at `*.manual-inc.sh`. The only way in is an explicit source in a caller that already exists.

`*.inc.sh` on a file that is **never** a name match currently **lies**: it looks autoloaded. `*.opt-inc.sh` under `asc/core/utils/` **lies** the other way: loaders never derive it (`utils/` is not a caller or hook dir). `manual-inc` is the self-explainable token: a human sources this.

`private-inc` was rejected in [20-two-include-kinds.md](./20-two-include-kinds.md). Do not revive that spelling.

On disk today, the first two files already use the new suffix:

- `asc/core/utils/fs_compression.manual-inc.sh` — `f_fs_compress`, `f_fs_compress_in_place`, `f_fs_trim_compression_ext`, `f_fs_extract`, `f_fs_extract_in_place`
- `asc/core/utils/fs_sync.manual-inc.sh` — `f_fs_merge_dirs`

Callers still source `asc/core/utils/fs.opt-inc.sh` (file gone). Wave 0 retargets those source lines. That is not optional bookkeeping.

---

## How to read the inventory

**Autoload** = a loader can derive this path from a dir name, a caller, or a hook. Keep `*.inc.sh` / `*.opt-inc.sh`. An extra explicit source of the same file (tests, `reinit` yaml fallback, kernel source of `core.inc.sh`) is **not** a reason to rename.

**Manual** = no loader derives this path. Rename to `*.manual-inc.sh`, keep every existing source, rewrite the file-level docblock (see **File docblocks**).

`asc/core/core.inc.sh` is autoload: `$subject` is `core`, so it is already on `ASC_INC`. Bootstrap also sources it. Same law as `yml.inc.sh`. Do **not** rename it. Do **not** drop it from `ASC_INC`. The filename keeps the eager spelling so discovery still works; the extra source stays in `asc/bootstrap.sh`.

Builder scaffolds `{subject}.inc.sh` / `{subject}.opt-inc.sh` under `asc/extensions/builder/template/` are **not sourced**. They emit autoload names. Leave them.

---

## Manual (rename to `*.manual-inc.sh`)

Hardcoded sources only. This is the whole work list.

### Kernel block (`asc/bootstrap.sh`)

Three of the four kernel source lines are manual-only. `core.inc.sh` stays (autoload plus an extra source).

| Today | After | Sourced by |
|-------|--------|------------|
| `asc/core/utils.inc.sh` | `asc/core/utils.manual-inc.sh` | `asc/bootstrap.sh` |
| `asc/core/core.inc.sh` | **unchanged** | `asc/bootstrap.sh` **and** `ASC_INC` (name match). Not a rename. |
| `asc/core/hook.inc.sh` | `asc/core/hook.manual-inc.sh` | `asc/bootstrap.sh` |
| `asc/core/autoload.inc.sh` | `asc/core/autoload.manual-inc.sh` | `asc/bootstrap.sh` |

### Hub children (`asc/core/utils.inc.sh`, later `utils.manual-inc.sh`)

| Today | After |
|-------|--------|
| `asc/core/utils/arr.inc.sh` | `asc/core/utils/arr.manual-inc.sh` |
| `asc/core/utils/fs.inc.sh` | `asc/core/utils/fs.manual-inc.sh` |
| `asc/core/utils/shell.inc.sh` | `asc/core/utils/shell.manual-inc.sh` |
| `asc/core/utils/str.inc.sh` | `asc/core/utils/str.manual-inc.sh` |

These were never `$subject/$subject.inc.sh`. `utils/` is not an active dir. The hub sources them on every heavy bootstrap.

### Explicit lazy cluster (never derived)

| Today | After | Callers that source it (grep before moving) |
|-------|--------|--------------------------------------|
| `asc/core/global.opt-inc.sh` | `asc/core/global.manual-inc.sh` | `instance.inc.sh`, `globals_debug.sh`, `remote.inc.sh`, `apache.inc.sh`, `drupalwt.inc.sh`, `moodle_d4php.inc.sh`, `remote_traefik.inc.sh`, `systemd_service_setup.sh`, `global.test.sh` |
| `asc/core/utils/str.opt-inc.sh` | `asc/core/utils/str_slug.manual-inc.sh` | `host.inc.sh` (slug path), `instance/slug.sh`, `instance/snake.sh`, `utilities.test.sh` |
| `asc/core/utils/fs.opt-inc.sh` | **gone** (split; see Wave 0) | — |
| `asc/core/utils/fs_compression.manual-inc.sh` | already | compress/extract callers |
| `asc/core/utils/fs_sync.manual-inc.sh` | already | `f_fs_merge_dirs` callers |

`global.opt-inc.sh` is not `core.opt-inc.sh`. Caller opt-inc for `asc/core/upgrade.sh` would look for `core.opt-inc.sh` / `upgrade.opt-inc.sh`. `str.opt-inc.sh` sits in `utils/`, which has no `*.sh` action and no `*.hook.sh`.

Hub child `str.inc.sh` becomes `str.manual-inc.sh`. The slug file cannot share that name → `str_slug.manual-inc.sh` (same stem idea as `fs_compression` / `fs_sync`).

---

## File docblocks

Rewrite the **file-level** header in the same slice as the `git mv`. Leave **function** docblocks alone.

Shape: shebang, one-line description, how it is sourced, `@see` the real source path(s), convention line, then the first function docblock. No changelog `@see`. No inventory of helpers. No “slug lives in that other file” footnote.

**Incorrect** (today’s `str.inc.sh`):

```bash
#!/usr/bin/env bash

##
# String-related utility functions sourced on every heavy bootstrap.
# Sanitize / split / case / tokens / random / basic-auth.
# Slug helpers: `. asc/core/utils/str.opt-inc.sh`
# @see changelog/2026/09/19-lazy-opt-inc-remaining-core-waves.md
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#
```

### Kernel (sourced from `asc/bootstrap.sh`)

```bash
#!/usr/bin/env bash

##
# <one-line description>
#
# This file is sourced during core ASC bootstrap.
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#
```

| After | One-line description |
|-------|----------------------|
| `asc/core/utils.manual-inc.sh` | Kernel utils hub. |
| `asc/core/hook.manual-inc.sh` | Hooks-related utility functions. |
| `asc/core/autoload.manual-inc.sh` | Autoloading-related utility functions. |

Do not rewrite `core.inc.sh` in this plan (autoload spelling stays). The hub has no functions; keep the convention line anyway. Its body stays the four source lines of hub children.

### Hub children (sourced from `utils.manual-inc.sh`, which bootstrap sources)

```bash
#!/usr/bin/env bash

##
# Filesystem (fs) related utility functions.
#
# This file is sourced during core ASC bootstrap.
# @see asc/core/utils.manual-inc.sh
# @see asc/bootstrap.sh
#
# Convention : functions names are all prefixed by "f".
#
```

| After | One-line description |
|-------|----------------------|
| `asc/core/utils/arr.manual-inc.sh` | Array-related utility functions. |
| `asc/core/utils/fs.manual-inc.sh` | Filesystem (fs) related utility functions. |
| `asc/core/utils/shell.manual-inc.sh` | Bash shell utilities. |
| `asc/core/utils/str.manual-inc.sh` | String-related utility functions. |

Add the convention line where it is missing today (`shell.inc.sh`). `@see` the **post-rename** hub path. If a slice still has `utils.inc.sh` on disk, `@see` that path until the hub rename lands, then retarget.

### Caller-only manuals (not on the bootstrap path)

Do **not** write “sourced during core ASC bootstrap”.

```bash
#!/usr/bin/env bash

##
# <one-line description>
#
# Callers must source this file.
#
# Convention : functions names are all prefixed by "f".
#
```

| After | One-line description |
|-------|----------------------|
| `asc/core/global.manual-inc.sh` | Init-only global aggregate helpers. |
| `asc/core/utils/str_slug.manual-inc.sh` | Slug / snake helpers. |
| `asc/core/utils/fs_compression.manual-inc.sh` | Filesystem compression and extraction helpers. |
| `asc/core/utils/fs_sync.manual-inc.sh` | Filesystem merge and sync helpers. |

Drop “not derived by bootstrap”, “`utils/` is not a caller dir”, and changelog `@see`. Drop the extra paragraph on the two fs files (“This file contains functions dedicated to…”). The one-liner is enough.

Wave 0 rewrites `fs_compression.manual-inc.sh` and `fs_sync.manual-inc.sh` even though they already have the suffix.

---

## Autoload (do **not** rename)

### Eager `*.inc.sh` (name match) — this instance’s `ASC_INC` plus disabled ext that still have the file

| File | Why autoload |
|------|----------------|
| `asc/git/git.inc.sh` | active dir `git` |
| `asc/host/host.inc.sh` | active dir `host` |
| `asc/instance/instance.inc.sh` | active dir `instance` |
| `asc/make/make.inc.sh` | active dir `make` |
| `asc/thread/thread.inc.sh` | active dir `thread` |
| `asc/core/core.inc.sh` | active dir `core` (also an explicit source in `asc/bootstrap.sh` — keep that source, keep the suffix, keep `ASC_INC`) |
| `asc/yml/yml.inc.sh` | active dir `yml` (also an explicit source in `reinit.sh` when `.env` is missing — keep that source, keep the suffix) |
| `asc/extensions/entity/entity.inc.sh` | extension point `entity` |
| `asc/extensions/file_registry/file_registry.inc.sh` | extension point `file_registry` |
| `asc/extensions/compose/compose.inc.sh` | extension point `compose` (disabled here; shape is autoload) |
| `asc/extensions/compose/instance/instance.inc.sh` | compose subject `instance` when that ext is on |
| `asc/extensions/crontab/crontab.inc.sh` | extension point `crontab` (disabled here) |
| `asc/extensions/db/db.inc.sh` | extension point `db` (disabled here) |
| `asc/extensions/remote/remote.inc.sh` | extension point `remote` (disabled here) |
| `scripts/asc/contrib/asc/apache/apache.inc.sh` | contrib `$extension.inc.sh` (disabled here) |
| `scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh` | same |
| `scripts/asc/contrib/asc/moodle_d4php/moodle_d4php.inc.sh` | same |
| `scripts/asc/contrib/asc/remote_traefik/remote_traefik.inc.sh` | same |

No `scripts/asc/*.inc.sh` at the contrib-parent glob today. That glob stays eager autoload if a file appears. It is **not** manual.

### Lazy `*.opt-inc.sh` (caller or hook derivation)

| File | Why autoload |
|------|----------------|
| `asc/test/test.opt-inc.sh` | `$subject.opt-inc.sh` for callers under `asc/test/` (`make test-core` → `asc/test/core.sh`). Extra explicit source from `generate.sh` and hooks **outside** `asc/test/` stays; **do not** rename |
| `asc/extensions/db/db/db.opt-inc.sh` | 2-level caller dir `db/` (`make db-dump`). Also an explicit source from db hooks / `remote_instance` opt-inc |
| `asc/extensions/remote_db/remote/remote.opt-inc.sh` | 2-level caller `remote/` |
| `asc/extensions/remote_instance/db/db.opt-inc.sh` | 2-level inner `db/` |
| `asc/extensions/software/software/software.opt-inc.sh` | 2-level caller `software/` |
| `asc/extensions/software/host/provision.opt-inc.sh` | `$action.opt-inc.sh` next to `provision.sh`; also sourced from `software.opt-inc.sh` |

If a later grep finds a `*.opt-inc.sh` whose **only** route is an explicit source and no caller/hook would derive it, it joins the manual table. Do not guess; grep.

---

## Loaders after the rename

No new bootstrap loop. No scan of `*.manual-inc.sh`.

| Kind | Who sources it |
|------|----------------|
| `*.inc.sh` | Eager autoload only |
| `*.opt-inc.sh` | Caller opt-inc and/or hook seed |
| `*.manual-inc.sh` | An explicit source in a caller that already exists |

Action discovery already skips double-ext after stripping `.sh` (`fs.inc` / `fs.opt-inc` / `fs_compression.manual-inc` all have a leftover dot). `core/utils` still is not an `$object`.

Garage rule today says “two include kinds only” and “no third suffix”. Accepting this plan **replaces** that line with the three-kind table above. One line in `.cursor/rules/asc-lightweight.mdc`. Do not add a new `.mdc`.

---

## Wave 0 — fs split callers (on disk, source lines stale)

`fs.opt-inc.sh` is gone. Source the file that defines the function.

| Caller | Needs |
|--------|--------|
| `asc/extensions/db/db/db.opt-inc.sh` | source `asc/core/utils/fs_compression.manual-inc.sh` (`f_fs_extract_in_place`, `f_fs_compress`) |
| `asc/extensions/db/db/dump_reduce.sh` | same |
| `scripts/asc/contrib/asc/drupalwt/new/project.sh` | source `asc/core/utils/fs_sync.manual-inc.sh` (`f_fs_merge_dirs`) |
| `asc/test/core/utilities.test.sh` | compression (`f_fs_compress_in_place`, `f_fs_extract_in_place`) |
| `asc/test/core/file_system.test.sh` | **both** (merge + compress/extract/trim) |

Keep the `type -t` guard. Rewrite the two fs `*.manual-inc.sh` file-level headers to the caller-only template. Tests: `test_f_fs_archive_helpers_absent_from_kernel_bootstrap`, `test_f_fs_compress_and_extract`, `test_f_fs_compress_gz_is_gzip_not_tar`, `test_f_fs_merge_change_trim` (`make test-core`). Unrun stays unverified.

---

## Later waves (after this plan is accepted)

Small `git mv` + retarget source lines + **file-level docblock** + tests. One cluster per slice.

1. **Kernel three** — `utils` / `hook` / `autoload` `git mv`; bootstrap source lines (leave the source of `asc/core/core.inc.sh`); kernel header template for those three; `test_asc_utils_inc_is_kernel_include` greps `utils.manual-inc.sh`; assert `ASC_INC` **still** lists `asc/core/core.inc.sh` and does **not** list `core.manual-inc.sh`.
2. **Hub children** — four `git mv` inside `utils.manual-inc.sh`; hub-child header template (`@see asc/core/utils.manual-inc.sh` then `asc/bootstrap.sh`).
3. **`global.opt-inc.sh` → `global.manual-inc.sh`** — every source site in the table above; caller-only header. Test: `test_f_global_aggregate_helpers_absent_from_kernel_bootstrap` still holds; `global.test.sh` sources the new path.
4. **`str.opt-inc.sh` → `str_slug.manual-inc.sh`** — slug/snake callers; caller-only header. Test: `test_f_str_slug_helpers_absent_from_kernel_bootstrap`.
5. **Rule + case table** — lightweight rule three-kind line; [19-eager-vs-lazy-include-cases.md](./19-eager-vs-lazy-include-cases.md) row for `fs.opt-inc.sh` becomes the two `*.manual-inc.sh` files, “never auto”.
6. **README (human)** — separate `changelog/2026/09/21-readme-manual-inc.md` when applying. Root SoT. Do not dump this inventory into README.

### Proposed README recap (3 rows, not the full table)

Heading: **Always (= eager) VS conditionally (= lazy) sourced includes** / Recap.

Replace the `fs.inc.sh` why-cell “hub `utils.inc.sh`” with hub `utils.manual-inc.sh`. Add one row: `(any)` / manual / `asc/core/utils/fs_compression.manual-inc.sh` / ❌ unless a caller sources it / not a name match, not caller-dir. Stop. Human continues.

---

## Tests (when implementing)

Unrun stays unverified.

- `make test-core`.
- Kernel sed range in `bootstrap.test.sh` still uses the comment `Include ASC core utilities`.
- No loader test should expect `*.manual-inc.sh` on `ASC_INC` or from caller opt-inc.
- After Wave 1: `[[ " $ASC_INC " == *asc/core/core.inc.sh* ]]` and `!= *core.manual-inc.sh*`. Kernel block still sources `core.inc.sh`.

---

## Open tasks

- [ ] Accept this spelling (`manual-inc`, not `private-inc`, not a fourth loader).
- [ ] Wave 0: retarget stale `fs.opt-inc.sh` source lines; rewrite `fs_compression` / `fs_sync` file headers.
- [ ] Waves 1–4: `git mv` + retarget sources + file-level docblock + the tests named above.
- [ ] Wave 5: garage rule + eager/lazy case table.
- [ ] Wave 6: README delta file (human applies).
