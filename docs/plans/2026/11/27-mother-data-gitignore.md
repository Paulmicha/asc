# Mother `.gitignore`: `/data` parent rule and trackable exceptions

Status: draft

Reconcile the mother ignore rules with commit `007a0c5`, which already ignores
generated data under `/data` but also prunes the parent so nested README
exceptions never take effect. This plan describes proposed work; it does not
claim implementation or authorize commit.

**Authority:** [docs/instance/review.md](../../../instance/review.md) is the
source of truth. Background inventory also appears in
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
restored existing nested exceptions while dumps and logs stayed ignored.

So the earlier “restore missing producer exclusions” inventory is stale for
coverage of generated content: `/data` already ignores `data/logs/`,
`data/threads/`, `data/db/dumps/`, `data/private/`, `data/files/`, and generated
remote paths. What remains broken is **maintained-path exceptions**, including
READMEs that the file already lists.

Generated remote ownership and lifecycle still belong in
[27-remote-lifecycle-ownership.md](27-remote-lifecycle-ownership.md). This plan
owns the mother ignore shape and which paths under `data/` must stay trackable.

## Work

1. Change the parent rule from `/data` to `/data/*` (or an equivalent that does
   not prune children), then keep or adjust nested ignore / exception pairs so
   generated producers stay ignored.
2. **Record** which maintained paths under `data/instance` and `data/doc` must
   remain trackable (and any other intentional exceptions). Candidates to decide
   and write down explicitly (not an automatic claim they are all tracked today):
   - `data/instance/` README(s) and maintained local declarations under
     `data/instance/local/`
   - maintained non-generated files under `data/instance/remote/` (at least
     `README.md`; same ownership boundary as the remote lifecycle plan)
   - maintained paths under `data/doc/` (e.g. fixtures/fonts called out in the
     README data-dir table), if they are intended to be versioned here
3. Keep intentional README exceptions under re-opened trees (`data/asc`,
   `data/log` / active `data/logs`, `data/thread` / active `data/threads`,
   `data/db/dumps/local`, test trees, etc.) actually effective.
4. Align singular vs plural producer paths with what this tree still writes
   (`data/logs`, `data/threads`, `data/db/dumps`) when re-opening parents.
5. Do not design install-time propagation into other projects.

## Acceptance

Use an isolated Git fixture and `git check-ignore --no-index -v` (not only
`check-ignore` against the index):

- Representative generated / producer paths remain ignored: e.g. a log file
  under the active log dir, a thread file, a compressed dump under
  `data/db/dumps/`, a private-file path, a Moodle `data/files/…` path, a
  generated `data/instance/remote/<id>.sh`, and remote metadata such as
  `data/instance/remote_ids.sh`.
- Each **recorded** maintained path under `data/instance` and `data/doc` (and
  listed README exceptions) is **not** ignored.
- Document the final parent rule (`/data/*` or equivalent) and the recorded
  trackable list in the plan outcome or a short note beside the `.gitignore`
  change.

## Order

Land with or immediately after generated-remote ownership decisions in
[27-remote-lifecycle-ownership.md](27-remote-lifecycle-ownership.md) so
maintained remote README exceptions and generated remote ignores agree.
Independent of cron, archive, and globals fixture work.
