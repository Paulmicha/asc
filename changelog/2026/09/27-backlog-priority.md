# Changelog backlog priority

| Field | Value |
|-------|--------|
| **Date** | 2026-09-27 |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | One reading order for the dated changelog, after the root README contradictions that would propagate into code. Each open topic keeps one maintained plan. Completed notes stay on disk as history. |
| **Out of this plan** | Deleting dated files. Replacing human-written README lines in place. Regenerating `NEXT_STEPS.agent.core.md` as the repair. Filling `discover.sh`, `asc_core_sync.sh`, `generate.sh`, or guidance generation. A gates row for this note. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), except `$HOME`.

Until [`changelog/README.md`](../../README.md) is rewritten, this note is the priority record. The root [`README.md`](../../../README.md) stays the concept source. Where that file mixes a contract, a running behavior, and a proposal, this note records the split and a recommended repair. A dated proposal is **proposed**. It becomes a decision only when it is **accepted**, and it leaves the backlog only when a maintained plan **reflects** it. `gates.core.yml` stays the approval surface for later code. Do not add a row for this note.

**End.** When the changelog index and the maintained plans carry the reconciled priorities, set this note’s status to superseded by those files. It is not a second permanent queue.

The split below is a reading of status rows on 2026-09-27, with spot checks. It is not a fresh run of every historical implementation. Recount: 62 source notes, excluding this retrospective. 35 + 3 + 3 + 21 = 62. With this file the dated set is 63.

---

## Why the current list misleads

Completed work, design decisions, inventories, and executable plans sit in one index and look equally pending.

- The [index frontier](../../README.md) still calls entity discovery unstarted. [10-begin-entity-system-with-remote-instances.md](./10-begin-entity-system-with-remote-instances.md) says tasks 1–7 are done. The remainder is a README proposal (task 8, host-fixture table).
- The index says the subshell inventory finished waves 1–3. [31-subshell-printf-v-candidates.md](../07/31-subshell-printf-v-candidates.md) says waves 1–8 are done. What remains there is category G (bootstrap global command-substitution literals) and a later `eval` / `f_yaml_parse` implementation.
- [19-lazy-opt-inc-remaining-core-waves.md](./19-lazy-opt-inc-remaining-core-waves.md) has every checkbox checked. Its status line still names `make.inc.sh` and the wave table still names later subjects (`thread`, `host`, `instance`). `asc/make/make.inc.sh` is still on disk. A checkbox queue marks that note finished and drops the leftover.
- [`NEXT_STEPS.agent.core.md`](../../../NEXT_STEPS.agent.core.md) was generated on 2026-09-22. Plans dated 23, 25, 26, and 27 are absent.
- [`gates.core.yml`](../../../gates.core.yml) says `discuss` and `held` stay `no`. Three `discuss` rows have `go: yes`: the nameref inventory, [host scan](./20-host-scan-project-instances.md), and the XDG state path. Host scan’s own status says the stub is not a go. [Concert order](./25-concert-order.md) places that fill after the sidecar rewrite. That sequence is concert order’s chosen work order. The README catalog uses the host registry, so the sidecar scope decision is not a technical prerequisite. `asc/host/asc_core_sync.sh` still comments a backport into the mother; [23-host-asc-core-sync.md](./23-host-asc-core-sync.md) is a report, then a forward mirror, and its gate is `go: no`.
- [27-agent-guidance-from-antipatterns.md](./27-agent-guidance-from-antipatterns.md) says this checkout has no `AGENTS.md` and no `.agents/` directory. Both are present. `.agents/skills/` holds `asc-author-code`, `asc-author-docs`, and `asc-mother-guard`.

Regenerating the agent queue leaves those contradictions in place.

---

## Maintained topics

Eighteen of the twenty-one open files fold into seven topics. The dated file stays. The maintained plan links it. History is not copied in.

