# Reply to review of `main` @ `5dc602b` (24–27 Nov)

Status: draft reply  

Implementation update, 27 November: the five remediation items below have been
implemented locally. Their linked plans record the changes, fixture checks and
limits. The integrated core suite passed in an initialized disposable checkout;
live remote, database and host crontab operations were not exercised. The
findings and verdict below describe the reviewed revisions, not the current
working tree.
Scope: response to the 23-commit review ending at `5dc602b`  
Reviewed revision: `5dc602b1bfe840c915bd59420e89bb290cd357e5` (checkout has since advanced; this reply refers to the checks done at that tip)

**Authority:** this reply owns remediation decisions (what to fix and why). The six dated plans below own steps and acceptance for their items. Where an older note or automated suggestion disagrees with this reply on remediation intent, this reply wins; where a plan’s steps or acceptance need detail, that plan wins over a shorter summary here.

**Out of scope:** compatibility with other ASC project instances (upgrade paths, install-time `.gitignore` propagation, retained legacy data dirs for existing checkouts, dual job-file suffixes for instance-local leftovers, and similar). Fixes target the mother tree and its fixtures only.

Thank you for the thorough pass. The findings match what was on disk at that tip: the entity removal and path migrations left several consumers half-moved, and the scratch-checkout failures you listed are real blockers. This reply accepts each comment, records confirmation, and states the intended fix direction. It does not claim the fixes are implemented yet.

Derived plans (implementation documents for steps and acceptance):

1. [27-globals-test-fixture-synonym.md](../plans/2026/11/27-globals-test-fixture-synonym.md) — ready (fixture synonym verified in disposable checkout)
2. [27-remote-lifecycle-ownership.md](../plans/2026/11/27-remote-lifecycle-ownership.md)
3. [27-mother-data-gitignore.md](../plans/2026/11/27-mother-data-gitignore.md)
4. [27-cron-path-migration.md](../plans/2026/11/27-cron-path-migration.md)
5. [27-test-archive-consistency.md](../plans/2026/11/27-test-archive-consistency.md)
6. [27-remote-db-action-loading.md](../plans/2026/11/27-remote-db-action-loading.md)

Related README labeling work (separate from this code reply):
[27-readme-proposed-as-current.md](../plans/2026/11/27-readme-proposed-as-current.md).

Background only (context; not authority over this reply’s decisions or the derived plans’ steps):

- [24-deprecate-entity-related-abstractions.md](../plans/2026/11/24-deprecate-entity-related-abstractions.md) — remote ownership / purge / enumeration context; still-relevant load, YAML-variant, and stale-load checks are carried into the remote lifecycle plan
- [24-restore-active-data-ignore-rules.md](../plans/2026/11/24-restore-active-data-ignore-rules.md) — ignore-path inventory context

## Verdict

Agree with severity and ordering, with one correction to the remote remediation sequence: **make cleanup safe before restoring lifecycle hooks.** Restoring hooks alone would let `reinit` call the unsafe purge again. Ownership checks (including load), failure propagation on refresh/`reinit` **and both hook-cache paths**, hook relocation, and the mother ignore parent-rule fix (`/data` → `/data/*`) land together as **one** criterion — not ownership first and ignore as a follow-up. After `007a0c5`, generated data is already ignored; the ignore P1 is restoring effective README/maintained exceptions (inventory from `git ls-files data`) without un-ignoring producers. The four P1 items remain the blockers; the P2 items are confirmed. The globals synonym is the cheapest independent unblocker for `make test-core` and is ready.

Convention check is correct: several moves put hooks under an object directory, optional includes beside the wrong level, and discovery globs on the old filename suffix. Shell syntax (`bash -n`) passing does not catch any of that.

ASC discovery (README recap): `$ext/$subject/$action.sh` → `$subject-$action`; `$ext/$subject/$object/$action.sh` → `$subject-$object-$action`. Object-dir hooks (`$ext/$subject/$object/*.hook.sh`) are not discovered.

---

## [P1] Preserve maintained files during remote cleanup

**Accepted.** Confirmed at `f_remote_purge_instances` in `asc/extensions/remote/remote.inc.sh` (approx. 936–939): after listing every direct file under `data/instance/remote`, the loop `rm`s each one with no ownership filter. That deletes maintained YAML, README, and any other non-generated sibling in the same directory.

This is the most urgent regression. Refreshing remote definitions must not be a blunt directory wipe. **Do not restore the lifecycle hooks until this ownership rule is in place** (see remediation order).

