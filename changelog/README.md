# Changelog

Dated notes for this ASC **core** repo. Long form lives here. The root [`README.md`](../README.md) is the **only** source of truth (human-written). These files do not override it.

Files: `YYYY/MM/DD-short-label.md`. Each file starts with a status table. `$` in these notes is an ASC placeholder (`$subject` / `$action` / …), not a shell variable.

**How to read:** trust the status row. Huge files that say **implemented** still contain historical plan checkboxes — do not re-run them.

## Current frontier (2026-09-20)

Live work is the lazy-include split. Meadows loop **skipped** — hunts apply in chat ([2026/09/20-meadows-plan-review-feedback-loop.md](2026/09/20-meadows-plan-review-feedback-loop.md)). Eager/lazy **working table** (not SoT — root README is): [2026/09/19-eager-vs-lazy-include-cases.md](2026/09/19-eager-vs-lazy-include-cases.md). Entity discovery is a separate unstarted plan. Print/PDF is shipped.

## 2026-09

### Shipped

| File | One line |
|------|----------|
| [04-pdf-generation-improvements.md](2026/09/04-pdf-generation-improvements.md) | Markdown→PDF: orphans, KaTeX, Mermaid, long code |
| [11-bootstrap-cache-layout-and-invalidation.md](2026/09/11-bootstrap-cache-layout-and-invalidation.md) | Stamp + `core/active.sh`; `make cc` = lookup only |
| [12-rename-generated-mk-to-pivots-mk.md](2026/09/12-rename-generated-mk-to-pivots-mk.md) | `generated.mk` → `pivots.mk` |
| [12-rename-test-case-run-to-single-case-make.md](2026/09/12-rename-test-case-run-to-single-case-make.md) | `case.run.sh` → `single_case.make.sh` |
| [12-subject-object-action-entry-points.md](2026/09/12-subject-object-action-entry-points.md) | Heuristic A: `$subject` / `$object` / `$action` |
| [17-pdf-graphviz-support.md](2026/09/17-pdf-graphviz-support.md) | Graphviz fences in the print pipeline |
| [17-pdf-graphviz-edge-labels.md](2026/09/17-pdf-graphviz-edge-labels.md) | Opt-in gvpr edge labels |
| [20-garage-lightweight-rule.md](2026/09/20-garage-lightweight-rule.md) | Garage clause in `asc-lightweight.mdc` |
| [20-self-explainable-labels.md](2026/09/20-self-explainable-labels.md) | Labels / human↔token loop; `phase 90` → caller opt-inc |
| [20-match-script-not-clone-includes.md](2026/09/20-match-script-not-clone-includes.md) | Sibling `. include` is not a caller |
| [20-readme-is-sot.md](2026/09/20-readme-is-sot.md) | Root README is the only SoT; agents must flag mismatches |

### Live (do not implement as one PR)

| File | Role |
|------|------|
| [11-lazy-opt-inc-and-entry-point-extraction.md](2026/09/11-lazy-opt-inc-and-entry-point-extraction.md) | Parent split + caveats (1)–(14). SoT for keep/move/drop |
| [19-eager-vs-lazy-include-cases.md](2026/09/19-eager-vs-lazy-include-cases.md) | Two loaders, case table. **Pick A locked** (caller-dir). Tests: `caller_opt_inc.test.sh` |
| [19-fs-archive-lazy-include.md](2026/09/19-fs-archive-lazy-include.md) | First code slice: archive helpers off kernel `fs.inc.sh` |
| [19-db-thin-inc-and-opt-inc.md](2026/09/19-db-thin-inc-and-opt-inc.md) | Creds eager; dump/exec cluster lazy at `db/db/db.opt-inc.sh` (pick A). Function move later |
| [19-mysql-pgsql-hook-opt-inc.md](2026/09/19-mysql-pgsql-hook-opt-inc.md) | DRY only if grep shows sharing; otherwise skip |
| [20-meadows-plan-review-feedback-loop.md](2026/09/20-meadows-plan-review-feedback-loop.md) | Meta-plan. Loop skipped; hunts apply in chat |

### Later / out of that loop

| File | Role |
|------|------|
| [19-lazy-opt-inc-remaining-core-waves.md](2026/09/19-lazy-opt-inc-remaining-core-waves.md) | After fs+db. First leftover: yaml dual-source |
| [20-host-scan-project-instances.md](2026/09/20-host-scan-project-instances.md) | Catalog `$PROJECT_DOCROOT` trees on this host |
| [20-builder-kernel-subject.md](2026/09/20-builder-kernel-subject.md) | `asc/builder/` one kernel subject + `template.able` / `literal.able` sketches |
| [10-begin-entity-system-with-remote-instances.md](2026/09/10-begin-entity-system-with-remote-instances.md) | Entity types → instances → cache. Stub path still wrong |

## 2026-08

| File | Status |
|------|--------|
| [18-transcribe-mp4.md](2026/08/18-transcribe-mp4.md) | implemented (`transcribe-file`) |

## 2026-07

| File | Status |
|------|--------|
| [24-subject-asc-extensions.md](2026/07/24-subject-asc-extensions.md) | plan / review (open README conflict) |
| [24-yml-structure.md](2026/07/24-yml-structure.md) | plan / review (not implementation go-ahead) |
| [26-living-docs-readme-status.md](2026/07/26-living-docs-readme-status.md) | done (docs) |
| [31-array-dict-naming-plan.md](2026/07/31-array-dict-naming-plan.md) | implemented |
| [31-nameref-clarity-candidates.md](2026/07/31-nameref-clarity-candidates.md) | inventory (logic migrations remain) |
| [31-subshell-printf-v-candidates.md](2026/07/31-subshell-printf-v-candidates.md) | partial (waves 1–3 done) |