| Topic | Maintained plan | Also read | Treatment |
|-------|-----------------|-----------|-----------|
| Template rendering | [22-make-generate.md](./22-make-generate.md) | [22-make-generate-string.md](./22-make-generate-string.md), [20-builder-kernel-subject.md](./20-builder-kernel-subject.md) | Merge the string slice in as phase 1. The README places builder with the opt-in extensions. The kernel relocation stays deferred. |
| DSL | [22-make-ds.md](./22-make-ds.md) | [22-make-ds-literal.md](./22-make-ds-literal.md) | Merge directly. Literal print is phase 1. That slice currently copies the README `[[ script ]]` wrapper. Correct that contract before any compiler work. Grammar stays open. |
| Agent guidance and checking | [27-agent-guidance-from-antipatterns.md](./27-agent-guidance-from-antipatterns.md) | [26-patterns-and-antipatterns.md](./26-patterns-and-antipatterns.md) | Reconcile first. Keep Markdown records. Four objects: ability/contract, skill procedure, anti-pattern, template. Guidance may land before mechanical checking. Refresh the empty-tree assumption against `.agents/skills/` and `AGENTS.md`. |
| Core loading and shell maintenance | Index candidate list (this note, below) | [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md), [19-lazy-opt-inc-remaining-core-waves.md](./19-lazy-opt-inc-remaining-core-waves.md), [31-nameref-clarity-candidates.md](../07/31-nameref-clarity-candidates.md), [31-subshell-printf-v-candidates.md](../07/31-subshell-printf-v-candidates.md) | One list of remaining candidates. The inventories stay references. They stay separate refactors. The status checklist’s “refactor core” mark does not close this list. |
| Workflow and model dispatch | [22-workflow.md](./22-workflow.md) | [22-agent-llm-entry-point.md](./22-agent-llm-entry-point.md) | One design topic. The README name is `llm-call`. The `agent-llm` plan aligns with that name or proposes a change. Printing the queue and calling a model stay separate phases. Orchestration stays parked. |
| Storage and entity contracts | Sidecar section of [25-concert-order.md](./25-concert-order.md) | [24-yml-structure.md](../07/24-yml-structure.md), task 8 of [10-begin-entity-system-with-remote-instances.md](./10-begin-entity-system-with-remote-instances.md) | One decision agenda. YAML structure, sidecar paths, and the host registry stay three subjects. The registry path already accepted is `$HOME/.local/state/asc/registry` ([22-xdg-state-store.md](./22-xdg-state-store.md)). The README already separates `include` from `includes`. Scalar versus list form, and target resolution, stay in the July note. A path template for logs and changelogs is a scope change beside entity YAML sidecars, and it does not gate host discovery. |
| Host discovery and core distribution | [20-host-scan-project-instances.md](./20-host-scan-project-instances.md) then [23-host-asc-core-sync.md](./23-host-asc-core-sync.md) | Host-catalog section of [25-concert-order.md](./25-concert-order.md) | One roadmap, three deliverables: discovery, then a read-only drift report, then forward apply. Each keeps its own approval. The catalog uses the host registry. The live stub is `asc/host/instance/discover.sh`. |

`25-concert-order.md` is one dated file with three sections. The sidecar section feeds storage. The host-catalog section feeds discovery. The branch section is reconciled with gitflow. It stays one file until each of those sections has been transferred. Marking the whole note merged into storage would drop the other two sections.

### Consolidation

The destination in the table is the only actionable copy of that topic.

1. Transfer the remaining requirements into the destination.
2. Set the source status to merged into that destination, and link back to it.
3. Leave the source with no unchecked task lines.

`asc/doc/next_steps.sh` (`f_doc_next_steps_lane`) skips a note when the unchecked-task count is zero, and it does that before it reads the status word. `merged` and `superseded` are not lane words. Open checkboxes plus a status that only says merged are classified **sequential**. A label change alone leaves the child on the queue. After the transfer, regenerate the agent queue and confirm the task is listed once.

### Loading candidates

These are the leftovers named by the four references. The 2026-10-02 reinit timings are in [02-reinit-performance.md](../10/02-reinit-performance.md). That note is its own plan and does not reopen this loading list. A concrete defect, or the same maintenance repeating, can still justify a clarity or correctness change without a further measurement.

