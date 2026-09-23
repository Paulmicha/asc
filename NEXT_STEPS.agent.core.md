# NEXT_STEPS.agent

Generated 2026-09-22 by `asc/doc/next_steps.sh`. Project-docroot hook data, rung 4, same lookup model as `env.yml`. Dry-run returns this path; the file is not sourced.

```sh
next_steps_actor=agent
hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' -v 'next_steps_actor' -r
```

Discussion is `NEXT_STEPS.md`. Go-ahead is the gates file `hook_ms` returns (`hook_ms 'dry-run' -s 'doc' -a 'gates' -c 'yml' -v 'STACK_VERSION HOST_TYPE INSTANCE_TYPE' -r`). A row here may start only when that file sets its `go` to yes. This entry point writes neither file.

Lanes: **sequential** waits on the row above; **parallel** does not wait on the sequential chain or on other parallel rows.

## Sequential

Start at row 1. Leave the next row until this one is done.

_None this hour._

## Sequential, after the row above

Same chain, later. An "After" or "Optional" line waits.

### 1. `changelog/2026/09/11-lazy-opt-inc-and-entry-point-extraction.md`

Status: split — stamp prerequisite is done ([11-bootstrap-cache-layout-and-invalidation.md](./11-bootstrap-cache-layout-and-invalidation.md)). Do not implement this...

- [ ] Optional: measure wrap vs action bootstrap cost; only then consider a thinner `call_wrap` bootstrap.


## Parallel

Independent of the sequential chain. Still wait for approval in NEXT_STEPS.md.

### 1. `changelog/2026/07/31-subshell-printf-v-candidates.md`

Status: partial implementation — waves 1–8 done (2026-09-22). `eval` / `f_yaml_parse` design written (2026-09-22; implementation still needs a later gates row)....

- [ ] Category G: bootstrap `global … "$(f_*)"` literals


## Awaiting human approval

Open changelog notes that are not an implementation go-ahead. Discussion belongs in `NEXT_STEPS.md`.

- `changelog/2026/07/24-yml-structure.md` — plan / accepted for discussion (2026-09-22 gates). Still not implementation go-ahead for loaders or schema merge.
- `changelog/2026/07/31-nameref-clarity-candidates.md` — inventory / plan (docs only — no code changes). Reviewed 2026-07-31: suffix renames already landed via array-dict plan; counts/caveats refreshed.
- `changelog/2026/09/10-begin-entity-system-with-remote-instances.md` — plan (corrected: contracts vs types; discovery → cache → load). Tasks 1–7 done (`f_entity_load` cache path, discover, generate, `post_init.hook.sh`, type-aware...
- `changelog/2026/09/20-builder-kernel-subject.md` — proposed, later. No code. Not in the 2026-09-19 lazy-include order. Not in the [meadows review loop](./20-meadows-plan-review-feedback-loop.md). Prefer after...
- `changelog/2026/09/20-host-scan-project-instances.md` — proposed, later. No code. Not in the 2026-09-19 lazy-include order. Not in the [meadows review loop](./20-meadows-plan-review-feedback-loop.md). Prefer after...
- `changelog/2026/09/22-agent-llm-entry-point.md` — proposal — plan / review (not implemented). Docs only until `gates.yml` go.
- `changelog/2026/09/22-gitflow.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/22-make-ds-literal.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/22-make-ds.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/22-make-generate.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/22-make-generate-string.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/22-workflow.md` — plan / review (not an implementation go-ahead)
- `changelog/2026/09/22-xdg-state-store.md` — plan / review (not an implementation go-ahead)

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

