# Host-wide ASC needs and skill feedback: implementation plan

| Field | Value |
|-------|-------|
| **Date** | 2026-11-06 |
| **Status** | Proposed for review. This document records the design and staged plan; it does not enable capture or change a skill. |
| **Scope** | Preserve needs encountered during ASC work, then use reviewed evidence to improve actions, their composition, documentation, and skills. |
| **User decisions** | Use **needs**, with dated Markdown files such as `$HOME/.local/state/asc/needs/2026/11/06/14h30-foobar-need.md`. |
| **Still proposed** | Record format, capture threshold, automatic-capture policy, review states, reference placement, and optional writer. |

**Goal:** Let ordinary work in any ASC project instance contribute concise evidence about unmet or poorly served needs, without requiring an implementation plan during that work.

**Architecture:** A user-local, host-shared directory contains one Markdown file per observation. The existing action-priority skill identifies relevant observations and points to a maintained capture reference. Later review decides whether an observation warrants a change, where that change belongs, and how to validate it.

**Tech stack:** Markdown and the local filesystem for the first slice. Existing ASC actions and skill-distribution mechanisms where applicable. No database, queue service, mandatory entity compiler, or agent scheduler.

**Spec:** The design sections of this document, based on the user's discussion and the sources below. Proposed choices are reviewable here before implementation. An eventual implementer should use `superpowers:executing-plans`, or an explicitly selected delegated workflow, after approval.

## Sources and evidence boundaries