**Intended fix:**

1. Define an explicit **generated-file ownership** rule before any purge, overwrite, removal, **or load**. Filename or `.sh` extension alone is insufficient in a shared directory.
2. Apply that rule consistently in generation, enumeration, `remote-instance-remove`, purge, uninit, and `f_remote_instance_load` (reject unowned definitions; consumers must stop on load failure).
3. If ownership cannot be proven, preserve the file and report a conflict; do not overwrite a pre-existing path that maps to a declared ID.
4. Keep the ID-list cache and any parsed intermediate in ASC-owned generated locations that cannot be enumerated as remotes.
5. Do not purge before YAML selection and destination checks; define what remains available after a failed refresh so a partial/stale set is never presented as current.
6. Propagate lifecycle abort using the builder abort pattern (`… || exit $?`). Cover **cold** via public `reinit`/`init`, and **warm** via direct init or a dispatcher fixture with a verified cache hit — repeating `reinit` clears the hook cache and cannot prove warm. A shared dispatcher change is conditional on demonstrated need after hooks use the builder pattern. Include uninit cleanup failure.
7. **Every** `f_remote_instance_load` consumer must stop on failure (full caller audit as implementation work; representative fixtures for regression). Include the definition accessor, which can return values from the previously loaded remote.
8. Define which `REMOTE_INSTANCE_*` values a **successful** load replaces or clears. Generator skips empty fields, so loading valid B after valid A can leave A’s optional values (e.g. docroot) active unless the loader clears unset keys.

**Acceptance / fixture:**

- Seed a maintained README and an unrelated sibling; run refresh/purge twice; assert those files survive while only owned generated definitions are removed.
- Same-ID collision: place a maintained file whose name matches a declared remote ID; run refresh; assert the operation **reports failure** and **neither deletes nor overwrites** that file.
- Propagate that failure through the public path: `remote-definitions-update` and cold `reinit` (post-init) must exit **nonzero**, must not print success/`done` when setup failed, and must preserve the maintained file. Warm abort uses a path that can stay warm. Today both print `done` and exit zero when setup returns nonzero (reproduced with setup stubbed to return 7).
- Load remote A, then a missing or unowned B in the same shell; assert load failure without using A’s configuration, including via the definition accessor.
- Load real-generated A then B in the same shell; assert exports match the replace/clear contract (no silent inheritance of A’s omitted fields).
- Enumerate generated definitions only; invalidate the ID-list cache on remove and regeneration (see P2 ID-list item — same ownership rule).
- Carry forward YAML variant fallback and double-generate checks from the older remote plan into the lifecycle plan’s acceptance.

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

**Intended fix:** move the three lifecycle hooks under `asc/extensions/remote/instance/…`, keep the same hook call contracts, and update `@see` / examples. Verify discovery with the real lookup, e.g. `make hook-debug p:post a:init` (and the matching calls for `ensure_dirs_exist` and uninit). Re-run init/reinit/uninit in a fixture with `remote` enabled only **after** ownership protects maintained files, and assert the hooks execute without deleting non-generated content. Hooks that must abort use the builder pattern; cold via `reinit`, warm via direct init or a verified cache-hit fixture (not a second `reinit`); uninit cleanup failure included (details in the lifecycle plan).

---

## [P1] Restore Git exclusions for local data

**Accepted — and updated for `007a0c5`.** That commit already ignores generated data via a parent `/data` rule. The same rule **prunes** the directory, so nested README exceptions below it never take effect. In a Git fixture, `/data/*` restored the existing `data/asc` and `data/cron` README exceptions while dumps and logs stayed ignored, but still hid already tracked local instance and host READMEs, `data/doc` fixtures, and fonts.

Coverage of producers and generated remotes is therefore largely present; the remaining ignore work is to **stop pruning** so intentional exceptions work, and to **record** trackable paths from `git ls-files data` (including `data/instance`, `data/host`, and `data/doc`). Verify maintained paths and generated neighbors with `git check-ignore --no-index -v`.

| Concern | Role after `007a0c5` |
| --- | --- |
| Parent `/data` | Ignores all of `data/` including generated remotes, logs, dumps, private, Moodle `data/files` — and also hides README exceptions |
| Nested `!/data/…/README.md` etc. | Present in the file but ineffective while `/data` prunes |
| Active producers (`data/logs`, `data/threads`, `data/db/dumps`, …) | Ignored by parent; keep ignored after switching to `/data/*` |
| Generated remotes / metadata | Ignored by parent; keep ignored; ownership still decides purge/enumerate |
| Maintained under `data/instance`, `data/doc` | Must be listed explicitly and proven trackable after the parent-rule fix |