| Candidate | Where it is named |
|-----------|-------------------|
| `make.inc.sh`, then `thread`, `host`, `instance` on `ASC_INC` | Remaining-waves status and wave table. `asc/make/make.inc.sh` is still eager. |
| Optional wrap-versus-action bootstrap measurement | Lazy parent. The gates row authorizes measurement only. |
| Category G bootstrap globals | Subshell inventory, after waves 1–8. Performance work waits on a measurement. |
| Nameref inventory | Re-audit [31-nameref-clarity-candidates.md](../07/31-nameref-clarity-candidates.md). Retain only candidates that are still unimplemented. |
| Category C | Deferred. Optional `f_yaml_parse` helper or pilot, after its own gates row. The design in the subshell inventory keeps `eval` until then. |

On 2026-09-27, `f_in_array` and `f_array_add_once` in `asc/core/utils/arr.manual-inc.sh`, and `f_str_split1` in `asc/core/utils/str.manual-inc.sh`, already use `local -n`. `asc/test/core/utilities.test.sh` covers them (`test_f_in_array_and_add_once`, `test_f_str_split1`). That is a reading of the code and the test file. The tests were not run. The earlier “nameref pilots” line repeated a stale inventory. The nameref `discuss` / `go: yes` row is a gates contradiction. It is not authorization for a repo-wide rewrite.

---

## Three open files outside the seven

| File | Treatment |
|------|-----------|
| [22-gitflow.md](./22-gitflow.md) | Branch-policy design note. Reconcile it with the branch section of concert order. It is a contract to accept, not a script project. |
| [22-gates-registry-alternative.md](./22-gates-registry-alternative.md) | Parked. `gates.core.yml` stays the approval store. A second store would copy the same rows, including the stale ones. |
| [27-desktop-agent-terminal-reply.md](./27-desktop-agent-terminal-reply.md) | Independent research. Cursor, Codex, and Claude terminal reply. It blocks none of the other topics. |

---

## Reference only

Consult these. They are not projects.

| File | Role |
|------|------|
| [19-eager-vs-lazy-include-cases.md](./19-eager-vs-lazy-include-cases.md) | Working table. Pick A is locked. Root README remains the source of truth. |
| [20-agent-review-feedback-home.md](./20-agent-review-feedback-home.md) | Where agent review feedback lives. No runtime. |
| [20-stub-gap-inventory.md](./20-stub-gap-inventory.md) | Survey of stubs. No deletes. |

---

## Historical decisions

Keep these as decisions. Do not reopen them as work.

| File | Decision |
|------|----------|
| [19-mysql-pgsql-hook-opt-inc.md](./19-mysql-pgsql-hook-opt-inc.md) | Skipped. No shared mysql/pgsql hook helpers to extract. |
| [24-subject-asc-extensions.md](../07/24-subject-asc-extensions.md) | Rejected. No `$subject/.asc_extensions` loader. Keep `.asc_subjects_ignore`. |
| [20-meadows-plan-review-feedback-loop.md](./20-meadows-plan-review-feedback-loop.md) | Loop skipped. The mirror-path pick stays inside this note. |

---

## README layers

Checked against the root README and the tree on 2026-09-27. The README can close several open questions. It also stacks three layers that disagree: the contract it intends, the behavior that runs, and a proposal. A status checkbox that says “stabilized” is none of those three by itself.

Mark design and implementation separately. Both can be true. Design is **open**, **proposed**, or **accepted**. Implementation is **absent**, **partial**, or **present**.

### Contradictions that would propagate into code

**DSL.** The status checklist marks DSL stabilized. The validation example compiles `test-in(p1,slug(p1),snake(p1))` to:

```sh
[[ asc/test/in.sh 'foo-bar' "$(asc/instance/slug.sh 'foo-bar')" "$(asc/instance/snake.sh 'foo-bar')" ]] || exit 1
```

`bash -n` rejects that line: `conditional binary operator expected`. `[[ … ]]` does not run a command and test its exit status. [22-make-ds-literal.md](./22-make-ds-literal.md) copies the same `[[ script ]]` wrapper. Correct the contract before any compiler slice.

The same DSL section leaves more grammar open. Functions require `[]`, and the chaining examples drop the brackets on the later call. Nested `slug` is a shell function in one example and an ASC script in another. A function whitelist is named and never listed. [22-make-ds.md](./22-make-ds.md) already records those three.