- [Main README](../../../../README.md): Overarching goal; Scope and Non-goals; Skills, Instructions, Capabilities; Genericity (scale); Extension Point; Contracts; Data dirs; Workflow.
- [Shared instructions](../../../../AGENTS.asc.md) and [action-priority skill](../../../../.agents/skills/asc-actions-priority/SKILL.md): current task routing and operational discovery requirements.
- [Documentation skill](../../../../.agents/skills/asc-author-docs/SKILL.md), [code skill](../../../../.agents/skills/asc-author-code/SKILL.md), and [mother guard](../../../../.agents/skills/asc-mother-guard/SKILL.md): maintained authoring and ownership boundaries.
- [Build Your Own Skill Library](https://drive.google.com/file/d/1ithrUotyBW6FZBpMvYJBo1d9EKTFVUf4/view), attributed to `@0xShoopy`, Applied Agent Engineering, Field Notes 2026: all ten pages read through the Google Drive preview on 2026-11-06. Particularly relevant are sections II, IV-XII, XVI-XXI, and XXIV. Its architecture is an author's proposal, not an ASC contract or a verified guarantee about every agent product.
- [Accepted host-registry storage decision](../09/22-xdg-state-store.md): host-shared storage and the one-string-per-key registry contract.
- [Guidance as project skills](../09/30-asc-guidance-as-project-skills.md) and [guidance from anti-patterns](../09/27-agent-guidance-from-antipatterns.md): related source-ownership and rendering proposals. Historical completion claims require comparison with current code.
- [No core gap entity](../09/20-gap-entity-not-core.md): keep knowledge-management complexity out of ASC core.

This is a documentation-only change. Source inspection supports the inventory below; no new capture mechanism, agent replay, upgrade, or host write was executed. The PDF's repository popularity, quantitative targets, cost estimates, and product claims were not independently verified and are not adoption criteria here.

## 1. Intent: make ordinary work inform ASC's vocabulary

ASC develops a common language for shell operations through stable pivots, implementations, variants, and composition. A successful direct command can therefore expose an opportunity: perhaps an existing implementation is hard to discover, perhaps arguments are lost, perhaps several actions need better composition, or perhaps a reusable implementation is missing.

The useful questions are:

1. Do current ASC implementations express this need adequately and efficiently?
2. If they do not, what is the smallest improvement consistent with existing implementations, and where does it belong on the genericity scale?

Routine work often has enough evidence to record the first question without enough time or authority to settle the second. Preserve that evidence while it is fresh. Continue the authorized task using the suitable action or fallback. Review the opportunity separately.

**Need** names the desired outcome or constraint before a solution has been selected. An idea proposes a possible solution. A plan selects work and validation. A recorded need can support several ideas, an existing solution, or a decision to leave the current approach in place.

This distinction prevents every fallback from becoming a demand for a new action or skill. It also preserves useful observations made while ASC succeeds: repeated overrides, awkward combinations, excessive discovery effort, or checks that do not establish the claimed result.

## 2. What exists today

| Source | Observed behavior | Consequence |
|--------|-------------------|-------------|
| `asc/extensions/file_registry/file_registry.inc.sh` and its host hooks | Host registry values are files under the configured registry root, defaulting to `$HOME/.local/state/asc/registry`, with a `host` namespace. Set replaces one string value. | Reuse its host-sharing principle; do not silently turn its get/set/delete contract into a document queue. |
| `asc/extensions/workflow/idea/idea.entity.yml` | Includes `sidecar.able`; it does not define this needs workflow. | No existing needs schema or Markdown discovery contract can be claimed from it. |
| README Data dirs and Workflow | Queue, skills storage, and ideas sections remain TODOs; workflow storage contains proposals. | Their headings are not implemented queue services. |
| `asc/extensions/agent/skill/skill.entity.yml` and `skill/render.sh` | A product-neutral skill declaration and render entry point exist. Codex and Cursor render hooks currently write product-specific skill paths. | A future structured skill source is possible, but migrating all skills is separate work. |
| `.asc_extensions_ignore` in this checkout | `agent`, `memory`, and `workflow` are disabled. | First-slice capture must not depend on enabling them. |
| `asc/core/upgrade.sh` | Replaces four named shared skill directories, copies `AGENTS.asc.md`, and preserves the instance's root `AGENTS.md`. It also contains Claude skill-link handling. | Changes are distributed only through the actual upgrade path and selected upstream revision. A fifth skill is not automatically included in that explicit list. |

The README's 2026-10-30 proposal still says the upgrade overwrites `AGENTS.md`. That differs from the current script. A later adjacent README proposal should reconcile the description; this plan does not rewrite the README.

The action-priority skill already has uncommitted discovery improvements. Preserve them when implementing the additions proposed here. This plan does not replace that work.

## 3. Approaches and chosen direction

| Approach | Benefit | Cost or limitation | Position |
|----------|---------|--------------------|----------|
| Project-local observations only | Context stays beside the project. | Cross-project recurrence remains scattered. | Keep detailed private evidence there, but use host records to make needs visible together. |
| Needs as host-registry values | Uses an available writer. | Structured review, relationships, and document updates would be conventions layered on a string store. A shared aggregate value also creates contention. | Keep the registry for existing keys and optional anonymized origin references. |
| One dated Markdown record per observation in host state | Readable without ASC, independent writes, easy chronological browsing and text search. | Requires a small capture convention and later human review. | User-selected storage direction; recommended first slice. |

Calling this an inbox or backlog is sufficient. It has no FIFO execution promise, consumers, acknowledgements, leases, or automatic plan dispatch. A date determines where an observation is stored, not its review priority.

## 4. Storage and identity

### 4.1 Shared host location

Use the user-selected default:

```text
$HOME/.local/state/asc/needs/
  2026/
    11/
      06/
        14h30-forward-arguments-need.md
        14h30-forward-arguments-need-2.md
```

`$HOME` here is the shell home directory, not a conceptual ASC placeholder. The first path is the requested convention; the numeric collision suffix is proposed.

All ASC instances under the same user on the same host write to the same directory, including the home-directory instance. The records belong to the user's host state, not to the mother repository or to whichever project happened to create them.

Do not derive the directory from the current project root or from the location of a globally discovered skill. Installing the skill globally does not make every workspace an ASC instance. Apply ASC-specific capture only when the task concerns an identified ASC tree.

Keep the default literal and simple for the first slice. Do not derive it from `FILE_REGISTRY_HOST_LEVEL_PATH`, which names a different store. Support an explicit instance or host policy choosing another root when necessary; do not introduce a storage resolver or a new global merely for hypothetical backends. If configurable resolution is later implemented, all participating instances on one host must agree on the root. Adopting `$XDG_STATE_HOME` resolution would be a separate explicit refinement to this default.

Host state is persistent local evidence, but not automatically backed up, versioned, synchronized between machines, or available to remote agents. A scheduled review or backup is a separate choice, not part of capture.

### 4.2 Naming and time

- Use `YYYY/MM/DD/HHhMM-$slug-need.md`; `$slug` is a short English description of the desired outcome, using lowercase ASCII letters, digits, and hyphens.
- Obtain the directory date and filename time from one capture instant in the producer's local timezone. Store an ISO 8601 timestamp with its numeric UTC offset in the record. This distinguishes chronology during timezone changes and repeated clock hours.
- Use the relative path from the needs root as the initial record identifier. Do not rename it when the title or review status changes.
- A filename collision must never replace another record. Reserve names exclusively; try a numeric suffix such as `-2`, then `-3`, when necessary. Checking that a path is absent before an ordinary overwrite is insufficient under concurrent writers.
- Publish a complete record, not a partially written Markdown document. A future writer should stage privately on the same filesystem and publish without replacing an existing destination. Temporary files are not reviewable needs.
- A slug describes the need without client names, private domains, ticket identifiers, or secrets.

Minute precision is useful for reading; collision handling provides uniqueness. There is no need for a central sequence file or a lock covering the entire inbox.

## 5. Minimal record format

Use ordinary Markdown. A YAML entity sidecar, a compiled entity cache, and a database identifier are not prerequisites. Do not claim that this layout is already discoverable by the existing sidecar loader.

The proposed first format has a title, a short metadata table, and three required sections: **Need**, **Evidence**, and **Current approach**. Add **Possible reuse** and **Review** only when useful. The following is an illustrative record, not a report of an observed defect:

```markdown
# Preserve arguments when invoking an application tool

| Field | Value |
|-------|-------|
| Captured | 2026-11-06T14:30:00-03:00 |
| Status | new |
| Origin | local project reference, preferably an existing anonymized registry key |

## Need

Invoke the application's tool with its flags and positional arguments intact.

## Evidence

The selected entry point and its argument forwarding were inspected.
For this use case, one required argument was not preserved.
The project-local investigation contains the reproduction and source paths.

## Current approach

A direct invocation satisfied the immediate task. Its result was checked.

## Possible reuse

Other projects invoke the same tool through ASC.
Improving the existing entry point may be sufficient; a new action is undecided.
```

The evidence must distinguish what was inspected, attempted, and verified. If the workaround was not run or did not succeed, say so. Do not claim the absence of an implementation merely because one expected filename was missing.

An origin must be useful enough for later investigation. Reference the owning project, a local note, a relevant source revision, or an existing registry key. Do not create an anonymization registry just to satisfy every record; use existing references when available and preserve private detail in its owning instance. An unavailable source can be marked unavailable without inventing supporting evidence.

No required recurrence count, confidence score, complete command transcript, exhaustive list of actions searched, or predetermined extension point. Optional related-record links are enough to preserve recurrence.

## 6. Capture procedure and threshold

### 6.1 When to record

Record a concise observation when there is concrete evidence of at least one of these:

- A missing capability with credible reuse potential.
- Repeated workarounds, copied commands, or project overrides expressing the same underlying need.
- An existing action whose behavior, argument handling, discoverability, or documentation materially hinders the operation.
- A cumbersome composition that a smaller change could improve.
- A skill that does not activate when relevant, activates on unrelated work, points at stale resources, or gives a procedure whose checks do not support its outcome.
- A durable user correction exposing one of these problems, when capture is permitted by the owning instance's policy.

A first observation can qualify. Recurrence strengthens the evidence; it is not a mandatory three-occurrence threshold. Conversely, repetition alone does not prove that a generic implementation is desirable.

Skip ordinary file inspection, successful routine action use, already represented observations from the same investigation, unsupported wishes for optimization, and one-off edits with no broader implication. A sandbox failure alone is a permissions issue; follow the applicable approval process before diagnosing the action as unsuitable. Repeated permission friction can be recorded as such, without claiming missing ASC functionality.

### 6.2 Proposed operating sequence

1. Identify the ASC tree owning the task. Read its instructions and the applicable skill.
2. Discover and inspect the relevant implementations as the action-priority skill already requires. Keep stale inventories and disabled extensions distinct from absent implementations.
3. Perform the authorized task through the suitable action or narrow fallback. Capture can happen earlier if the evidence is already clear, but must not become a prerequisite for completing the task.
4. Decide whether the observation meets the threshold. Keep one record for one independently reviewable need; combine several symptoms when they share that need.
5. Briefly check for an obvious related record when the inbox is small and accessible. Do not scan the entire backlog on every action. With concurrent sessions, a new linked observation is safer than silently editing another writer's record.
6. Write a complete, sanitized record if capture is authorized and the destination is writable. Verify the path and contents before reporting it as saved.
7. Mention the saved path only when useful in the task report. No mandatory `skip` messages and no ritual entry for every command.

### 6.3 Automatic capture is a policy choice

The user selected the storage and requested this plan; they have not yet selected a permanent automatic-capture policy.

Recommended policy for a later approved rollout: automatically save qualifying, concise observations under the agreed host root without asking for each record. The skill supplies this bounded procedure; the owning instance's instructions can disable capture or narrow its scope. Approval of this plan's text alone must not be presented as an already installed policy.

Do not respond to restricted host-state access by bypassing sandbox permissions. If a required approval is unavailable, retain a concise pending observation in the task report, or use a project-local destination already authorized by that instance. Do not invent a new persistent fallback store silently, lose the original task, or claim capture succeeded. Once access and policy are established, avoid repeatedly asking permission for the same authorized capture behavior.

## 7. Review and placement on the genericity scale

Review is explicit work requested by the user, or a later separately configured routine. No schedule is installed by this plan.

For a selected record or small batch:

1. Recover the evidence and recheck current implementations. The implementation or skill may have changed since capture.
2. Relate observations describing the same need. Keep originals as evidence; no automatic deletion or global deduplication service.
3. Decide whether the issue concerns discovery, documentation, a procedure, validation, an implementation, or composition. Several may apply.
4. Compare improving an existing implementation with adding a new one. Prefer the smaller sufficient change. State the actual deficiency and intended benefit before claiming optimization.
5. Choose the appropriate ownership and extension points using the README's genericity scale and lookup rules.
6. Record the review outcome. Create a plan only when the need and proposed work justify it. Link that plan back to the observations.

| Likely reusable scope | Candidate destination for an approved change |
|-----------------------|------------------------------------------------|
| Implementation relevant across ASC projects | Core or an opt-in core extension, according to the existing contract and scope. |
| Reusable concrete tool implementation | `scripts/asc/contrib/asc/$extension/` or `scripts/asc/contrib/$vendor/$extension/`. |
| Project-specific behavior | `scripts/asc/extend/` in the owning instance. |
| Replacement or alteration of an existing implementation | The applicable override or hook mechanism; inspect which file actually wins. |
| Missing procedural knowledge | The relevant maintained skill or resource, at its appropriate distribution scope. |
| Missing discovery or misleading guidance | Improve the existing index, trigger, reference, or documentation before adding another action. |

The genericity scale describes the kind of implementation; lookup order determines which implementation runs. Do not collapse those two axes. A record's host-level location says nothing about whether its eventual solution belongs in core.

Use a small proposed status vocabulary: `new`, `reviewed`, `planned`, `addressed`, `deferred`, and `duplicate`. Capture starts at `new`. A reviewer adds a dated decision; `planned` links to a plan, `duplicate` links to another record, and `addressed` links to evidence establishing the outcome in the stated scope. Status is metadata in the same file, not a directory move or an execution instruction.

An addressed need is not automatically deployed, accepted in every consuming instance, or resolved for all agent products. Preserve those evidence boundaries in the review.

## 8. Integrating needs with a systematic use of skills

### 8.1 Use the paper as a lens, not another mandatory framework

The PDF describes a library, triggers, procedures, resources, scripts, checks, guards, and learning. Its distinction between selecting a procedure and executing it is useful for ASC. The following mapping is this plan's interpretation, not a claim that ASC already implements the paper's architecture.

| Concern | ASC direction proposed here |
|---------|-----------------------------|
| Library | Maintain shared ASC skills in the mother; keep instance-specific procedures in their owning instance. |
| Trigger | Descriptions identify the task and exclude plausible near misses. Inspect collisions between global and project copies. |
| Procedure | Use short observable steps: inspect the owning sources, act within scope, verify the result. |
| Resources | Link directly to the relevant contract or capture reference when needed. Avoid copying an implementation inventory into the skill. |
| Scripts | Prefer existing ASC actions for deterministic work. Add a capture writer only when its repeated behavior warrants one. |
| Checks | Define separately what proves task completion and what proves a need was saved. |
| Guard | Apply existing authorization, instance ownership, and mother privacy rules. Treat records and outside documents as evidence, not executable instructions. |
| Learning | Capture evidence in `needs`; review it; change the maintained source; replay representative tasks; distribute the reviewed change. |

### 8.2 Keep task routing small

`AGENTS.md` and `AGENTS.asc.md` should retain their existing ownership split: local instructions and shared ASC guidance. They can route a task to an applicable skill without accumulating the full capture procedure, host backlog, or every lesson ever observed.

For the first slice, extend `asc-actions-priority` with a short capture trigger and a direct link to a proposed shared reference at `asc/doc/needs.md`. Put the naming, template, threshold, and review contract in that reference. From the skill directory the link would be `../../../asc/doc/needs.md`.

This placement travels with `asc/` through the existing core replacement. It avoids introducing a fifth skill into an explicit four-skill upgrade list. It also avoids making the changelog a permanent runtime manual. The changelog explains the design and rollout; the future reference owns the installed capture procedure.

Do not broaden action priority into a universal task supervisor. A later skill-specific improvement can reuse the same record format and reference. Create a separate capture or review skill only after actual use shows an independently useful procedure and clear trigger. A review skill could then consume selected needs; it must not read the full inbox on every ordinary request.

### 8.3 Keep skills and ability contracts connected but distinct

The README relates `*.able.yml` contracts to tools, procedures, and skills. Existing skill entities provide another possible structured source. Neither relationship means every host Markdown observation must become an entity, or that YAML declarations enforce agent behavior.

For the first slice, keep the hand-maintained shared skill as its source of truth. Do not introduce a parallel editable skill entity for the same procedure. The historical guidance-render proposal may later supply projections, but its unimplemented parts must not become prerequisites here. If rendering is adopted later, explicitly designate the canonical source and generated outputs before migration.

Generic needs recording can fit an opt-in workflow extension if a substantial writer is later justified. Do not add `gap.entity.yml`, move knowledge-management orchestration into core, or rename the existing `idea` type as a shortcut. A future `need` entity would require a real use case for discovery or relationships and a separately reviewed storage contract compatible with host Markdown.

### 8.4 Make learning selective and reviewable

The paper encourages durable feedback. ASC should adapt that into a review step before changing shared behavior. A correction may call for a local output fix, updated reference, script assertion, narrower trigger, or improved action. It does not necessarily call for another permanent checklist line.

Proposed progression:

1. Ordinary work produces an observation.
2. A need preserves the observation and its origin.
3. Review selects the smallest justified change and its owning source.
4. Authorized implementation changes that source and adds appropriate evidence.
5. Representative replays check both desired behavior and near misses.
6. The change is published and distributed through the normal, separately authorized process.

No automatic rewriting of mother skills from a client session, no adding instructions to a global memory file as a substitute for source ownership, and no per-step memory-edit ritual. Do not copy every correction into both a skill and the README.

### 8.5 Evaluate behavior, not just skill formatting

Use a small set of real, sanitized cases to validate routing, execution, and capture separately. Observe which instruction and skill files were actually loaded. A global copy may otherwise hide a broken project copy; merely producing the expected answer is inconclusive.

Vary the wording of legitimate requests and include nearby tasks that should not trigger ASC capture. Keep a representative input stable while testing a description change. After procedure changes, check the output and execution evidence as well. Repeat a flaky case in fresh sessions rather than treating one successful run as proof of reliable routing.

Do not adopt the PDF's fixed scores, retention periods, numeric token estimates, or universal retry limits as ASC requirements. Select proportionate checks for the change. No telemetry collection, per-action run log, dashboard, mandatory subagent, or automatic retirement policy is needed for this inbox.

## 9. Privacy, ownership, and distribution

- Host records stay local by default. They may aggregate observations across private projects, so the directory is not public mother content and must not be included in skill synchronization.
- Keep client-identifying details, private reproduction material, and raw logs in their owning repository. Use a generic statement plus a permitted origin reference in host state. Creating a record never authorizes copying credentials or private evidence.
- Mother-bound plans contain generic requirements and neutral examples. Before transfer, use the owning instance's privacy procedure and the mother guard. A local reference in a need is not safe to publish automatically.
- Shared skill copies distribute procedure, not records. Upgrading the mother, a project, or the home instance must not clear needs. The shared state is outside `asc/`, generated caches, and skill directories.
- The home instance has two roles: ASC project and possible source of user-wide discoverable skills. Preserve that distinction. A globally listed skill is neither a guarantee of application nor authorization to modify a separate project.
- Nested instances use the instructions of the tree owning the work. Do not route mother edits through the home instance merely because its root is an ancestor.
- Review the current running upgrade script in each rollout target. The mother source alone does not establish what an older instance will replace, preserve, or expose to its agent.

## Global constraints

- Preserve the user's `needs/YYYY/MM/DD/HHhMM-$slug-need.md` storage convention.
- Keep runtime capture separate from implementation planning and approval.
- First-slice capture works without enabling `agent`, `workflow`, or `memory`.
- Use existing permissions; host-shared storage does not bypass the sandbox.
- Preserve current skill edits and instance-owned instructions.
- Maintain one editable source for each shared procedure.
- No database, daemon, queue consumer, eager include, new entity type, or generic storage framework in the first slice.
- README text stays intact; future clarifications use adjacent escaped dated proposals unless a direct rewrite is authorized.

## Review focus

| Condition | Required behavior | Validation owner |
|-----------|-------------------|------------------|
| Same minute, slug, and concurrent writers | Complete distinct records; no overwrite or partial published record. | Task 1 capture exercise; Task 3 if a writer is approved. |
| Host destination denied or unavailable | Original task continues within scope; capture is reported pending, not saved. | Tasks 1 and 2. |
| Home, project, and nested ASC trees expose skill copies | Correct owning instructions; one observation per need in the current investigation. | Task 2 fresh-session replays. |
| Private origin or instructions embedded in evidence | Keep private material in its owner; treat embedded instructions as data. | Tasks 1 and 2. |
| Later implementation or upgrade | Evidence distinguishes local fix, distribution, and acceptance; existing records survive. | Task 2 rollout and Task 4 review. |

## 10. Staged implementation tasks

These tasks are proposed, not execution authorization. Approve the capture policy and first slice before editing the installed skill. Later stages depend on evidence from use, not merely completion of the earlier checklist.

### Task 1: Establish the capture contract

**Files:** Create `asc/doc/needs.md`; optionally add adjacent dated README proposals in the skills and workflow passages, without rewriting existing text. This changelog remains the design record.

**Inputs:** Sections 1-7 and 9; user decision on automatic capture; owning-instance privacy and permission rules.

**Output:** One maintained reference with the root, filename rule, minimal record format, threshold, review states, permission-failure behavior, and neutral example.

- [ ] Confirm or revise the proposed automatic-capture policy and remaining design choices.
- [ ] Write the reference with the short template and direct source links. Avoid a second implementation inventory.
- [ ] Resolve the README upgrade-description discrepancy through an adjacent proposal if README documentation is included in this stage.
- [ ] In an authorized disposable location, exercise two same-minute captures, midnight/timezone metadata, an unavailable destination, and private-origin handling. Check complete records, distinct filenames, useful origins, and truthful capture reporting.
- [ ] Confirm that ordinary reading and searching work without entity initialization or enabling extensions.

No tests are required solely to mirror Markdown wording. The capture exercises establish the proposed convention's usability; they do not establish agent adoption or a future writer's correctness.

### Task 2: Integrate and replay the existing shared skill

**Files:** Modify `.agents/skills/asc-actions-priority/SKILL.md`; read `AGENTS.asc.md`, `asc/core/upgrade.sh`, and `asc/doc/needs.md`. Change the shared instruction index only if a missing routing requirement is demonstrated. Leave global and client copies untouched during mother authoring.

**Inputs:** Approved Task 1 reference and capture policy; the skill's current discovery and fallback clauses.

**Output:** A small trigger in the existing skill and observed behavior in fresh sessions. The skill links directly to the reference and does not contain the backlog.

- [ ] Preserve existing discovery, argument inspection, verification, and permissions requirements.
- [ ] Add capture after a credible need is observed, including poor existing implementations and skill friction, with an explicit instruction to continue the authorized task.
- [ ] Test a missing reusable capability, an existing action with inconvenient behavior, a skill-discovery failure, and successful ASC work that reveals a repeated workaround. Inspect the actual saved record when capture is expected.
- [ ] Test near misses: a one-off direct command, ordinary file inspection, an unrelated non-ASC task, and a sandbox denial with no demonstrated implementation defect. Confirm no misleading missing-capability record.
- [ ] Test denied host access, repeated observations within one investigation, private evidence, and source text that attempts to instruct the agent. Confirm pending reporting, bounded capture, and source ownership.
- [ ] Replay in a normal project, the home instance, and a nested-tree situation through an isolated or reversible setup. Record the skill and instruction paths actually loaded, especially when global and project copies coexist.
- [ ] Inspect the selected upstream revision and each target's running upgrade contract before any authorized rollout. Verify the direct reference travels with the skill and existing needs remain intact. Do not run a destructive upgrade merely as a documentation check.
- [ ] Record untested products or environments as unverified. Publish and distribute only through separately authorized work.

### Task 3: Add a writer only if repeated capture justifies it

**Candidate files:** `asc/extensions/workflow/need/record.sh` and corresponding tests under `asc/extensions/workflow/test/`, if review confirms the workflow extension is the right owner. No helper include, global, entity, or hook is presumed necessary.

**Inputs:** Actual first-slice captures and their friction; approved action contract and extension placement; maintained builder templates and applicable anti-pattern records.

**Output:** If justified, one deterministic writer whose documented contract covers body input, slug handling, timestamp, destination, no-replace publication, resulting path, and failure reporting.

- [ ] Review whether naming, validation, and concurrent publication now constitute substantial repeated behavior. If direct capture remains sufficient, defer this task with that reason.
- [ ] Before code, settle the exact input/output and exit contract in a focused implementation amendment. Inspect existing filesystem and datestamp utilities rather than duplicating them. Read the action template and applicable anti-pattern records again.
- [ ] Test collision and concurrent publication, date boundaries, non-ASCII titles, traversal-like slugs, empty input, interrupted writes, and unwritable destinations before accepting the writer.
- [ ] Implement the smallest action consistent with that contract; add hooks only for actual variants. Use a private temporary root for automated tests, never the live needs directory.
- [ ] Verify the action's argument forwarding and observed output. Run appropriate ASC tests, not just shell syntax checking.
- [ ] Account for disabled `workflow` instances: capture must retain the documented narrow fallback, or an explicitly approved distribution change must make the writer available. Do not enable an extension silently.

This task is intentionally conditional. The exact writer API is not ready for execution until the amendment is reviewed; the first slice does not depend on it.

### Task 4: Review an initial batch and evaluate the feedback loop

**Files:** Selected local need records and, only if warranted, new plans in the owning repositories. Shared skill or code changes require their own authorized implementation scope.

**Inputs:** A small real batch, current source behavior, and the approved review procedure.

**Output:** Dated review decisions with evidence, related-record links, and a justified destination for any selected change.

- [ ] Review a mixed batch containing a discovery problem, an implementation limitation, a skill problem, a duplicate, and an observation that needs no change.
- [ ] Recheck source behavior and distinguish independent recurrence from repeated logging of the same event.
- [ ] Choose the minimal intervention and its scope. Leave placement undecided where evidence is insufficient rather than forcing a core action.
- [ ] Link any new plan back to its needs, using private references only within their owning repositories. Record deferred or already-satisfied outcomes without inventing work.
- [ ] For an implemented improvement, replay the originating case and relevant near misses. Mark the need addressed only within the verified scope.
- [ ] Assess whether capture was brief, useful across projects, and quiet during routine success. Refine the reference or trigger if noise outweighed useful observations.
- [ ] Consider a dedicated review skill or structured need entity only if the batch demonstrates a procedure or relationship that the current format cannot adequately express.

## 11. Acceptance and limits

The first slice is accepted when an authorized ordinary ASC task can save a concise qualifying need at the shared dated path, continue its work, and leave enough evidence for a later reviewer to choose a minimal improvement. Ordinary tasks and near misses remain quiet; denied writes are reported truthfully; private details remain in their owning instance.

Systematic skill use is demonstrated by observed routing, relevant source reads, appropriate actions, and verified results in the replay cases. A well-formed `SKILL.md`, an installed copy, or a checklist ticked without evidence is insufficient.

The broader feedback loop is demonstrated only after at least one reviewed need leads to a justified change or a supported decision that no change is necessary. Capture alone does not establish improvement. Local replay does not establish behavior in every ASC instance, agent product, or future version.

## 12. Status of this changelog work

- [x] Record the user's terminology and dated host-storage choice.
- [x] Inspect the current action-priority skill, README, registry, skill rendering, extension configuration, and upgrade source.
- [x] Read the linked skill-library PDF and separate its proposals from current ASC behavior.
- [x] Describe the capture convention, review procedure, genericity decisions, skill integration, and staged validation.
- [ ] Approve or revise the proposed design and capture policy.
- [ ] Implement and validate Task 1 and Task 2.
- [ ] Reassess the conditional writer and later review tooling from actual use.

Writing this plan does not enable automatic capture, create the host inbox, modify shared skills or instructions, change gates, synchronize instances, or authorize publication.
