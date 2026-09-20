# Split archive helpers out of kernel `fs.inc.sh`

| Field | Value |
|-------|--------|
| **Date** | 2026-09-19 |
| **Status** | proposed (no code yet). Filename **locked**: `asc/utils/fs.opt-inc.sh` (not `private-inc`; two include kinds — [20-two-include-kinds.md](./20-two-include-kinds.md)). README Recap applied; gzip vs `tar`+`.gz` and `f_fs_watch_poll` still open. |
| **Scope** | `asc/utils/fs.inc.sh` (~1088 lines) is sourced on **every** heavy bootstrap via `asc/utils/core_utils.inc.sh`. Move compress/extract/merge/watch off that path. Align `f_db_dump` / `dump_reduce.sh` with those helpers. |
| **Parent** | [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md) Wave A (fs slice only). |
| **Not this plan** | `str.inc.sh` tail, yaml dual-source, `db.inc.sh` thinning (see sibling sub-plans). |

`$` in this file is the ASC docs placeholder, not a shell variable.

---

## Why utils cannot use the auto loaders

Caller opt-inc and hook seeding derive `<dir>/<subject>.opt-inc.sh` from a **caller script** or a `*.hook.sh`. `asc/utils/` is neither an active dir nor a hook dir.

| Path | Auto-sourced? |
|------|----------------|
| `asc/utils/fs.inc.sh` | ✅ kernel |
| `asc/utils/fs.opt-inc.sh` | ❌ never, unless something `.`s it |

The 2026-09-11 line “move compress to `fs.opt-inc.sh` sourced by the few callers” is still the pick — **explicit `.`**, not a third loader and not a third suffix.

---

## Keep vs move

Production callers (this repo, excluding tests):

| Function | Keep in `fs.inc.sh`? | Why |
|----------|----------------------|-----|
| `f_fs_dir_list` | **keep** | `core.inc.sh`, `db/list_dumps.sh` |
| `f_fs_file_list` | **keep** | `list_dumps.sh`, entity, remote, mysql `exec.mysql.hook.sh` |
| `f_fs_relative_path` | **keep** | git, mysql/pgsql dump hooks, `list_dumps.sh`, remote |
| `f_fs_get_file_contents` | **keep** | `core.inc.sh`, drupalwt |
| `f_fs_get_most_recent` | **keep** (v1) | `db.inc.sh`, remote opt-incs. Cheap. Revisit if `f_db_get_dump` leaves eager db. |
| `f_fs_change_line` | **keep** | `instance/fs_perms_set.hook.sh` |
| `f_fs_compress` / `_in_place` / `f_fs_trim_compression_ext` | **move** | tests + (should be) db dump |
| `f_fs_extract` / `_in_place` | **move** | `f_db_exec`, `db/dump_reduce.sh` |
| `f_fs_merge_dirs` | **move** | `scripts/asc/contrib/asc/drupalwt/new/project.sh` only |
| `f_fs_watch_poll` | **move** | tests / comments only |

Approx. lines moved: `fs.inc.sh:37-231` (watch + merge) + `:696-1088` (compress/extract) ≈ **600**.

---

## Target files

- **Keep:** `asc/utils/fs.inc.sh` — list/path/contents/most-recent/change-line only.
- **New:** `asc/utils/fs.opt-inc.sh` — watch, merge, compress, extract (same function names). Header comment: *not derived by bootstrap; callers must `.` this file*.
- **Do not** add `asc/utils` to `ASC_INC` or invent `ASC_OPT_INC`.

### Who `.`s the new file

| Caller | How |
|--------|-----|
| `asc/test/core/file_system.test.sh` / `utilities.test.sh` | `. asc/utils/fs.opt-inc.sh` after bootstrap (or from a tiny test helper once) |
| `asc/extensions/db/db.inc.sh` `f_db_exec` (today) / `db/db.opt-inc.sh` (after db sub-plan) | `.` once at top of the dump/exec include, not inside the hot loop |
| `asc/extensions/db/db/dump_reduce.sh` | `.` after bootstrap, next to the existing `f_fs_extract_in_place` call |
| `scripts/asc/contrib/asc/drupalwt/new/project.sh` | `.` before `f_fs_merge_dirs` |

Idempotent source: wrap with `if ! type f_fs_extract_in_place &>/dev/null; then . …; fi` **or** rely on “source once per shell” and document that tests/bootstrap order must not assume archive helpers exist.

---

## Compression inconsistency (fix in this plan)

Today:

| Site | What it writes |
|------|----------------|
| `f_db_dump` | `tar czf "$db_dump_file.gz"` — **tar.gz bytes**, `.gz` name |
| `dump_reduce.sh` | `gzip -c` — real gzip (comment: restores use gunzip) |
| `f_fs_compress` | `tar -czf` default extension **`tgz`** |

`f_db_exec` already goes through `f_fs_extract_in_place`, which is why mixed archives still restore. The dump vs reduce mismatch is still a footgun for humans and for `gunzip` without `f_fs_extract`.

**Pick:** dump/reduce/exec all use `f_fs_compress*` / `f_fs_extract*` after the split. Choose **one** on-disk convention (prefer **gzip of a single SQL file**, matching `dump_reduce.sh` and typical `*.sql.gz` names) and make `f_fs_compress` honor it when the preferred extension is `gz` (today’s TODO in `f_fs_compress`: “adapt tar parameters depending on extension”). Do not leave `tar czf file.sql.gz` as a special case in `f_db_dump`.

If gzip-vs-tar is too behavior-changing for one PR, split: (1) move functions + explicit `.`, keep `tar czf` in `f_db_dump` for this PR; (2) format unification as a tiny follow-up. Prefer doing both if tests in `file_system.test.sh` + a db dump/exec test can lock the format.

---

## Tests

- Existing `test_f_fs_compress_and_extract` / in-place tests: fail with `type -t f_fs_compress` → empty **before** the test file sources `fs.opt-inc.sh`; pass after.
- `test_f_fs_watch_poll` / merge tests: same.
- A kernel-only bootstrap (`ASC_INC` empty or `make` of a non-db action) must **not** define `f_fs_extract`.
- After dump alignment: `f_db_exec` on a file produced by `f_db_dump` still works (extract in place).

---

## Open tasks

- [ ] Confirm gzip-of-SQL vs keep tar+`.gz` name.
- [ ] Move functions; add explicit `.` at the callers above.
- [ ] Case-table row for `asc/utils/fs.opt-inc.sh` stays “never auto-sourced”.
