# README: proposed conventions labeled as current

Status: draft

Align the mother README so examples and claims that are still proposed are not
written as current behavior. This plan describes proposed documentation work; it
does not claim the README rewrite is complete or authorize commit.

**Authority for remediation intent:** manual modifications from the README
reviews (2026-11-27) and accepted `&lt;proposal-2026-11-27&gt;` blocks in
`README.md`. Code remediation remains in
[docs/instance/review.md](../../../instance/review.md) and the other `27-*-`
plans dated the same day.

**Out of scope:** other ASC project instance compatibility; implementing
unimplemented DSL/hook conventions just to make a README example true.

## Context

Fourteen commits touched the main README between 24–27 Nov. Several passages
present proposed conventions as if they already run. Scratch checks covered
YAML, DSL, TOC, and Git ignore.

## Landed or in-tree (this pass)

- Working remote `remote_instances` YAML example under Instance(s).
- DSL section leads with `asc/dsl.sh` / `ASC_DS_EXPR`.
- Filename embedding marked proposed.
- Overrides = file swap; branching/forking under Workflow.
- TOC hrefs use GitHub slugs; `u_md_slug` strips Markdown emphasis, keeps
  literal underscores (e.g. `NEXT_STEPS`), and keeps double hyphens
  (`md_toc` covers Plans, Next Steps, and `_Entry points_` emphasis).
- Remote refresh prose matches `f_remote_instances_setup`: owned definitions
  (non-symlink regular file with the generated marker) are replaced, other
  files stay, and an unowned collision aborts before the purge while
  `data/instance/remote_refresh_failed` remains.
- Unsupported DSL sketches labeled where they appear (options, `;` / parallel /
  pipe, Variables `v-`, Functions `[]`, Conditional `++`, Redirecting,
  Iterations). Arguments example uses working `slug(…)` pivot.
- Extension inventory: `remote_asc` (not `remote_instance`); Workflow no longer
  cites the removed `rules` extension; lazy-include example paths updated.
- Test results noted as Git-ignored; data-dir table marks proposed
  host-qualified / nested layouts vs flat generated remotes; `data/logs` noted.
- Diátaxis kept for reader intent; proposal links
  [documentation specification](../../../specs/asc/documentation.md) for
  document homes.

## Remaining / verify

1. Confirm lazy-include table wording once `remote-db-*` subject opt-inc wiring
   lands ([27-remote-db-action-loading.md](27-remote-db-action-loading.md)).
2. Re-read DSL example subsections for any unmarked unsupported samples
   (variables-in-filename, etc.).
3. Fourth collapsed inline comment from the latest paste (body not provided) —
   absorb if distinct from the items above.
4. Relative link check: this file’s DSL spec href must be
   `../../../specs/asc/dsl.md` (not `../../specs/…`).

## Earlier P2 titles (first README pass)

### Working instance YAML

Use a working `remote_instances` shape; do not present stack `front`/`api`
trees as that contract.

### DSL working interface

Lead with the working carrier; keep Make pivot synonyms secondary.

### Filename-safety

Qualify absolute multi-OS filename-embedding claims as proposed.

## Three findings previously missing from this plan

### Extension names and loading examples

- Inventory must not name `remote_instance`; use `remote_asc` (and other real
  dirs under `asc/extensions/`).
- Lazy-include examples must not use deleted
  `asc/extensions/remote_instance/…` paths.
- Workflow must not point at the removed `rules` extension.

### Active and proposed data paths

- Logs still go to `data/logs` (and threads to `data/threads`).
- Test results under `data/test/result` are Git-ignored.
- Host-qualified remote YAML and report/frozen paths in the data-dir table are
  **proposed layouts**; flat `data/instance/remote/<id>.sh` is current
  generated output.

### Documentation placement

- Keep Diátaxis for reader intent (tutorial / how-to / reference / explanation).
- Link [docs/specs/asc/documentation.md](../../../specs/asc/documentation.md)
  for where to put plans, specs, decisions, guides, and ideas. Do not require
  a parallel `docs/tutorials` tree unless a later decision says so.

## Acceptance

- Regeneration via `asc/doc/md/toc.sh` keeps
  `#plans--changes-implementation-steps-execution-plans` and
  `#next_steps--priorities`.
- README does not present deferred DSL combinators or filename embedding as
  current.
- Extension and include examples name paths that exist (or are clearly labeled
  as intended wiring).
- Data-dir and test-result prose distinguish active, ignored, and proposed
  layouts.
- Documentation section points at the ASC documentation specification for
  homes.
- Mother README conceptual edits use escaped proposal delimiters unless a human
  authorizes a direct rewrite of a given passage.