**Intended fix:** change `/data` to `/data/*` (or equivalent non-pruning parent); keep generated producers ignored; record and verify every path from `git ls-files data`. Coordinate with remote ownership (blanket `*.sh` under `data/instance/remote` remains too wide). Do not design install-time propagation into other projects.

**One landing criterion** with remote ownership and hook relocation — not a separate follow-up step — so maintained remote README exceptions and generated ignores agree.

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

**Intended fix:** update loading, discovery, contrib, tests, host hooks, and `cron-run` together in this tree:

- Wire the opt-inc so `cron-settings` and sibling actions source it.
- Point the base template at `asc/extensions/cron/base_settings.cron.yml`.
- Discover `*.cron.yml` only (no dual-suffix / legacy `*.crontab.yml` compatibility layer). Job files are `$ext/$subject/$action.$preset.cron.yml`.
- Restrict discovery to ASC’s **enabled** extension and subject inventory; detect duplicates by **generated entry key** across presets; **validate before replace** so a bad job does not remove the previous generated definition; preserve the hook-backed thread-monitor job when its owner stays enabled. Path/suffix-only discovery accepted a disabled-extension job, overwrote shipped log-rotate, listed it twice, and missed an enabled contrib job.
- Refresh the contrib post-init include, the YAML test, and the Debian 13 run hook.
- Update the `cron-run` missing-job diagnostic (still says `.crontab.yml`) to that `.cron.yml` shape.
- Dispatch via normal `hook_ms` (not dry-run lookup then manual sourcing); assert which implementation ran; **keep an explicit no-runner failure** (`hook_ms` returns zero on empty match). Debian 13 currently delegates the same behavior as the default via a stale path.
- Contrib post-init must abort on failed generation (no host sync) and on failed sync when `ASC_CRON_SYNC_ON_INIT=true` (builder `|| exit $?`); today it prints `done` and exits zero after stubbed failures.
- Acceptance: `cron-settings` with `cron` enabled; generated entries for log-rotate and thread-monitor when enabled; disabled-extension job rejected; enabled contrib job included; post-init failure fixtures; `cron-run` fixture asserts the selected run-hook implementation and the empty-match failure.

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

- Restore subject-level loading for the DB helpers, scoped to the DB actions (subject `remote.opt-inc.sh` that sources the db include, or relocate the include to the path bootstrap already resolves).
- Point sync-from / dl-from (and other `remote_asc` callers) at **`remote-exec`**, not a missing `remote_asc/remote/exec.sh`.
- Forward arguments with `"$@"` so the documented empty second argument before an explicit DB ID is preserved inside the action (wrappers currently use unquoted `$@`). Empty-slot fixtures use **direct action paths**; Make can drop `''` before the action starts — document Make coverage separately.
- Forward the selected DB ID into dump and restore operations (`db-restore`, `get_dump.sh`, local restore). Use DB-scoped dump helpers for sync-to empty/`new` source selection. Asserting only the shell’s selected DB can pass while restore targets `default` or omits the DB argument.
- Propagate failures **inside** the real restore path (clear must block import; import failure reaches the public action). An outer restore stub alone is insufficient.
- Enable **`db`** in the fixture as well: with only `remote` and `remote_asc`, a repaired include can define `f_remote_sync_db_to` while `f_db_set` remains missing.
- Fixtures: exercise **all three pivots** with **two distinguishable DBs**; assert uploaded dump and restore target for sync-to empty/`new`; assert DB at each operation and final status; assert a failed prerequisite prevents restore; update action examples alongside the wiring.

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
| Archive self-test escapes fixture | Suite creates `test_results_self_tmp`, but helpers bypass it. `_u_archived_status` builds from an unset local `batch_dir`, so the test tries to create `/plain-ok` and similar paths. |

**Intended fix:**

