# Workflow extension — close the loop

> **2026-09-25 concertation.** Order of work is [25-concert-order.md](./25-concert-order.md). Gates are a later agent surface. This printer is not the current design queue. The catalog pivot is `host-instance-discover`.

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | Design of the core `workflow` extension: one lap from a changelog plan to a gates row to a printed next task. Case study: [22-make-ds.md](./22-make-ds.md). Git branches: [22-gitflow.md](./22-gitflow.md). |
| **Out of this plan** | Calling a model. Enabling `workflow` in `.asc_extensions_ignore`. Writing `gates.yml` or `NEXT_STEPS.md`. Filling `rules` TODO scripts. Host catalog implementation ([20-host-scan-project-instances.md](./20-host-scan-project-instances.md)). Syncing sibling trees. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

Go-ahead is the workflow row in [`gates.yml`](../../../gates.yml). `go` stays `no` until that row is approved. Approving it authorizes the print-only `workflow-next` slice. It does not authorize gitflow, a model call, or a host copy.

---

## The lap, using `make ds` as it stands today

That changelog is the case study because it already walked the manual lap:

1. A plan file under `changelog/YYYY/MM/` with a status row `plan / review` and at least one open `- [ ]` task (otherwise `asc/doc/next_steps.sh` skips it).
2. A `gates.yml` row: `lane: discuss`, `approved: "no"`, `go: "no"`, `summary` short enough to approve without opening the file.
3. `asc/doc/next_steps.sh` would list it under “Awaiting human approval”. It does not write `gates.yml` or `NEXT_STEPS.md`.
4. A human sets `approved` and `go`. Discuss and held stay `go: "no"` (the registry comment). Sequential `go` also waits on lower `order` in that lane.
5. Nothing in the tree then starts work. `change/review.sh` and `change/iterate.sh` are empty. `workflow` is listed in `.asc_extensions_ignore`, so those pivots are not even registered here.
6. After implementation, the status becomes implemented / done / shipped / skipped, and the gates row is removed (see [22-gates-prune-approved-work.md](./22-gates-prune-approved-work.md)).

`workflow-next` is step 5 as a printer. It does not become the worker.

---

## `workflow-next`

| Piece | Value |
|-------|--------|
| Script to add | `asc/extensions/workflow/workflow/next.sh` |
| Pivot, once the extension is enabled | `workflow-next` |
| Direct call | `asc/extensions/workflow/workflow/next.sh` |
| Reads | The file `hook_ms 'dry-run' -s 'doc' -a 'gates' -c 'yml' -r` returns. Same lookup as the `gates.yml` header. |
| Writes | Nothing. Stdout only. |

A row is runnable when `lane` is `sequential` or `parallel`, `approved` is `yes`, and `go` is `yes`. `discuss` and `held` are not runnable. Trusting `go` alone is wrong on this tree: the nameref row is `discuss` with `go: "yes"`.

Stdout, one runnable row per block, in file order:

```text
changelog/2026/09/22-make-ds.md
Accept make ds as the short pivot…
```

No runnable row: exit 0 and print `none`. Missing gates file: non-zero. The script does not launch the changelog’s task, does not edit the changelog, and does not refresh `NEXT_STEPS.agent.md`.

The live `make ds` row is `go: "no"`, so a run against this mother prints `none`. The test uses a temp gates file with one runnable row and one discuss row, and passes that path. Production with no argument uses the dry-run path.

`change/review.sh`, `change/iterate.sh`, and the empty `*.able.yml` / `plan.entity.yml` stay as they are. `change.entity.yml` is a field sketch (`idea`, `tag`); it is not the task list. README still says the next-step store is unsettled (`reg-set` / `reg-get` or entities). The store this slice reads is `gates.yml`. [22-gates-registry-alternative.md](./22-gates-registry-alternative.md) stays the unstarted alternative.

Enable `workflow` on an instance only after the file exists. This plan does not edit `.asc_extensions_ignore`. Tests call the script.

