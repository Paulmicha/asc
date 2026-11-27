# Remote lifecycle: ownership, hooks, ID list, ignore coordination

Status: draft

Make remote definition cleanup safe, restore discoverable lifecycle hooks, keep
the remote ID list accurate, apply ownership on load, propagate lifecycle
failures on both hook-cache paths, and coordinate with mother ignore rules so
generated remotes stay ignored while maintained files can remain trackable.
Land as **one coherent change set** with
[27-mother-data-gitignore.md](27-mother-data-gitignore.md). This plan describes
proposed work; it does not claim implementation or authorize commit.

**Authority:** [docs/instance/review.md](../../../instance/review.md) owns
remediation decisions (what and why). This plan owns steps and acceptance for
the remote lifecycle work. Background only (not authority over those decisions
or this plan’s steps):
[24-deprecate-entity-related-abstractions.md](24-deprecate-entity-related-abstractions.md),
[24-restore-active-data-ignore-rules.md](24-restore-active-data-ignore-rules.md).
Still-relevant checks from the older remote plan that this plan must carry
forward are listed under **Carried checks** below.

**Out of scope:** compatibility with other ASC project instances (upgrade
migration of foreign checkouts, install-time `.gitignore` propagation, retained
legacy entity cache paths for other projects).

## Why one change set

Restoring lifecycle hooks alone would let `reinit` call the unsafe purge again
and delete maintained files under `data/instance/remote`. Ownership checks
(including load), hook relocation, ID-list accuracy, failure propagation on
the public refresh path **and** both hook-cache paths, and ignore coordination
must land together. Safe cleanup first; hooks restored in the same land. The
mother ignore parent-rule fix is part of the same landing criterion (see Order).

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
4. **Refresh failures swallowed at the action.** `remote-definitions-update`
   and the post-init hook call `f_remote_instances_setup` then print `done` and
   exit zero even when setup fails (reproduced with setup stubbed to return 7).
5. **Hook-cache paths also swallow abort.** Returning nonzero from a relocated
   hook body is insufficient. On a cache miss, `hook` continues sourcing later
   matches and then writes the lookup cache. On a cache hit, a later successful
   hook in the same call can mask an earlier failure. A fixture with `return 7`
   followed by a successful hook returned zero on both cold and warm lookup.
6. **Load ignores ownership and stale state.** `f_remote_instance_load` sources
   any matching `data/instance/remote/<id>.sh`. In a fixture, loading remote A
   then requesting a missing remote left A’s configuration active; the exec
   wrapper selected A in debug mode and returned zero. Separately, loading
   valid B after valid A can inherit A’s optional exports when the generator
   omitted empty fields from B’s file (e.g. B kept A’s docroot).
7. **Setup order.** `f_remote_instances_setup` purges before parsing the YAML
   match or checking destinations, so a later parse/write failure can leave the
   directory emptied.
8. **Ignore parent prune (post-`007a0c5`).** `/data` already ignores generated
   remotes and metadata, but also prunes so README exceptions never apply.
   Parent-rule fix and trackable-path recording live in
   [27-mother-data-gitignore.md](27-mother-data-gitignore.md); this plan must
   agree on which `data/instance/remote` paths are maintained vs generated.

## Work

### Ownership

1. Define an explicit **generated-file ownership** rule before any purge,
   overwrite, removal, **or load**. Filename or `.sh` extension alone is
   insufficient in a shared directory.
2. Apply that rule in generation, enumeration, `remote-instance-remove`, purge,
   uninit, **and `f_remote_instance_load`**. Reject unowned definitions on load
   (nonzero; do not source them).
3. If ownership cannot be proven, preserve the file and report a conflict; do
   not overwrite a pre-existing path that maps to a declared ID.
4. Keep the ID-list cache and any parsed intermediate in ASC-owned generated
   locations that cannot be enumerated as remotes.

### Load failure and stale configuration

5. Make a failed or missing load return nonzero. **Audit every caller** of
   `f_remote_instance_load` (and helpers that load then continue on empty SSH /
   stale exports) so each stops on load failure instead of continuing with a
   previously loaded remote’s exports. Implementation work is the full caller
   audit; regression fixtures use representative cases. Callers to cover in the
   audit include at least:
   - `f_remote_exec_wrapper`
   - `f_remote_upload` / `f_remote_download`
   - `f_remote_definition_get_key` / token-replacement paths that read loaded
     exports (the accessor can return values from the previously loaded remote
     when the new load fails or is skipped)
   - DB consumers under `remote_asc` that load then act
   - other in-tree action scripts that call load directly (e.g. ssh key auth,
     files sync)
6. Fixture contract (failure): load remote A, then attempt a missing or
   unowned remote B in the **same shell**; assert B’s load fails.
   Representative regression cases must include **exec** and
   **`f_remote_definition_get_key`** (or an equivalent definition accessor
   path) so a rejected load cannot return A’s values or contact a remote as A.
7. **Successful A then successful B in the same shell.** The generator skips
   empty fields, so B’s generated file may omit keys that A exported. Define
   which `REMOTE_INSTANCE_*` values a successful load **replaces or clears**
   when the new definition does not set them. Verify with definitions produced
   by the **real generator** (not hand-written stubs alone): e.g. A with
   `docroot: /srv/alpha`, B with no docroot — after loading B, B must not keep
   A’s docroot unless the contract explicitly inherits it (today B loaded with
   its own ID and A’s docroot).

### Setup order and post-failure availability

8. Do not purge before the YAML match is selected and destination conflicts are
   checked. Define and document what remains available after a failed refresh:
   - which generated definitions (if any) may remain;
   - that the ID-list cache must not present a partial or stale set as current;
   - that public entry points must not print success/`done` for that failure.