- One summary location used by writer, partial loader, **and** `f_test_results_case_status`.
- Create the batch directory before opening `output.txt`.
- Give batches **distinct keys** (not only the directory basename) so ASC core and extension `core` suites do not clobber each other.
- Keep archive self-tests inside `test_results_self_tmp` (fix `_u_archived_status`).
- Fix per-case status parsing: the real batch runner archived a failing first shUnit2 case as PASS and a passing second as FAIL (aggregate failure assigned to the last case). Require mixed fail/pass and skip/pass suites. When capture cannot identify which case skipped (`OK (skipped=1)` is identical across different skip sets), record unknown/insufficient rather than inventing SKIP. Decide whether regenerated results should keep removing the frozen fallback (writer currently does).
- **Legacy summary policy:** first load of an old-parser summary must discard it or import entries as unknown/insufficient — do not carry a falsely attributed PASS into a partial merge. Seed one such summary in acceptance; then verify partial merges preserve valid new-rules results.
- Acceptance: full then partial keeps earlier cases under the new rules; same-basename batches stay distinct; fail/pass and skip/pass statuses verified under the evidence contract; legacy seed handled; archive self-test fixture-isolated.

---

## [P2] Keep the remote ID list accurate

**Accepted.** Confirmed in `f_remote_get_instances` (approx. 972–986): every direct file under `data/instance/remote` except `_parsed.sh` becomes an ID via `${file%.sh}`. A maintained `README.md` therefore yields a spurious remote ID. `remote-instance-remove` also leaves the deleted ID in `data/instance/remote_ids.sh` because the cache is not invalidated on remove.

Same ownership rule as the P1 purge fix must drive enumeration: **generated definitions only**. Removal and regeneration must invalidate the ID-list cache. Fold this into the remote ownership + fixture work (including the same-ID collision case above).

---

## Cross-cutting notes

- **Authority.** This reply owns remediation decisions. The six derived plans own steps and acceptance. Older Nov-24 plans are background; carry still-relevant remote checks (YAML variant fallback, stale-load) into the lifecycle plan rather than treating that older plan as executable authority.
- **Out of scope.** Other ASC project instance compatibility (upgrades, install-time ignore repair, legacy path retention for foreign checkouts, dual cron YAML suffixes for leftover job files).
- **Convention drift.** Prefer ASC pivot syntax when naming entry points: `$ext/$subject/$action.sh` → `$subject-$action`; `$ext/$subject/$object/$action.sh` → `$subject-$object-$action`. Object-dir hooks are not discovered. Treat “path moved” and “discovery still finds it” as one change set. Discovery can be correct and still produce the wrong result when ownership, enabled inventory, or status propagation is missing on the normal path.
- **Test signal.** Scratch checkout at the reviewed revision: `make test-core` stopped on the missing synonym; archive, YAML, and remote lifecycle suites failed when run alone. That matches a half-migrated tip, not flaky tests. At `12d6a6b1`, a disposable checkout confirmed the globals synonym unblocks the six globals tests; full `make test-core` and end-to-end lifecycle acceptance remain unverified.
- **Execution.** No commit, push, or live instance reinit is authorized by this document. Remediation should land as explicit follow-up work with fixture proof per item in this tree.

## Proposed remediation order

1. Globals fixture synonym in the existing `nftascgevdehnc` temporary extension — unblock `make test-core` (**ready**).
2. **Remote ownership + load checks (full consumer audit; failed load + successful A→B replace/clear) + purge/enumerate/remove/cache + failure propagation (builder abort; cold reinit + warm via init/dispatcher fixture) + lifecycle hook relocation + mother ignore parent-rule / `git ls-files data` inventory** — **one landing criterion**. Safe cleanup first; hooks restored in the same land so reinit cannot call the unsafe purge. Fixture covers maintained siblings, same-ID collision, A-then-missing-B and A-then-B loads, uninit cleanup failure, and ID-list accuracy.
3. Cron opt-inc + enabled-inventory `*.cron.yml` discovery/template + entry-key duplicate detection (validate before replace) + contrib post-init abort on generation/sync failure + YAML test + Debian 13 run hook + normal `hook_ms` `cron-run` dispatch with preserved no-runner failure — `$ext/$subject/$action.$preset.cron.yml` only.
4. Test archive path consistency — every reader, distinct batch keys, full-then-partial and same-basename cases, fail/pass and skip/pass under the evidence contract, legacy-summary first-run policy, frozen-fallback decision, self-tests confined to `test_results_self_tmp`.
5. `remote-db-sync-to` / `remote-db-sync-from` / `remote-db-dl-from` opt-inc wiring + `"$@"` + DB-scoped dump source (empty/`new`) + DB ID on dump/restore ops + real restore path (clear blocks import) + `remote-exec` + two-DB fixture (direct action for empty slot; Make documented separately).

Step 2 must not be split so that hooks or ignore land before ownership protects maintained files and load rejects unowned definitions; ignore is not a separate step after ownership.