---

## Where the other dots attach

They are later children. `workflow-next` does not call them.

| Dot | What it is today | Later child |
|-----|------------------|-------------|
| Changelogs + `gates.yml` | This lap’s inputs. `doc-next-steps` already lists them. | `workflow-next` only prints. |
| Host instances | [20-host-scan-project-instances.md](./20-host-scan-project-instances.md) catalogs sibling `$PROJECT_DOCROOT` trees and refuses to sync them. Pivot `host-instance-discover`. | After that stub is filled, a read-only child may print each path. It does not copy `asc/` and does not run `make generate`. |
| `make llm-call` | README Workflow names this pivot, with a provider env in the `DB_DRIVER` style, and `make agent-loop` / `make slm-call`. | Dispatch child. Not this slice. |
| `make agent-llm` | [22-agent-llm-entry-point.md](./22-agent-llm-entry-point.md) names a different pivot: hook call in `agent/llm.sh`, hook implementation in cursor, no provider env, no second pivot. Also `go: "no"`. | Same dispatch child. One of these two names, not both. |
| `make cursor-task` | Not a pivot in this tree. Cursor contrib is `scripts/asc/contrib/asc/cursor/agent/wrap.sh` only, and `asc/cursor` is ignored. | The contrib file is a hook implementation of an abstract task pivot, not a second make target. |

README also assigns next-step chains and DSL priority to the `rules` extension, and calls `workflow` the complement. Every `rules` script is still a TODO stub. This plan does not fill `rules`.

### Dispatch child (unwritten)

One abstract model pivot, one abstract task pivot.

- Model call: either README’s `make llm-call` (`asc/extensions/agent/llm/call.sh`, subject `llm` already has an empty `llm.entity.yml`) or the agent plan’s `make agent-llm`. The gate picks one before this child is written. Shipping both is two harnesses.
- Task: `make workflow-task` is the hook call (`hook_ms -s 'workflow' -a 'task'`). The cursor hook implementation, when that contrib is enabled, is `scripts/asc/contrib/asc/cursor/workflow/task.hook.sh`. The phrase `cursor-task` means that file. It is not a second entry point and it is not registered as `make cursor-task`.
- Provider selection by env, the way README describes `DB_DRIVER`, stays in that child. The agent-llm plan skipped it for its first cut. Workflow does not invent the env name here.
- The task body receives the changelog path `workflow-next` printed. It does not scan `gates.yml` again to find a different row.

### Host child (unwritten)

`host-instance-discover` is the catalog. Workflow does not grow a second find. A later printer may join “runnable gates row” with “sibling docroots” as text. Copying the mother tree onto those docroots, and running `make generate` there, is not this extension’s first write.

---

## Gaps

1. **Three names for the model call.** README: `llm-call`. Agent plan: `agent-llm`. This request also says `cursor-task`, which the harness rule keeps as a hook implementation name, not a pivot. Dispatch stays unwritten until one model pivot is chosen.
2. **`workflow` is disabled** on this mother. `workflow-next` is callable by path before it shows up in `pivots.mk`.
3. **Discuss rows with `go: "yes"` already exist.** The printer has to require `sequential` or `parallel` as well as `go`.
4. **README “Stabilize workflow + git flow” is unchecked.** Git is the other file. The proposal block in README § Workflow is not adopted human text.
5. **Host catalog refuses sync.** Connecting the dots is a printed join after discover exists. It is not a copy.
6. **`rules` is the README’s queue, and it is empty.** Workflow reads `gates.yml` directly. It does not pretend `rule/run.sh` already queues work.
7. **No new loader, no eager include, no write to the registry.**

---

## Tasks

- [ ] Confirm `workflow-next` only prints runnable gates rows.
- [ ] Pick `llm-call` or `agent-llm` before any dispatch child is written.
- [ ] Leave `cursor-task` as the cursor hook-implementation name, not a make pivot.
- [ ] Leave git branches to [22-gitflow.md](./22-gitflow.md).