9. Propagate nonzero status from `f_remote_instances_setup` (and underlying
   purge/generate/write failures) through:
   - `remote-definitions-update`
   - the `post_init` hook implementation
   - `reinit` / init when that hook runs
10. Do not print success/`done` when setup failed.

### Hook abort on both cache paths

11. Relocated lifecycle hooks that must abort their action use the existing
    builder pattern for a hook that must stop the action:
    `… || exit $?` (see `asc/extensions/builder/subject/core.hook.tpl.sh`).
    Returning nonzero alone is not the contract. The builder exit pattern
    already stops both cache paths when used; a shared dispatcher change in
    `asc/core/hook.manual-inc.sh` is **conditional on a demonstrated need**
    after hooks use that pattern (do not rewrite the dispatcher by default).
12. Prove abort on **cold and warm** lookup separately:
    - **Cold:** public `reinit` (or init with an empty hook cache) is fine —
      `asc/instance/reinit.sh` clears `data/asc/cache` before launching init,
      so repeating public `reinit` cannot prove a cache hit.
    - **Warm:** use **direct `init`** or a **dispatcher fixture** that leaves
      the hook lookup cache in place and verifies a cache hit before the
      aborting hook runs. Do not claim warm coverage from two `reinit` calls.
13. Include **uninit cleanup failure** in the same contract: a failing uninit
    hook must yield nonzero on cold and warm lookup (warm via a path that can
    stay warm), with no false success.

### Hooks (discovery)

14. Move the three lifecycle hooks to the extension’s `instance` subject:
    - `asc/extensions/remote/instance/post_init.hook.sh`
    - `asc/extensions/remote/instance/ensure_dirs_exist.hook.sh`
    - `asc/extensions/remote/instance/uninit.hook.sh`
15. Keep the same hook call contracts. Update `@see` / examples.
16. Verify discovery with the real lookup, e.g. `make hook-debug p:post a:init`,
    and matching calls for `ensure_dirs_exist` and uninit.

### ID list

17. Enumerate **generated definitions only**.
18. Invalidate the ID-list cache on remove and on regeneration.

### Ignore coordination

19. Treat generated per-ID definitions and remote metadata as generated for
    both ownership and ignore purposes. Coordinate with
    [27-mother-data-gitignore.md](27-mother-data-gitignore.md) so the parent
    `/data` → `/data/*` (or equivalent) fix leaves maintained
    `data/instance/remote` files trackable when intended. Blanket `*.sh` under
    that directory remains too wide.

## Carried checks (from older remote plan)

These remain required acceptance even though that plan is background only:

- YAML selection: host/instance-specific variants **and** unqualified fallback
  still produce the expected generated definitions and exports.
- Generate twice; assert ID set, shell syntax, effective values, includes,
  override precedence, defaults, and exported `REMOTE_INSTANCE_*` variables.
- Warm the ID-list cache, remove a declaration, regenerate; deleted IDs are
  absent from enumeration and cannot be loaded.
- Missing declarations / missing IDs / empty set behave as documented; a missing
  declaration is an empty configuration, not a reason to retain obsolete
  generated definitions after a successful refresh.

## Acceptance / fixture

- Seed a maintained README and an unrelated sibling; run refresh/purge twice;
  those files survive; only owned generated definitions are removed.
- Same-ID collision: maintained file whose name matches a declared remote ID;
  refresh **reports failure** and **neither deletes nor overwrites** that file.
- **Public action:** `remote-definitions-update` exits **nonzero**, does not
  print a success/`done` line for that failure, and preserves the maintained
  collision file (and other non-owned siblings).
- **Cold `reinit` / post-init:** with `remote` enabled, the same collision (or
  a setup stub returning nonzero) yields a **nonzero** reinit status and
  preserves the maintained file.
- **Warm abort:** the same aborting hook (builder `|| exit $?`), followed by a
  successful peer when relevant, yields nonzero on a **verified cache hit**
  via direct init or a dispatcher fixture — not via a second `reinit`.
- **Uninit:** cleanup failure (stub or real) yields nonzero on cold and warm
  lookup (warm as above); no success/`done` for that failure.
- Load failure: unowned `<id>.sh` is rejected; load remote A then missing or
  unowned B in the same shell fails. Regression fixtures cover exec and the
  definition accessor so A’s values are not returned after B’s rejected load.
  The caller audit list in Work item 5 is implemented even where not every
  caller has its own fixture.
- Load success A then B: with real generated definitions, after loading B the
  exported `REMOTE_INSTANCE_*` set matches the replace/clear contract from
  Work item 7 (no silent inheritance of A’s optional fields such as docroot
  unless the contract says so).
- After a failed refresh, the documented post-failure availability holds (no
  false current ID list; no success presentation of a partial/stale set).
- After remove/regenerate, deleted IDs are absent from enumeration and cannot
  be loaded; cache is not stale.
- YAML variant fallback and double-generate checks from **Carried checks**
  pass.
- With `remote` enabled, `make hook-debug p:post a:init` (and the other
  lifecycle lookups) finds the moved hooks; init/reinit/uninit run them without
  deleting non-generated content when setup succeeds.
- Ignore checks for generated vs maintained remote paths are verified under the
  mother-data-gitignore parent-rule fix (`git check-ignore --no-index`), using
  the same landing criterion as that plan.

## Order

After [27-globals-test-fixture-synonym.md](27-globals-test-fixture-synonym.md).
**One landing criterion** with
[27-mother-data-gitignore.md](27-mother-data-gitignore.md): ownership, load
checks, hook relocation, failure propagation (action + both cache paths),
ID-list accuracy, and the ignore parent-rule / trackable inventory must land
together. Before relying on remote DB actions in
[27-remote-db-action-loading.md](27-remote-db-action-loading.md) if those
tests need a working remote lifecycle.
