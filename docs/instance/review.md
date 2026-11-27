# Reply to review of `main` @ `5dc602b` (24–27 Nov)

Status: draft reply  
Scope: response to the 23-commit review ending at `5dc602b`  
Reviewed revision: `5dc602b1bfe840c915bd59420e89bb290cd357e5` (checkout has since advanced; this reply refers to the checks done at that tip)

**Source of truth:** the manual modifications recorded in this reply. Where a draft plan, older note, or automated suggestion disagrees, this document wins for remediation intent.

**Out of scope:** compatibility with other ASC project instances (upgrade paths, install-time `.gitignore` propagation, retained legacy data dirs for existing checkouts, dual job-file suffixes for instance-local leftovers, and similar). Fixes target the mother tree and its fixtures only.

Thank you for the thorough pass. The findings match what was on disk at that tip: the entity removal and path migrations left several consumers half-moved, and the scratch-checkout failures you listed are real blockers. This reply accepts each comment, records confirmation, and states the intended fix direction. It does not claim the fixes are implemented yet.

Background only (not authority over this reply):

- [24-deprecate-entity-related-abstractions.md](../plans/2026/11/24-deprecate-entity-related-abstractions.md) — remote ownership / purge / enumeration context
- [24-restore-active-data-ignore-rules.md](../plans/2026/11/24-restore-active-data-ignore-rules.md) — ignore-path inventory context

## Verdict

Agree with severity and ordering, with one correction to the remote remediation sequence: **make cleanup safe before restoring lifecycle hooks.** Restoring hooks alone would let `reinit` call the unsafe purge again. Ownership checks, Git exclusions for generated output, and hook relocation land together. The four P1 items remain the blockers; the P2 items are confirmed. The globals synonym is the cheapest independent unblocker for `make test-core`.

Convention check is correct: several moves put hooks under an object directory, optional includes beside the wrong level, and discovery globs on the old filename suffix. Shell syntax (`bash -n`) passing does not catch any of that.

ASC discovery (README recap): `$ext/$subject/$action.sh` → `$subject-$action`; `$ext/$subject/$object/$action.sh` → `$subject-$object-$action`. Object-dir hooks (`$ext/$subject/$object/*.hook.sh`) are not discovered.

---

## [P1] Preserve maintained files during remote cleanup

**Accepted.** Confirmed at `f_remote_purge_instances` in `asc/extensions/remote/remote.inc.sh` (approx. 936–939): after listing every direct file under `data/instance/remote`, the loop `rm`s each one with no ownership filter. That deletes maintained YAML, README, and any other non-generated sibling in the same directory.

This is the most urgent regression. Refreshing remote definitions must not be a blunt directory wipe. **Do not restore the lifecycle hooks until this ownership rule is in place** (see remediation order).

**Intended fix:**

1. Define an explicit **generated-file ownership** rule before any purge, overwrite, or removal. Filename or `.sh` extension alone is insufficient in a shared directory.
2. Apply that rule consistently in generation, enumeration, `remote-instance-remove`, purge, and uninit.
3. If ownership cannot be proven, preserve the file and report a conflict; do not overwrite a pre-existing path that maps to a declared ID.
4. Keep the ID-list cache and any parsed intermediate in ASC-owned generated locations that cannot be enumerated as remotes.

**Acceptance / fixture:**

- Seed a maintained README and an unrelated sibling; run refresh/purge twice; assert those files survive while only owned generated definitions are removed.
- Same-ID collision: place a maintained file whose name matches a declared remote ID; run refresh; assert the operation **reports failure** and **neither deletes nor overwrites** that file.
- Enumerate generated definitions only; invalidate the ID-list cache on remove and regeneration (see P2 ID-list item — same ownership rule).

---

## [P1] Restore discovery of remote lifecycle hooks

**Accepted — land together with ownership and Git exclusions, not before.** Hooks currently live under:

- `asc/extensions/remote/remote/instance/post_init.hook.sh`
- `asc/extensions/remote/remote/instance/ensure_dirs_exist.hook.sh`
- `asc/extensions/remote/remote/instance/uninit.hook.sh`

