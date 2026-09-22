# Gates prune + approved work (2026-09-22)

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | **implemented** (this session). |
| **Scope** | Prune `gates.yml` of already-landed rows; carry approved `go: "yes"` work. Not the registry-store idea in [22-gates-registry-alternative.md](./22-gates-registry-alternative.md). |
| **Not this change** | Implementing `$subject/.asc_extensions` discovery. Filling `builder/instance/generate.sh` or `instance/discover.sh`. Committing. Category G bootstrap `global … "$(f_*)"`. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

---

## Removed from `gates.yml` (already implemented or held)

| Changelog / task | Evidence |
|------------------|----------|
| Wave C `git` off `ASC_INC` | `asc/git/git.opt-inc.sh` on disk; `git.inc.sh` gone; [19-lazy-opt-inc-remaining-core-waves.md](./19-lazy-opt-inc-remaining-core-waves.md) status; test `test_git_helpers_absent_from_bare_bootstrap` |
| Eager case-table *planned* → on disk | Files on disk; open task checked in [19-eager-vs-lazy-include-cases.md](./19-eager-vs-lazy-include-cases.md) |
| Held notes (array-dict, pdf, bootstrap cache, subject-object-action, pdf-graphviz, meadows) | Status implemented / shipped / skipped; agent “Do not re-run” |
| Discuss feedback done this session | README proposals; builder `instance/generate.sh` detail; host-scan → `instance/discover.sh` detail; entity task 8 proposal |

---

## Approved work done here

1. **Sequential:** mark leftover planned include rows **on disk** / skipped (docs only).
2. **Parallel:** shunit2 output-var cases for migrated scalars (`test_f_migrated_scalar_output_vars`).
3. **Parallel wave 4:** `f_software_*_status` → `printf -v`; callers updated; `test_f_software_status_output_vars`.
4. **Parallel waves 5–8:** `f_fs_get_most_recent`, host/shell, git get_*, test case helpers (2026-09-22 follow-up).
5. **Discuss:** README `&lt;proposal-2026-09-22&gt;` for nest declaration; Instantiation host-fixture table (`foobar.home.arpa` type / instance / cache); detailed plans in builder + host-scan changelogs.

---

## Still in `gates.yml`

- Optional wrap-vs-bootstrap measure — `approved: no` / `go: no`.
- Nameref clarity discuss — `approved: no` / `go: no`.

No `go: "yes"` rows remain after the 2026-09-22 (second) prune.

---

## Follow-up prune (same day, after human push)

Pulled clean `gates.yml`. Implemented three `go: "yes"` rows (docs/design only), then removed them:

1. **Deprecate `$subject/.asc_extensions`** — July 24 plan → skipped/rejected; deprecation changelog → implemented; README proposal already retracted the positive list.
2. **yml-structure** — plan status → accepted for discussion; no loaders.
3. **`eval` / `f_yaml_parse` design** — Category C design written; keep `eval` until a later implementation row.

---

## Safety

- No commit.
- README edits only inside escaped proposal delimiters.
- No new loader / hook / global.
- Runtime claims backed by tests listed in open verification below.

## Open

- [ ] Human accept/reject README proposals.
- [x] Focused passes: waves 5–8 (`f_fs_get_most_recent` through test helpers) — done 2026-09-22; row removed from `gates.yml`.
- [ ] Unapproved: `eval` / `f_yaml_parse` design; bootstrap `global … "$(f_*)"` (category G).
- [x] 2026-09-22: rewrite remaining `gates.yml` `summary` lines for glanceable approval.
