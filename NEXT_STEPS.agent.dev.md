# NEXT_STEPS.agent

Generated 2026-10-06 by `asc/doc/next_steps.sh`. Project-docroot hook data, rung 4, same lookup model as `env.yml`. Dry-run returns this path; the file is not sourced.

```sh
next_steps_actor=agent
hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' -v 'next_steps_actor STACK_VERSION HOST_TYPE INSTANCE_TYPE' -r
```

Discussion is the human next-steps file (`hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' -v 'STACK_VERSION HOST_TYPE INSTANCE_TYPE' -r`). Go-ahead is the gates file `hook_ms` returns (`hook_ms 'dry-run' -s 'doc' -a 'gates' -c 'yml' -v 'STACK_VERSION HOST_TYPE INSTANCE_TYPE' -r`). A row here may start only when that file sets its `go` to yes. This entry point writes neither file.

Lanes: **sequential** waits on the row above; **parallel** does not wait on the sequential chain or on other parallel rows.

## Sequential

Start at row 1. Leave the next row until this one is done.

### 1. `changelog/2026/09/30-asc-guidance-as-project-skills.md`

Status: Compatibility diff is in this work tree and is not published. Not a direction to run `core-upgrade`. Recorded-file checks and the `AGENTS.md` gate are open.

- [ ] `AGENTS.md` is copied only when absent, via the existing gates row. This note does not set `go`. The script still replaces an existing file on every run.
- [ ] Recorded-file checks, mother and home as separate cases, including an isolated run with the duplicate bodies absent, then again after live cleanup. The live duplicate bodies stay.


## Sequential, after the row above

Same chain, later. An "After" or "Optional" line waits.

### 1. `changelog/2026/09/20-host-scan-project-instances.md`

Status: Path amended 2026-09-25. Stub is on disk at `asc/host/instance/discover.sh`. Body is still `# TODO`. Not a go to fill it.

- [ ] After lazy-include: if `f_host_registry_*` left eager `host.inc.sh`, this script still works; if they moved, `.` the mirrored opt-inc (same path rule as the meadows file).


### 2. `changelog/2026/09/11-lazy-opt-inc-and-entry-point-extraction.md`

Status: split — stamp prerequisite is done ([11-bootstrap-cache-layout-and-invalidation.md](./11-bootstrap-cache-layout-and-invalidation.md)). Do not implement this...

- [ ] Optional: measure wrap vs action bootstrap cost; only then consider a thinner `call_wrap` bootstrap.


## Parallel

Independent of the sequential chain. Still wait for approval in the human next-steps file.

### 1. `changelog/2026/07/31-subshell-printf-v-candidates.md`

Status: partial implementation — waves 1–8 done (2026-09-22). `eval` / `f_yaml_parse` design written (2026-09-22; implementation still needs a later gates row)....

- [ ] Category G: bootstrap `global … "$(f_*)"` literals


## Awaiting human approval

Open changelog notes that are not an implementation go-ahead. Discussion belongs in the human next-steps file.

- `changelog/2026/07/24-yml-structure.md` — plan / accepted for discussion (2026-09-22 gates). Still not implementation go-ahead for loaders or schema merge.
- `changelog/2026/07/31-nameref-clarity-candidates.md` — inventory / plan (docs only — no code changes). Reviewed 2026-07-31: suffix renames already landed via array-dict plan; counts/caveats refreshed.
- `changelog/2026/09/10-begin-entity-system-with-remote-instances.md` — plan (corrected: contracts vs types; discovery → cache → load). Tasks 1–7 done (`f_entity_load` cache path, discover, generate, `post_init.hook.sh`, type-aware...
- `changelog/2026/09/20-builder-kernel-subject.md` — proposed, later. No code. Not in the 2026-09-19 lazy-include order. Not in the [meadows review loop](./20-meadows-plan-review-feedback-loop.md). Prefer after...
- `changelog/2026/09/22-agent-llm-entry-point.md` — proposal — plan / review (not implemented). Docs only until `gates.yml` go.
- `changelog/2026/09/22-gitflow.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/22-make-ds-literal.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/22-make-ds.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/22-make-generate.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/22-make-generate-string.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/22-workflow.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/23-host-asc-core-sync.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/25-concert-order.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/26-patterns-and-antipatterns.md` — plan / review. The split is chosen. Stubs are on disk. Bodies are not filled. Not an implementation go-ahead.
- `changelog/2026/09/27-agent-guidance-from-antipatterns.md` — plan / review. The split is chosen. The generation contract below is part of that choice. Nothing in this note is an implementation go-ahead.
- `changelog/2026/09/27-desktop-agent-terminal-reply.md` — plan / review. Discovery for Cursor, Codex, and Claude can proceed. Nothing here is an implementation go-ahead.
- `changelog/2026/09/28-agent-instructions-travel.md` — plan / review. Nothing in this note is an implementation go-ahead.
- `changelog/2026/10/02-reinit-performance.md` — plan / review (not an implementation go-ahead)

## Do not re-run

Status is implemented, done, shipped, or skipped. Open checkboxes in these files are historical.

- `changelog/2026/07/24-subject-asc-extensions.md`
- `changelog/2026/07/31-array-dict-naming-plan.md`
- `changelog/2026/09/04-pdf-generation-improvements.md`
- `changelog/2026/09/11-bootstrap-cache-layout-and-invalidation.md`
- `changelog/2026/09/12-subject-object-action-entry-points.md`
- `changelog/2026/09/17-pdf-graphviz-support.md`
- `changelog/2026/09/20-meadows-plan-review-feedback-loop.md`
- `changelog/2026/09/22-deprecate-subject-asc-extensions.md`
- `changelog/2026/09/22-gates-prune-approved-work.md`
- `changelog/2026/09/26-app-prefix-inventory.md`