That is `$ext/$subject/$object/*.hook.sh`, which ASC does not discover. Hook lookup in `f_hook_build_lookup_by_subject` skips object-directory action paths, so with `remote` enabled these implementations are never found. Directory creation (`ensure_dirs_exist`), generation after init, and cleanup on uninit are therefore omitted.

Discoverable shape (extension’s `instance` subject):

- `asc/extensions/remote/instance/post_init.hook.sh`
- `asc/extensions/remote/instance/ensure_dirs_exist.hook.sh`
- `asc/extensions/remote/instance/uninit.hook.sh`

**Intended fix:** move the three lifecycle hooks under `asc/extensions/remote/instance/…`, keep the same hook call contracts, and update `@see` / examples. Verify discovery with the real lookup, e.g. `make hook-debug p:post a:init` (and the matching calls for `ensure_dirs_exist` and uninit). Re-run init/reinit/uninit in a fixture with `remote` enabled only **after** ownership protects maintained files, and assert the hooks execute without deleting non-generated content.

---

## [P1] Restore Git exclusions for local data

**Accepted.** The mother `.gitignore` after `aee5a425` covers several *new* singular trees (`data/log/`, `data/thread/`, `data/db/…`) while active producers in this tree still write other paths. Inventory for the mother (other-instance upgrade leftovers are out of scope):

| Path | Role | Mother rule today |
| --- | --- | --- |
| `data/logs/` | Active: `asc/log/storage.hook.sh`, rotate/wrap | only `/data/log/*` |
| `data/threads/` | Active: `asc/thread/thread.inc.sh`, wrap/list/monitor | only `/data/thread/*` |
| `data/db/dumps/` | Current DB default (`ASC_DB_DUMPS_DIR` → `data/db/dumps`) | `/data/db/…` present; confirm compressed dumps (`.sql.tgz` / `.gz`) stay excluded |
| `data/private/` | Drupal private files (README / contrib default) | prior exclusion removed |
| `data/files/` | Moodle contrib defaults (`MOODLE_PHPUNITDATA_DIR`, behat data/faildumps under `data/files/…`) | prior exclusion removed |
| `data/instance/remote/<id>.sh` | Generated per-ID remote definitions | **not ignored** |
| `data/instance/remote_ids.sh`, `data/instance/remote_parsed.sh` (and any other generated remote metadata beside the per-ID files) | Generated remote metadata / caches | **not ignored** (must be covered with the ownership design; must not be enumerated as remote IDs) |

So Git ignore checks that show active log, thread, private-file, Moodle `data/files`, and generated remote paths as stageable are correct.

**Intended fix:** restore mother `.gitignore` exclusions for the paths above that producers still use; keep intentional README exceptions. Decide remote generated-file and metadata ignore together with ownership (blanket `*.sh` under `data/instance/remote` is too wide). Do not design install-time propagation or repair of other projects’ `.gitignore` files.

Land this together with remote ownership and hook relocation so generated output is ignored before reinit starts rewriting definitions again.

---

## [P1] Complete the cron path migration

**Accepted.** Stacked breakages beyond `cron-settings`:

1. **Optional include location.** `cron-settings` is `$ext/$subject/$action.sh` → pivot `cron-settings` at `asc/extensions/cron/cron/settings.sh`. Bootstrap’s caller opt-inc for that 2-level entry looks for `…/cron/cron.opt-inc.sh` beside the subject directory. The helpers still live at `asc/extensions/cron/cron.opt-inc.sh` (extension root), so the include is never sourced.
2. **Stale base template + discovery suffix.** `f_cron_load_base_templates` still opens `asc/extensions/crontab/base_settings.crontab.yml`. The base template is now `asc/extensions/cron/base_settings.cron.yml`. Discovery still walks `*.crontab.yml`, while shipped jobs are `*.cron.yml`:
   - `log/rotate.at-03h00.cron.yml` → log-rotate
   - `thread/monitor.every-1m.cron.yml` → thread-monitor