**YAML.** The status checklist marks YAML stabilized. The merging operator is introduced as `merge`. The reserved-key list and the worked examples use `alter`, with no statement that the two spellings are synonyms. Keep `alter`. That spelling is the one used in the reserved keys and the examples.

`default` is allowed for optional fields only. The next example, and `asc/host/host.entity.yml`, put `default: localhost` on a required `hostname`. Decide whether “required” means the author supplied the value, or the value is present after defaults. That decision comes before any validation implementation.

The collision section (flattened keys such as `foo_bar` and `foo_bar_value`) and the later alteration section (schema inheritance via `alter`) describe different mechanisms. `asc/extensions/entity/entity.inc.sh` already flattens sidecar keys and states that it does not merge the type file into the instance. The README collision write-up should keep those two mechanisms apart.

**Entities and storage.** Entity storage describes automatic backend selection and points at `asc/extensions/memory/store/store.able.yml`. That file is empty. The contract-inheritance passage says the chain is implemented. These cited contracts are empty: `asc/sidecar/sidecar.able.yml`, `asc/host/provision.able.yml`, `asc/host/synchronize.able.yml`, `asc/host/ssh.able.yml`, `asc/host/nest.able.yml`, `asc/host/shell.able.yml`. `entity.entity.yml` and `able.able.yml` hold a short synonym block only. Current entity code discovers types and instances and writes a load cache. It does not perform general schema merging.

**Skill.** The contracts heading equates contracts, capabilities, abilities, and skills. `asc/extensions/entity/asc/able.able.yml` repeats that: `skill` is a synonym of `capability`, `ability`, and `contract`. `asc/extensions/agent/skill/skill.entity.yml` is a task procedure (`description`, `task`, `body`), with synonyms `procedure` and `playbook`. Use four objects:

| Object | What it is |
|--------|------------|
| Ability / contract | What something supports or requires |
| Skill procedure | Instructions for performing a task |
| Anti-pattern | A constraint a procedure references |
| Template | A concrete implementation shape |

That split is the reconciliation target for the guidance notes. Describing a constraint and detecting it in code stay separate capabilities. The records and the authoring skills already provide guidance.

**Workflow.** Non-goals refuse an all-orchestrating platform and send complex agent behavior to a dedicated instance. The Workflow section describes launching workers, continuous priority changes, DSL-driven chains, and provider dispatch. The minimal ASC piece is the abstract hook call. Provider policy and the orchestration loop belong to an instance or a contrib hook implementation. That is why workflow automation stays parked, and why empty `workflow` and `rules` stubs stay empty.

**Stale operations.** These descriptions still name the previous tree. A proposal that repeats the old path needs a newer proposal beside it.

| Place | What the README says | What the tree does |
|-------|----------------------|--------------------|
| Kernel, Genericity | Five always-sourced includes | `asc/bootstrap.sh` sources four `*.manual-inc.sh` files |
| Cache diagram and the paragraph under it | `global.vars.sh`, then `utils.inc.sh`, `core.inc.sh`, `hook.inc.sh`, `autoload.inc.sh` | The paragraph above the diagram names `data/asc/globals.sh`. A 2026-09-21 proposal already names the four `*.manual-inc.sh` files. Bootstrap loads those. |
| Extension defaults | Only `file_registry` is enabled | `.asc_extensions_ignore` also leaves `builder`, `checker`, and `entity` enabled |
| Builder example (2026-09-26 proposal) | `asc/extensions/builder/template/core/` | That path is absent. Authoring templates are `asc/extensions/builder/subject/` |
| Host copies (2026-09-24 proposal) | `asc/instance/discover.sh`, and discover “is not on disk” | That path was withdrawn. The stub is `asc/host/instance/discover.sh` |
| Compose instructions | `asc/extensions/docker-compose/compose/update.sh` | The extension directory is `asc/extensions/compose` |
| `hook_ms()` lookup | TODO | [21-hook-specificity-rungs.md](./21-hook-specificity-rungs.md) is done. A short explanation belongs in that README section |

The status checklist also marks “Refactor core + core extensions” done. Lazy-loading leftovers stay in the loading candidate list above.

### Already settled, for the plans to follow

