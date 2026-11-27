# Mother `.gitignore`: `/data` parent rule and trackable exceptions

Status: draft

Reconcile the mother ignore rules with commit `007a0c5`, which already ignores
generated data under `/data` but also prunes the parent so nested README
exceptions never take effect. Inventory trackable paths from
`git ls-files data`, verify maintained paths and generated neighbors with
`git check-ignore --no-index`, and land with remote ownership as **one**
criterion. This plan describes proposed work; it does not claim implementation
or authorize commit.

**Authority:** [docs/instance/review.md](../../../instance/review.md) owns
remediation decisions (what and why). This plan owns steps and acceptance for
the mother ignore shape. Background inventory also appears in
[24-restore-active-data-ignore-rules.md](24-restore-active-data-ignore-rules.md);
the review wins on scope.

**Out of scope:** other ASC project instance compatibility (install-time
`.gitignore` propagation, upgrade leftovers such as `data/db-dumps/`, repair of
foreign project ignore files).

## Current state (`007a0c5` and later)

The mother `.gitignore` contains:

```gitignore
# /data contents are gitignored by default.
/data
```

followed by nested `!/data/…` re-opens and README exceptions (e.g.
`!/data/asc/README.md`, `!/data/log/README.md`).

A directory rule `/data` **prunes** the tree. Child negation patterns do not
restore trackability. In a Git fixture, replacing `/data` with `/data/*`
restored existing nested exceptions for `data/asc` and `data/cron` READMEs
while dumps and logs stayed ignored — but still **hid** already tracked paths
that the current rules never re-open, including local instance and host
READMEs, `data/doc` fixtures, and fonts.

So the earlier “restore missing producer exclusions” inventory is stale for
coverage of generated content: `/data` already ignores `data/logs/`,
`data/threads/`, `data/db/dumps/`, `data/private/`, `data/files/`, and generated
remote paths. What remains broken is **maintained-path exceptions**, including
READMEs that the file already lists **and** tracked paths that only
`git ls-files data` surfaces.

Generated remote ownership and lifecycle still belong in
[27-remote-lifecycle-ownership.md](27-remote-lifecycle-ownership.md). This plan
owns the mother ignore shape and which paths under `data/` must stay trackable.

## Inventory (source of truth for exceptions)

Use **`git ls-files data`** as the inventory of paths that must remain
trackable after the parent-rule fix (today: 49 paths in this tree, including
`data/asc/README.md`, `data/cron/README.md`, `data/instance/local/README.md`,
`data/host/local/README.md`, `data/doc/fixtures/…`, `data/doc/fonts/…`, and
other listed READMEs). Do not invent the exception list only from the existing
`.gitignore` comments.

For each inventoried path, and for representative generated neighbors (e.g.
`data/instance/remote/<id>.sh`, `data/instance/remote_ids.sh`, a log file, a
dump, a thread file), verify with `git check-ignore --no-index -v`.

## Work

1. Change the parent rule from `/data` to `/data/*` (or an equivalent that does
   not prune children), then keep or adjust nested ignore / exception pairs so
   generated producers stay ignored.
2. **Record** every path from `git ls-files data` that must remain trackable,
   and add the missing `!` / re-open rules so the parent-rule fix does not hide
   them. Explicit groups to cover (not optional):
   - existing README exceptions under re-opened trees (`data/asc`, `data/cron`,
     `data/log` / active `data/logs`, dumps, test trees, etc.)
   - `data/instance/local/` (and any other tracked instance paths)
   - `data/host/local/` (and any other tracked host paths)
   - maintained non-generated files under `data/instance/remote/` (at least
     `README.md` when present; same ownership boundary as the remote lifecycle
     plan)
   - `data/doc/fixtures/` and `data/doc/fonts/` (and any other tracked `data/doc`
     paths)
3. Keep intentional README exceptions under re-opened trees actually effective.
4. Align singular vs plural producer paths with what this tree still writes
   (`data/logs`, `data/threads`, `data/db/dumps`) when re-opening parents.
5. Do not design install-time propagation into other projects.

## Acceptance

Use an isolated Git fixture and `git check-ignore --no-index -v` (not only
`check-ignore` against the index):

- Every path from `git ls-files data` in this tree is **not** ignored after the
  change (or is explicitly documented if intentionally dropped from tracking —
  default is keep all current tracked `data/` paths).
- Representative generated / producer neighbors remain ignored: e.g. a log file
  under the active log dir, a thread file, a compressed dump under
  `data/db/dumps/`, a private-file path, a Moodle `data/files/…` path, a
  generated `data/instance/remote/<id>.sh`, and remote metadata such as
  `data/instance/remote_ids.sh`.
- Document the final parent rule (`/data/*` or equivalent) and the recorded
  trackable list in the plan outcome or a short note beside the `.gitignore`
  change.

## Order

**One landing criterion** with
[27-remote-lifecycle-ownership.md](27-remote-lifecycle-ownership.md): do not
treat ignore as a follow-up step after ownership. Ownership, load checks, hook
relocation, failure propagation, ID-list accuracy, and this ignore parent-rule
/ trackable inventory land together so maintained remote README exceptions and
generated remote ignores agree. Independent of cron, archive, and globals
fixture work.
