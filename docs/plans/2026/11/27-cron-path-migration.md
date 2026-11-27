# Complete the cron path migration

Status: completed

Finish moving cron loading, discovery, contrib, tests, host hooks, and the
`cron-run` entry point onto the `cron` / `*.cron.yml` layout in this tree, with
discovery limited to **enabled** extensions and subjects, defined duplicate-job
handling, and normal `hook_ms` dispatch (not dry-run lookup plus manual
sourcing). The outcome is recorded below.

**Authority:** [docs/instance/review.md](../../../instance/review.md) owns
remediation decisions (what and why). This plan owns steps and acceptance for
the cron migration.

**Out of scope:** dual-suffix / legacy `*.crontab.yml` compatibility for
job files left in other ASC project instances.

## Observed breaks (reviewed revision `5dc602b`)

1. **Optional include location.** Pivot `cron-settings` is
   `$ext/$subject/$action.sh` at `asc/extensions/cron/cron/settings.sh`.
   Bootstrap looks for subject opt-inc `…/cron/cron.opt-inc.sh`; helpers still
   live at `asc/extensions/cron/cron.opt-inc.sh` (extension root).
2. **Stale base template + discovery suffix.** `f_cron_load_base_templates`
   still opens `asc/extensions/crontab/base_settings.crontab.yml`. Base
   template is `asc/extensions/cron/base_settings.cron.yml`. Discovery still
   walks `*.crontab.yml`; shipped jobs are `*.cron.yml`:
   - `log/rotate.at-03h00.cron.yml` → log-rotate
   - `thread/monitor.every-1m.cron.yml` → thread-monitor
3. **Discovery ignores enabled inventory.** With only the path and suffix
   changes applied in a fixture, `cron-settings` accepted a job from an
   **explicitly disabled** extension, overwrote the shipped log-rotate
   definition, and added log-rotate twice to the generated list. It also
   **missed** an enabled contrib job. Globbing `asc/extensions/**` and
   `scripts/asc/extend/**` is not enough.
4. **Dispatch bypasses overrides.** `cron-run` uses `hook_ms 'dry-run'` then
   manually sources `$most_specific_match`. That skips normal hook dispatch
   (overrides, hook-local includes, cache abort behavior). The Debian 13 hook
   currently delegates the same behavior as the default via a stale
   `crontab` path.
5. **Downstream callers on the old tree:**
   - `scripts/asc/contrib/asc/crontab/instance/post_init.hook.sh`
   - `test_f_cron_load_base_templates` in `asc/test/core/yml.test.sh`
   - `asc/extensions/cron/cron/run.debian-13.hook.sh`
6. **`cron-run` diagnostic still names `.crontab.yml`.**

## Work

1. Wire the opt-inc so `cron-settings` and sibling actions source it.
2. Point the base template at `asc/extensions/cron/base_settings.cron.yml`.
3. Discover `*.cron.yml` only (no dual-suffix compatibility layer). Use the
   naming `$ext/$subject/$action.$preset.cron.yml` in docs and diagnostics.
4. **Restrict discovery to ASC’s enabled extension and subject inventory.** Do
   not pick up jobs from disabled extensions. Include enabled contrib /
   extend paths that are part of that inventory. Preserve the hook-backed
   thread-monitor job when `thread` (or its owning extension) remains enabled.
5. **Define duplicate-job handling by generated entry key.** Different presets
   can still write the same output file (`data/asc/cron/${entry}.sh`). Detect
   duplicates on that **entry key** across sources and presets. **Validate
   before replacing** existing generated definitions: a bad-preset (or other
   failing) job must return nonzero **without** removing the previous good
   generated job first. Overwriting a shipped definition silently and listing
   it twice is not acceptable.
6. Refresh the contrib post-init include, the YAML test, and the Debian 13 run
   hook together with loading and discovery. Debian 13 may keep “same behavior
   as default” only after it sources the current cron tree and participates in
   normal dispatch.
7. Update the `cron-run` missing-job diagnostic to name
   `$ext/$subject/$action.$preset.cron.yml` (not `.crontab.yml`).
8. **Dispatch via normal `hook_ms`** (not dry-run lookup followed by manual
   `. "$most_specific_match"`). Acceptance must assert **which implementation
   ran** (default vs Debian 13 vs a fixture override), not only that some file
   was sourced.
9. **Preserve the no-runner failure.** `hook_ms` returns zero with an empty
   match. Today `cron-run` explicitly fails when no run-hook implementation
   exists after the dry-run lookup. Keep an equivalent explicit check when
   switching to normal `hook_ms`, and exercise it alongside the successful
   dispatch fixture.
10. **Post-init failure propagation.** The contrib post-init hook must use the
    lifecycle abort pattern (`… || exit $?`) so failed generation does not
    proceed to host sync when `ASC_CRON_SYNC_ON_INIT=true`, and a failed sync
    does not print `done` / exit zero. Today the hook calls
    `f_cron_settings_setup` then optionally `f_cron_sync` without checking
    status, then always prints done.

## Acceptance

- With `cron` enabled, `cron-settings` succeeds.
- Generated entries exist for log-rotate and thread-monitor when their owning
  extensions/subjects are enabled; the thread-monitor hook-backed job is
  preserved under that condition.
- A job file under an **explicitly disabled** extension is **not** accepted,
  does not overwrite a shipped definition, and does not appear twice in the
  generated list.
- An enabled contrib / extend job that matches the inventory **is** included.
- Duplicate detection by **generated entry key** (across different presets) is
  enforced; a bad-preset fixture returns nonzero and **leaves** the previous
  generated job in place (validate before replace).
- YAML test loads base templates from the new path/include.
- Contrib post-init and Debian 13 run hook source the current cron tree.
- **Post-init fixture** (with `ASC_CRON_SYNC_ON_INIT=true`): generation stubbed
  to fail must **not** reach host sync, must not print success/`done`, and must
  exit nonzero; sync stubbed to fail (generation ok) must likewise propagate
  nonzero with no false `done`.
- `cron-run` diagnostic text uses the `.cron.yml` job shape above.
- A harmless `cron-run` fixture uses **normal `hook_ms` dispatch** and asserts
  which run-hook implementation executed (including a Debian 13 selection when
  that variant is active). Manual sourcing after dry-run lookup is not the
  acceptance path.
- A fixture with **no** cron run-hook match still exits **nonzero** (empty
  `hook_ms` match alone must not look like success).
- No requirement to accept or merge leftover `*.crontab.yml` job files.

## Order

Independent of remote ownership and archive work; after globals fixture if
running full `make test-core` as the gate.

## Implementation and verification (27 November)

Cron discovery and dispatch use the current extension layout. Refresh uses a lock and staged generation; a failed installation rolls back, while an interrupted swap preserves recovery files and the lock for manual inspection. Isolated tests exercise discovery, duplicate and invalid jobs, dispatch, host-write failures, rollback and interruption; no host crontab was changed.

The integrated `make test-core` passed in an initialized disposable checkout with the remote extension enabled. This was local fixture acceptance; no live remote, database, or host crontab operation was performed.

### Backend boundary follow-up

The generic `cron-*` actions now dispatch to cron hook implementations. The
crontab-specific templates, generation, host operations and runner are owned by
`scripts/asc/contrib/asc/crontab`; the earlier core paths in this historical
plan no longer describe their locations. The backend now stores its generated
definitions under `data/asc/crontab`; old `data/asc/cron` files are not removed
by this migration. Generic job declarations use the
backend-neutral `defaults` include. Isolated fixtures exercise an alternative
backend, missing backend, crontab success and failure, and preservation of
unrelated crontab lines.