| Question | Reading |
|----------|---------|
| Does `include` mean `includes`? | The README separates them: `include` loads other YAML files; `includes` reuses blocks inside one file. Close only that part of [24-yml-structure.md](../07/24-yml-structure.md). Scalar versus list `include`, and how a target stem resolves to a file, stay open there. |
| Is an ability an entity type? | No. A type is a `*.entity.yml`. An ability is a contract. Discovery keeps that split. |
| Must builder move into the kernel? | No. The README places it with the opt-in extensions. [20-builder-kernel-subject.md](./20-builder-kernel-subject.md) stays deferred. |
| Must guidance wait for an executable checker? | No. Constraints and mechanical detection are separate. |
| Where does provider-specific agent behavior live? | In a contrib hook implementation, behind an abstract core hook call. |
| Which model-call name leads? | The README uses `llm-call`. [22-agent-llm-entry-point.md](./22-agent-llm-entry-point.md) aligns with that name or proposes the change. Implementing both keeps the disagreement. |
| Should the host registry become entity storage? | No. The registry stays one string per key. Entity storage stays its own mechanism. |

### Still open after that reading

The sidecar contract. The README describes entity YAML sidecars under `data/entities`. Concert order proposes a path template that also covers logs, changelogs, and other files. That is a scope change. Timestamp spelling (`HH-II-SS` or `HH.MM.SS.MS`) and the split from `sidecar.wrap.sh` travel with that scope. The host catalog does not. It uses the registry that [22-xdg-state-store.md](./22-xdg-state-store.md) already accepted.

Also still open: the remaining DSL grammar, the meaning of “required” once defaults exist, and executable anti-pattern detection.

---

## Order

At most two implementation topics stay active beside a short decision list.

The numbered list is a priority recommendation. A topic starts when its own dependency below is met. An open README question does not hold unrelated work. The invalid DSL example blocks a DSL compiler. Required-field semantics block validation. Neither blocks host discovery or the string-substitution slice. Sidecar scope blocks a path-template implementation. The host catalog uses the registry in [22-xdg-state-store.md](./22-xdg-state-store.md), so discovery does not wait on that scope.

Three states, kept apart: **proposed** (written), **accepted** (the human agreed), **reflected** (the maintained plan, and the index when it is the map, state it). A proposal is not a resolved decision. Reflect only what is accepted. Work whose dependency is already met can proceed while another decision stays proposed.

### What blocks what

| Topic | Starts when | Does not wait on |
|-------|-------------|------------------|
| DSL compiler | The validation example is **accepted** as valid Bash, and a caller exists | Host discovery, string substitution |
| Validation | An **accepted** meaning of required-plus-default | Host discovery, string substitution |
| Host discovery | The host-scan gate and the host-scan note agree on whether the stub may be filled | The rest of the README pass, sidecar scope, the DSL contract |
| String substitution | The `make generate` gate is `go: yes` | The DSL example, required-field semantics, a kernel move |
| Guidance generation | The pain-list decision is to pursue generation | Other README items |
| Sidecar path template | Scope and timestamp spelling are **accepted** | Host discovery |
| Loading | The nameref re-audit is done. Performance items also need a measurement. Clarity or correctness items need a defect or repeated difficulty | The README pass as a whole |

### 1. README contradictions that would propagate into code

Preserve human-written README lines. Put a recommendation in a dated proposal beside them. When an older proposal is obsolete, mark that proposal superseded and point at the replacement. Do not leave competing recommendations beside the same paragraph.

Cover the DSL validation command, `alter` as the merging operator, the required-field default decision, flattened-key collisions versus inheritance merging, the four objects under “skill”, the workflow boundary against non-goals, and the stale paths in the table above. Replace a bare “stabilized” check with the design state and the implementation state. Add the short `hook_ms()` explanation in that same pass.

**Next action:** proposals for the DSL example and the `alter` / required-field pair. Record each as **proposed**.

**Done when** each propagating contradiction is **proposed** or still an explicit open question. Acceptance is a later human step. This pass does not start a compiler, a validator, or a generator, and it does not block topics whose dependency is already met.

### 2. Reconcile the backlog

Update [`changelog/README.md`](../../README.md) into four sections: active work, decisions awaiting review, parked ideas, history. Each active topic gets one next action and one completion condition from this note, including the acceptance cases named below. Follow the consolidation rule above so a child plan is not still actionable.

