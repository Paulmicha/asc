# Remote lifecycle: ownership, hooks, ID list, ignore coordination

Status: draft

Make remote definition cleanup safe, restore discoverable lifecycle hooks, keep
the remote ID list accurate, and coordinate with mother ignore rules so
generated remotes stay ignored while maintained files can remain trackable.
Land as **one coherent change set**. This plan describes proposed work; it does
not claim implementation or authorize commit.

**Authority:** [docs/instance/review.md](../../../instance/review.md) is the
source of truth. Where
[24-deprecate-entity-related-abstractions.md](24-deprecate-entity-related-abstractions.md)
or
[24-restore-active-data-ignore-rules.md](24-restore-active-data-ignore-rules.md)
disagree, the review wins.

**Out of scope:** compatibility with other ASC project instances (upgrade
migration of foreign checkouts, install-time `.gitignore` propagation, retained
legacy entity cache paths for other projects).

## Why one change set

Restoring lifecycle hooks alone would let `reinit` call the unsafe purge again
and delete maintained files under `data/instance/remote`. Ownership checks,
hook relocation, ID-list accuracy, failure propagation on the public refresh
path, and ignore coordination must land together. Safe cleanup first; hooks
restored in the same land.

## Observed breaks (reviewed revision `5dc602b`; ignore note as of `007a0c5`)

1. **Unsafe purge.** `f_remote_purge_instances` removes every direct file under
   `data/instance/remote` with no ownership filter.
2. **Hooks not discovered.** Implementations sit at
   `$ext/$subject/$object/*.hook.sh` under
   `asc/extensions/remote/remote/instance/` (`post_init`, `ensure_dirs_exist`,
   `uninit`). ASC does not discover object-dir hooks.
3. **ID list wrong.** `f_remote_get_instances` treats non-generated files (e.g.
   `README.md`) as remote IDs; `remote-instance-remove` leaves deleted IDs in
   `data/instance/remote_ids.sh`.
4. **Refresh failures swallowed.** `remote-definitions-update` and the post-init
   hook call `f_remote_instances_setup` then print `done` and exit zero even
   when setup fails (reproduced with setup stubbed to return 7).
5. **Ignore parent prune (post-`007a0c5`).** `/data` already ignores generated
   remotes and metadata, but also prunes so README exceptions never apply.
   Parent-rule fix and trackable-path recording live in
   [27-mother-data-gitignore.md](27-mother-data-gitignore.md); this plan must
   agree on which `data/instance/remote` paths are maintained vs generated.

## Work

### Ownership

1. Define an explicit **generated-file ownership** rule before any purge,
   overwrite, or removal. Filename or `.sh` extension alone is insufficient in
   a shared directory.
2. Apply that rule in generation, enumeration, `remote-instance-remove`, purge,
   and uninit.
3. If ownership cannot be proven, preserve the file and report a conflict; do
   not overwrite a pre-existing path that maps to a declared ID.
4. Keep the ID-list cache and any parsed intermediate in ASC-owned generated
   locations that cannot be enumerated as remotes.

### Failure propagation

5. Propagate nonzero status from `f_remote_instances_setup` (and underlying
   purge/generate failures) through:
   - `remote-definitions-update`
   - the `post_init` hook implementation
   - `reinit` / init when that hook runs
6. Do not print success/`done` when setup failed.

### Hooks

7. Move the three lifecycle hooks to the extension’s `instance` subject:
   - `asc/extensions/remote/instance/post_init.hook.sh`
   - `asc/extensions/remote/instance/ensure_dirs_exist.hook.sh`
   - `asc/extensions/remote/instance/uninit.hook.sh`
8. Keep the same hook call contracts. Update `@see` / examples.
9. Verify discovery with the real lookup, e.g. `make hook-debug p:post a:init`,
   and matching calls for `ensure_dirs_exist` and uninit.

### ID list

10. Enumerate **generated definitions only**.
11. Invalidate the ID-list cache on remove and on regeneration.

### Ignore coordination

12. Treat generated per-ID definitions and remote metadata as generated for
    both ownership and ignore purposes. Coordinate with
    [27-mother-data-gitignore.md](27-mother-data-gitignore.md) so the parent
    `/data` → `/data/*` (or equivalent) fix leaves maintained
    `data/instance/remote` files trackable when intended. Blanket `*.sh` under
    that directory remains too wide.

## Acceptance / fixture

- Seed a maintained README and an unrelated sibling; run refresh/purge twice;
  those files survive; only owned generated definitions are removed.
- Same-ID collision: maintained file whose name matches a declared remote ID;
  refresh **reports failure** and **neither deletes nor overwrites** that file.
- **Public action:** `remote-definitions-update` exits **nonzero**, does not
  print a success/`done` line for that failure, and preserves the maintained
  collision file (and other non-owned siblings).
- **`reinit` / post-init:** with `remote` enabled, the same collision (or a
  setup stub returning nonzero) yields a **nonzero** reinit/init status and
  preserves the maintained file.
- After remove/regenerate, deleted IDs are absent from enumeration and cannot
  be loaded; cache is not stale.
- With `remote` enabled, `make hook-debug p:post a:init` (and the other
  lifecycle lookups) finds the moved hooks; init/reinit/uninit run them without
  deleting non-generated content when setup succeeds.
- Ignore checks for generated vs maintained remote paths are verified under the
  mother-data-gitignore parent-rule fix (`git check-ignore --no-index`).

## Order

After [27-globals-test-fixture-synonym.md](27-globals-test-fixture-synonym.md).
With [27-mother-data-gitignore.md](27-mother-data-gitignore.md) for ignore
shape. Before relying on remote DB actions in
[27-remote-db-action-loading.md](27-remote-db-action-loading.md) if those
tests need a working remote lifecycle.
