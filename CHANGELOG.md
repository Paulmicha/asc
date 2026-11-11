# Changelog

Dated notes for this ASC **core** repo. Dated notes now live under `docs/plans/YYYY/MM/`. The root [`README.md`](README.md) is the **only** source of truth (human-written). These files do not override it.

Files: `docs/plans/YYYY/MM/DD-short-label.md`. The [migration map](docs/plans/2026/11/10-changelog-refactor.md#appendix-a--oldnew-map) records their old paths. Each file starts with a status table. `$` in these notes is an ASC placeholder (`$subject` / `$action` / …), not a shell variable.

**How to read:** trust the status row. Huge files that say **implemented** still contain historical plan checkboxes — do not re-run them.

**Priority (2026-09-27).** The frontier section below still describes 2026-09-21. Until it is rewritten, the order is [2026/09/27-backlog-priority.md](docs/plans/2026/09/27-backlog-priority.md).

## 2026-11

| File | Role |
|------|------|
| [06-host-needs-and-skill-feedback.md](docs/plans/2026/11/06-host-needs-and-skill-feedback.md) | Proposed. Host Markdown needs. Not a go-ahead. A same-day review found corrections the plan file does not yet contain. |
| [06-simplify-disk-entities-contracts.md](docs/plans/2026/11/06-simplify-disk-entities-contracts.md) | Proposed. First inventory for retiring unread entity and contract YAML. Not a go-ahead. |

## 2026-10

| File | Role |
|------|------|
| [02-reinit-performance.md](docs/plans/2026/10/02-reinit-performance.md) | Partial. Tasks 1–4 are in the tree. `php -l`, post-change reinit timing, and the instance settings override are still open. |
| [29-local-concurrent-stacks.md](docs/plans/2026/10/29-local-concurrent-stacks.md) | Plan only. One laptop, several Compose projects, one way to share ports 80 and 443. Not a go-ahead. |

## Current frontier (2026-09-21)

Live work is leftover core lazy waves after fs+db+yaml. Meadows loop **skipped**. Eager/lazy **working table** (not SoT — root README is): [2026/09/19-eager-vs-lazy-include-cases.md](docs/plans/2026/09/19-eager-vs-lazy-include-cases.md). `*.manual-inc.sh` **implemented**. Entity discovery is a separate unstarted plan. Print/PDF is shipped. Agent queue: [`NEXT_STEPS.agent.core.md`](../NEXT_STEPS.agent.core.md), refreshed by `asc/doc/next_steps.sh`. Discussion: [`NEXT_STEPS.core.md`](../NEXT_STEPS.core.md). Go-ahead: [`gates.core.yml`](../gates.core.yml) when `INSTANCE_TYPE` is `core`. Copy model: [`SPECIMEN.gates.yml`](../SPECIMEN.gates.yml).

## 2026-09

### Shipped

| File | One line |
|------|----------|
| [04-pdf-generation-improvements.md](docs/plans/2026/09/04-pdf-generation-improvements.md) | Markdown→PDF: orphans, KaTeX, Mermaid, long code |
| [11-bootstrap-cache-layout-and-invalidation.md](docs/plans/2026/09/11-bootstrap-cache-layout-and-invalidation.md) | Stamp + `core/active.sh`; `make cc` = lookup only |
| [12-rename-generated-mk-to-pivots-mk.md](docs/plans/2026/09/12-rename-generated-mk-to-pivots-mk.md) | `generated.mk` → `pivots.mk` |
| [12-rename-test-case-run-to-single-case-make.md](docs/plans/2026/09/12-rename-test-case-run-to-single-case-make.md) | `case.run.sh` → `single_case.make.sh` |
| [12-subject-object-action-entry-points.md](docs/plans/2026/09/12-subject-object-action-entry-points.md) | Heuristic A: `$subject` / `$object` / `$action` |
| [17-pdf-graphviz-support.md](docs/plans/2026/09/17-pdf-graphviz-support.md) | Graphviz fences in the print pipeline |
| [17-pdf-graphviz-edge-labels.md](docs/plans/2026/09/17-pdf-graphviz-edge-labels.md) | Opt-in gvpr edge labels |
| [20-garage-lightweight-rule.md](docs/plans/2026/09/20-garage-lightweight-rule.md) | Historical garage clause; mother rule retired on 2026-09-30 |
| [30-cursor-rules-home.md](docs/plans/2026/09/30-cursor-rules-home.md) | Shared Cursor rules owned by home user rules; mother copy retired |
| [20-self-explainable-labels.md](docs/plans/2026/09/20-self-explainable-labels.md) | Labels / pivot NL; harness = abstract hook vs contrib `hook_ms` |
| [20-match-script-not-clone-includes.md](docs/plans/2026/09/20-match-script-not-clone-includes.md) | Sibling `. include` is not a caller |
| [20-two-include-kinds.md](docs/plans/2026/09/20-two-include-kinds.md) | Two include kinds only; `utils/` opt-inc is explicit `.` |
| [19-fs-archive-lazy-include.md](docs/plans/2026/09/19-fs-archive-lazy-include.md) | Archive helpers in `fs.opt-inc.sh`; gzip-of-SQL; `f_fs_watch_poll` dropped |
| [19-db-thin-inc-and-opt-inc.md](docs/plans/2026/09/19-db-thin-inc-and-opt-inc.md) | Creds eager; dump/exec cluster at `db/db/db.opt-inc.sh` |
| [19-mysql-pgsql-hook-opt-inc.md](docs/plans/2026/09/19-mysql-pgsql-hook-opt-inc.md) | Skipped — no shared mysql/pgsql hook helpers |
| [21-manual-inc.md](docs/plans/2026/09/21-manual-inc.md) | Hardcoded includes → `*.manual-inc.sh`. Kernel four off `ASC_INC` |
| [22-doc-next-steps.md](docs/plans/2026/09/22-doc-next-steps.md) | `doc-next-steps` writes `NEXT_STEPS.agent.md`; `NEXT_STEPS.md` stays human |
| [22-gates-like-env.md](docs/plans/2026/09/22-gates-like-env.md) | Gates lookup matches `env.yml`. This checkout: `INSTANCE_TYPE=core` → `gates.core.yml` |
| [22-next-steps-like-env.md](docs/plans/2026/09/22-next-steps-like-env.md) | Next-steps lookup matches `env.yml`. This checkout: `NEXT_STEPS.core.md` and `NEXT_STEPS.agent.core.md` |

### Live (do not implement as one PR)

| File | Role |
|------|------|
| [11-lazy-opt-inc-and-entry-point-extraction.md](docs/plans/2026/09/11-lazy-opt-inc-and-entry-point-extraction.md) | Parent split + caveats (1)–(14). Keep/move/drop drill |
| [19-eager-vs-lazy-include-cases.md](docs/plans/2026/09/19-eager-vs-lazy-include-cases.md) | Two loaders, case table. **Pick A locked**. Tests: `caller_opt_inc.test.sh` |
| [19-lazy-opt-inc-remaining-core-waves.md](docs/plans/2026/09/19-lazy-opt-inc-remaining-core-waves.md) | After fs+db+yaml. Next leftover: Wave C `make.inc.sh` |
| [20-meadows-plan-review-feedback-loop.md](docs/plans/2026/09/20-meadows-plan-review-feedback-loop.md) | Meta-plan. Loop skipped; hunts apply in chat |

### Later / out of that loop

| File | Role |
|------|------|
| [20-host-scan-project-instances.md](docs/plans/2026/09/20-host-scan-project-instances.md) | Catalog `$PROJECT_DOCROOT` trees on this host |
| [22-gates-registry-alternative.md](docs/plans/2026/09/22-gates-registry-alternative.md) | Plan only. `gates.yml` is the registry. `reg-get` / `reg-set` YAML is not started |
| [22-xdg-state-store.md](docs/plans/2026/09/22-xdg-state-store.md) | Path accepted 2026-09-24. Host registry is `$HOME/.local/state/asc/registry`. Memory stays off. |
| [22-make-ds.md](docs/plans/2026/09/22-make-ds.md) | `make ds` contract. Plan only. Literal print is the child |
| [22-make-ds-literal.md](docs/plans/2026/09/22-make-ds-literal.md) | First slice: print one literal DSL call. Plan only |
| [22-make-generate.md](docs/plans/2026/09/22-make-generate.md) | `make generate` renders string, file, or dir templates. Plan only |
| [22-make-generate-string.md](docs/plans/2026/09/22-make-generate-string.md) | First slice: print one `{{ name }}` substitution. Plan only |
| [22-workflow.md](docs/plans/2026/09/22-workflow.md) | Workflow lap: changelog → gates → `workflow-next`. Plan only |
| [22-gitflow.md](docs/plans/2026/09/22-gitflow.md) | Mother / buffer / machine branch. Plan only. No scripts |
| [30-asc-guidance-as-project-skills.md](docs/plans/2026/09/30-asc-guidance-as-project-skills.md) | Compatibility diff in the work tree, unpublished. Not a direction to upgrade. |
| [20-builder-kernel-subject.md](docs/plans/2026/09/20-builder-kernel-subject.md) | `asc/builder/` one kernel subject + `template.able` / `literal.able` sketches |
| [20-gap-entity-not-core.md](docs/plans/2026/09/20-gap-entity-not-core.md) | Knowledge/task `gap` is a project instance (Projet Complexe), not core |
| [10-begin-entity-system-with-remote-instances.md](docs/plans/2026/09/10-begin-entity-system-with-remote-instances.md) | Entity types → instances → cache. Stub path still wrong |

## 2026-08

| File | Status |
|------|--------|
| [18-transcribe-mp4.md](docs/plans/2026/08/18-transcribe-mp4.md) | implemented (`transcribe-file`) |

## 2026-07

| File | Status |
|------|--------|
| [24-subject-asc-extensions.md](docs/plans/2026/07/24-subject-asc-extensions.md) | plan / review (open README conflict) |
| [24-yml-structure.md](docs/plans/2026/07/24-yml-structure.md) | plan / review (not implementation go-ahead) |
| [26-living-docs-readme-status.md](docs/plans/2026/07/26-living-docs-readme-status.md) | done (docs) |
| [31-array-dict-naming-plan.md](docs/plans/2026/07/31-array-dict-naming-plan.md) | implemented |
| [31-nameref-clarity-candidates.md](docs/plans/2026/07/31-nameref-clarity-candidates.md) | inventory (logic migrations remain) |
| [31-subshell-printf-v-candidates.md](docs/plans/2026/07/31-subshell-printf-v-candidates.md) | partial (waves 1–3 done) |