Reflect an item into a maintained plan only when it is **accepted**. Still **proposed**: leave it open. In particular, close only the `include` / `includes` distinction in the July note; scalar versus list `include`, and target resolution, stay open. The DSL literal slice drops the `[[ script ]]` wrapper only after an accepted valid-Bash example. Builder stays an extension. One model-call name, once that choice is accepted. Guidance uses the four objects once that split is accepted. Host discovery cites `asc/host/instance/discover.sh`.

Reconcile the three `discuss` / `go: yes` rows (nameref inventory, host scan, XDG state path) as their own edit. Inconsistent fields do not say whether approval should be withdrawn or expanded. Keep the human decision those rows and their changelog notes already record. A consistent file may remove a completed row, correct a lane while keeping an approval, narrow what the row authorizes, set `go` back to `no` when the decision was not an approval, or state an exception in the header.

**Done when** a reader of the index can name the active topics, the next action, and the completion condition without opening a history file, and the generated queue lists each transferred task once. Then set this note’s status to superseded by the index and those maintained plans.

### 3. Host discovery, then a read-only core drift report

`asc/host/instance/discover.sh` and `asc/host/asc_core_sync.sh` both end at `# TODO` (checked 2026-09-27). Start with paths, then differences. Schedule forward apply after target compatibility and replacement behavior are reviewed. Apply does not write into the mother.

The host-scan gate is `discuss` and `go: yes` while the note says not to fill the stub. Reconcile that pair under the gates rule above before writing the body. The core-sync gate stays `no` until the report’s own approval.

Sidecar scope, timestamp spelling, and the entity host-fixture README proposal (task 8) stay on their own agenda.

**Next action:** list project docroots from `make host-instance-discover`, once the gate and the note agree the stub may be filled.

**Done when** the acceptance cases in [20-host-scan-project-instances.md](./20-host-scan-project-instances.md) pass: upsert host-registry key `asc_project_instances` (newline-separated paths), print those paths, and the bounded walk holds (`find -P`, never `-L`, `-maxdepth 6`, prune on hit, the named directory prunes, reject `/`, repeatable `--root`, the shallow / nested / decoy fixture, no write into this git tree). A second slice prints core drift for `asc/` and `scripts/asc/contrib/asc/` without writing. Forward apply is a third slice with its own approval.

### 4. String template slice

[22-make-generate.md](./22-make-generate.md) bounds the first deliverable: substitute a string and print it. That matches the README scope line for builder templates. The kernel move stays in [20-builder-kernel-subject.md](./20-builder-kernel-subject.md) and is not a dependency of this slice.

**Next action:** implement the string-print slice only, after its gate is `go: yes`.

**Done when** the behavior table in [22-make-generate-string.md](./22-make-generate-string.md) passes, not only the happy path. Unknown `{{ slot }}` exits non-zero with no stdout. `[subject]` exits non-zero. `file` and `dir` exit non-zero. File mode, directory mode, and `<asc-if>` stay unwritten.

### 5. Reassess guidance against the skills already here

The guidance in the anti-pattern records stays useful. The generator in the September 27 note also brings a manifest, ownership checks, reconciliation, and product-specific output. Reconcile that note with the September 26 patterns note before any generation work: Markdown records stay, guidance precedes mechanical checking, and the four objects above stay distinct once that split is accepted.

**Next action:** list what is still painful with `asc-author-code`, `asc-author-docs`, and `asc-mother-guard` in `.agents/skills/`.

**Done when** that list ends in one decision: retain the current skills, improve them manually, or pursue generation. Generation starts only from the third. Mechanical checking is a later phase.

### 6. Parked until a concrete use pulls one forward