3. **Downstream callers still on the old tree.** Update together:
   - Contrib post-init: `scripts/asc/contrib/asc/crontab/instance/post_init.hook.sh` still sources `asc/extensions/cron/cron.opt-inc.sh` and points `@see` at the old crontab include path.
   - YAML test: `test_f_cron_load_base_templates` in `asc/test/core/yml.test.sh` still sources `asc/extensions/crontab/crontab.inc.sh`.
   - Debian 13 run hook: `asc/extensions/cron/cron/run.debian-13.hook.sh` still sources `asc/extensions/crontab/cron/run.hook.sh`.

**Intended fix:** update loading, discovery, contrib, tests, and host hooks together in this tree:

- Wire the opt-inc so `cron-settings` and sibling actions source it.
- Point the base template at `asc/extensions/cron/base_settings.cron.yml`.
- Discover `*.cron.yml` only (no dual-suffix / legacy `*.crontab.yml` compatibility layer).
- Refresh the contrib post-init include, the YAML test, and the Debian 13 run hook.
- Acceptance: `cron-settings` with `cron` enabled; generated entries for log-rotate and thread-monitor.

---

## [P2] Give the globals test its own extension fixture

**Accepted.** `test_instance_init_aggregates_core_appends_once` in `asc/test/core/global.test.sh` still asserts `anti-pattern/code-smell` in the aggregated `ASC_SYNONYMS` line. The checker extension used to declare that synonym; after its removal, nothing shipped does, so both dry-run init iterations fail and `make test-core` stops.

**Baseline clarification:** the same globals test on `f00b7bc` passed all six tests because checker still declared `anti-pattern/code-smell`. That was not a weaker suite — it was a different extension set.

**Intended fix:** the suite already creates a temporary extension under `asc/extensions/nftascgevdehnc/` (see `oneTimeSetUp` around line 78). Add a **fixture-owned** `anti-pattern/code-smell` synonym there (e.g. in that extension’s `global.vars.sh`). Do not reintroduce checker solely for this assertion, and do not soft-delete the check. Aggregation under test stays independent of which product extensions ship.

This remains the smallest unblocker for the core suite and can land ahead of the remote/cron bundle.

---

## [P2] Repair remote database action dependencies

**Accepted.** With `remote` and `remote_asc` enabled, the moved DB actions break loading and remote execution:

| Pivot | Path shape | Problem |
| --- | --- | --- |
| `remote-db-sync-to` | `$ext/$subject/$object/$action.sh` → `…/remote/db/sync_to.sh` | Bootstrap loads subject opt-inc `…/remote/remote.opt-inc.sh`, not `…/remote/db/db.opt-inc.sh`, so `f_remote_sync_db_to` is undefined → `command not found` |
| `remote-db-sync-from` | same object dir | Same opt-inc miss; helpers also call a missing `remote_asc` exec path |
| `remote-db-dl-from` | same object dir | Same |

Call sites under `remote_asc` still reference `asc/extensions/remote_asc/remote/exec.sh`, which does not exist. The existing action to use is **`remote-exec`** at `asc/extensions/remote/remote/exec.sh` (`$ext/$subject/$action.sh` → `remote-exec`).

**Intended fix:**

- Restore subject-level loading for the DB helpers (subject `remote.opt-inc.sh` that sources the db include, or relocate the include to the path bootstrap already resolves).
- Point sync-from / dl-from (and other `remote_asc` callers) at **`remote-exec`**, not a missing `remote_asc/remote/exec.sh`.
- Fixtures: a `remote-db-sync-to` case that checks helper loading without a live remote; a stubbed `remote-db-sync-from` or `remote-db-dl-from` case that checks the exec path is the real `remote-exec` action (and fails clearly if still missing).

---

## [P2] Keep full and partial test archives consistent

**Accepted.** Confirmed in `asc/test/test.opt-inc.sh`:

| Issue | Evidence |
| --- | --- |
| `output.txt` before parent dir | `f_test_results_batch_begin` opens `data/test/result/${slug}/output.txt` before creating that batch subdirectory. |
| Summary path mismatch | Partial begin reads `…/${slug}/summary.yml` (and `.txt`); `f_test_results_batch_end` writes `data/test/result/${slug}.yml`. |
| Status lookup stale path | `f_test_results_case_status` also reads `data/test/result/${slug}.yml` (then frozen fallback) — every archive reader must follow the same contract when the summary moves. |
| Dropped earlier cases | A full run then a partial run never reloads the written summary, so prior cases disappear from the merged tree. |
| Colliding batch keys | `test_results_slug="${p_dir##*/}"` — ASC core and extension batches both named `core` share one archive. |
| Archive self-test | Needs the helper include and path assertions updated to the same contract. |

**Intended fix:**

- One summary location used by writer, partial loader, **and** `f_test_results_case_status`.
- Create the batch directory before opening `output.txt`.
- Give batches **distinct keys** (not only the directory basename) so ASC core and extension `core` suites do not clobber each other.
- Acceptance: full run followed by partial run keeps earlier cases; two batches with the same basename get distinct archives; archive self-test updated.

---

## [P2] Keep the remote ID list accurate

**Accepted.** Confirmed in `f_remote_get_instances` (approx. 972–986): every direct file under `data/instance/remote` except `_parsed.sh` becomes an ID via `${file%.sh}`. A maintained `README.md` therefore yields a spurious remote ID. `remote-instance-remove` also leaves the deleted ID in `data/instance/remote_ids.sh` because the cache is not invalidated on remove.

Same ownership rule as the P1 purge fix must drive enumeration: **generated definitions only**. Removal and regeneration must invalidate the ID-list cache. Fold this into the remote ownership + fixture work (including the same-ID collision case above).

---

## Cross-cutting notes

- **Authority.** Manual modifications in this reply are the source of truth for what to fix and how. Draft plans are background only.
- **Out of scope.** Other ASC project instance compatibility (upgrades, install-time ignore repair, legacy path retention for foreign checkouts, dual cron YAML suffixes for leftover job files).
- **Convention drift.** Prefer ASC pivot syntax when naming entry points: `$ext/$subject/$action.sh` → `$subject-$action`; `$ext/$subject/$object/$action.sh` → `$subject-$object-$action`. Object-dir hooks are not discovered. Treat “path moved” and “discovery still finds it” as one change set.
- **Test signal.** Scratch checkout at the reviewed revision: `make test-core` stopped on the missing synonym; archive, YAML, and remote lifecycle suites failed when run alone. That matches a half-migrated tip, not flaky tests.
- **Execution.** No commit, push, or live instance reinit is authorized by this document. Remediation should land as explicit follow-up work with fixture proof per item in this tree.

## Proposed remediation order

1. Globals fixture synonym in the existing `nftascgevdehnc` temporary extension — unblock `make test-core`.
2. **Remote ownership + purge/enumerate/remove/cache + lifecycle hook relocation + Git exclusions for generated remotes/metadata** — one coherent change set. Safe cleanup first; hooks restored in the same land so reinit cannot call the unsafe purge. Fixture covers maintained siblings, same-ID collision (refresh fails without delete/overwrite), and ID-list accuracy.
3. Mother Git ignore restoration for active producers — `data/logs`, `data/threads`, `data/db/dumps`, `data/private`, Moodle `data/files` (no other-instance ignore policy).
4. Cron opt-inc + `*.cron.yml` discovery/template + contrib post-init + YAML test + Debian 13 run hook — restore `cron-settings`, log-rotate, thread-monitor (`*.cron.yml` only).
5. Test archive path consistency — every reader (`batch_begin` partial load, `batch_end` writer, `f_test_results_case_status`), distinct batch keys, full-then-partial and same-basename batch cases.
6. `remote-db-sync-to` / `remote-db-sync-from` / `remote-db-dl-from` opt-inc wiring + point callers at existing `remote-exec`.

Items in step 2 must not be split so that hooks return before ownership and ignore rules protect maintained files and generated output.
