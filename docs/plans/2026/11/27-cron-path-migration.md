# Complete the cron path migration

Status: draft

Finish moving cron loading, discovery, contrib, tests, host hooks, and the
`cron-run` entry point onto the `cron` / `*.cron.yml` layout in this tree. This
plan describes proposed work; it does not claim implementation or authorize
commit.

**Authority:** [docs/instance/review.md](../../../instance/review.md) is the
source of truth.

**Out of scope:** dual-suffix / legacy `*.crontab.yml` compatibility for
job files left in other ASC project instances.

## Observed breaks (reviewed revision `5dc602b`)

1. **Optional include location.** Pivot `cron-settings` is
   `$ext/$subject/$action.sh` at `asc/extensions/cron/cron/settings.sh`.
   Bootstrap looks for subject opt-inc `…/cron/cron.opt-inc.sh`; helpers still
   live at `asc/extensions/cron/cron.opt-inc.sh` (extension root).
2. **Stale base template + discovery.** `f_cron_load_base_templates` still opens
   `asc/extensions/crontab/base_settings.crontab.yml`. Base template is
   `asc/extensions/cron/base_settings.cron.yml`. Discovery still walks
   `*.crontab.yml`; shipped jobs are `*.cron.yml`:
   - `log/rotate.at-03h00.cron.yml` → log-rotate
   - `thread/monitor.every-1m.cron.yml` → thread-monitor
3. **Downstream callers on the old tree:**
   - `scripts/asc/contrib/asc/crontab/instance/post_init.hook.sh`
   - `test_f_cron_load_base_templates` in `asc/test/core/yml.test.sh`
   - `asc/extensions/cron/cron/run.debian-13.hook.sh`
4. **`cron-run` diagnostic still names `.crontab.yml`.**
   `asc/extensions/cron/cron/run.sh` tells users to add a
   `{action}.{preset}.crontab.yml` beside the entry script. The current job
   file shape is `$ext/$subject/$action.$preset.cron.yml`.

## Work

1. Wire the opt-inc so `cron-settings` and sibling actions source it.
2. Point the base template at `asc/extensions/cron/base_settings.cron.yml`.
3. Discover `*.cron.yml` only (no dual-suffix compatibility layer). Use the
   naming `$ext/$subject/$action.$preset.cron.yml` in docs and diagnostics.
4. Refresh the contrib post-init include, the YAML test, and the Debian 13 run
   hook together with loading and discovery.
5. Update the `cron-run` missing-job diagnostic to name
   `$ext/$subject/$action.$preset.cron.yml` (not `.crontab.yml`).

## Acceptance

- With `cron` enabled, `cron-settings` succeeds.
- Generated entries exist for log-rotate and thread-monitor.
- YAML test loads base templates from the new path/include.
- Contrib post-init and Debian 13 run hook source the current cron tree.
- `cron-run` diagnostic text uses the `.cron.yml` job shape above.
- A harmless `cron-run` fixture selects the Debian 13 run hook so acceptance
  covers **dispatch** as well as generation (not generation alone).
- No requirement to accept or merge leftover `*.crontab.yml` job files.

## Order

Independent of remote ownership and archive work; after globals fixture if
running full `make test-core` as the gate.