| Topic | Why it waits | What would pull it |
|-------|----------------|--------------------|
| DSL compiler | The validation contract is invalid Bash, and the grammar questions above are still open. | An **accepted** valid-Bash example, then a real caller for one literal print. |
| Workflow dispatch | Non-goals leave orchestration to an instance. The documented pivot name is `llm-call`. | A consumer, and an **accepted** alignment with `llm-call` or an **accepted** rename. Queue printing and the model call stay separate phases. Empty `workflow` and `rules` stubs stay empty. |
| Sidecar path template | The README sidecar is entity YAML. A template for logs and changelogs is a wider scope. | An **accepted** scope and timestamp spelling. Host discovery does not wait for it. |
| Loading refactors | Performance items have no measurement. The nameref list still needs the re-audit. Category C stays deferred. | A measurement for a performance item, or a defect or repeated difficulty for a clarity or correctness item. |
| Desktop terminal reply | Bounded research. It unlocks nothing else. | Someone doing that research for its own result. |

---

## History (35)

Accepted or done inside the scope the note itself states. The index rewrite files these under history.

| File | Status row, short |
|------|-------------------|
| [04-pdf-generation-improvements.md](./04-pdf-generation-improvements.md) | implemented |
| [11-bootstrap-cache-layout-and-invalidation.md](./11-bootstrap-cache-layout-and-invalidation.md) | implemented; later lazy work is the parent plan |
| [12-rename-generated-mk-to-pivots-mk.md](./12-rename-generated-mk-to-pivots-mk.md) | implemented |
| [12-rename-test-case-run-to-single-case-make.md](./12-rename-test-case-run-to-single-case-make.md) | implemented |
| [12-subject-object-action-entry-points.md](./12-subject-object-action-entry-points.md) | implemented |
| [17-pdf-graphviz-edge-labels.md](./17-pdf-graphviz-edge-labels.md) | implemented |
| [17-pdf-graphviz-support.md](./17-pdf-graphviz-support.md) | implemented |
| [19-db-thin-inc-and-opt-inc.md](./19-db-thin-inc-and-opt-inc.md) | implemented |
| [19-fs-archive-lazy-include.md](./19-fs-archive-lazy-include.md) | implemented |
| [20-drop-empty-kernel-global-inc.md](./20-drop-empty-kernel-global-inc.md) | done |
| [20-gap-entity-not-core.md](./20-gap-entity-not-core.md) | done |
| [20-garage-lightweight-rule.md](./20-garage-lightweight-rule.md) | done |
| [20-match-script-not-clone-includes.md](./20-match-script-not-clone-includes.md) | done |
| [20-self-explainable-labels.md](./20-self-explainable-labels.md) | done |
| [20-two-include-kinds.md](./20-two-include-kinds.md) | done |
| [21-hook-specificity-rungs.md](./21-hook-specificity-rungs.md) | done |
| [21-kernel-utils-inc.md](./21-kernel-utils-inc.md) | done |
| [21-manual-inc.md](./21-manual-inc.md) | implemented |
| [21-rename-asc-subject-to-core.md](./21-rename-asc-subject-to-core.md) | done |
| [21-utils-under-core.md](./21-utils-under-core.md) | done |
| [22-deprecate-subject-asc-extensions.md](./22-deprecate-subject-asc-extensions.md) | implemented |
| [22-doc-next-steps.md](./22-doc-next-steps.md) | implemented |
| [22-gates-like-env.md](./22-gates-like-env.md) | implemented |
| [22-gates-prune-approved-work.md](./22-gates-prune-approved-work.md) | implemented |
| [22-next-steps-like-env.md](./22-next-steps-like-env.md) | implemented |
| [22-xdg-state-store.md](./22-xdg-state-store.md) | path accepted; reconcile its `discuss` / `go: yes` row with that acceptance |
| [25-fs-file-list-append.md](./25-fs-file-list-append.md) | done |
| [25-fs-list-arrays.md](./25-fs-list-arrays.md) | done |
| [25-wired-init-lists.md](./25-wired-init-lists.md) | git list implemented; alias half withdrawn |
| [26-app-prefix-inventory.md](./26-app-prefix-inventory.md) | implemented |
| [26-host-shell-aliases-asc.md](./26-host-shell-aliases-asc.md) | implemented |
| [26-readme-toc-pre-commit.md](./26-readme-toc-pre-commit.md) | implemented |
| [26-living-docs-readme-status.md](../07/26-living-docs-readme-status.md) | done |
| [31-array-dict-naming-plan.md](../07/31-array-dict-naming-plan.md) | implemented |
| [18-transcribe-mp4.md](../08/18-transcribe-mp4.md) | implemented |
