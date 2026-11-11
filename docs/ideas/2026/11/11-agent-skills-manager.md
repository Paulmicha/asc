# Agent skills manager

- **Date:** 2026-11-11
- **Status:** research idea / comparison; not an approved design or implementation plan
- **Scope:** ten public skill repositories and a proposed ASC skill-management capability
- **Method:** repository documentation inspected on 2026-11-11. No skill was installed or run, no benchmark was performed, and this is not a security review of the repositories.

## Decision in brief

Evaluate **Graphify** first as a disposable, derived view over a small research corpus. Consider **Cloudflare Security Audit** for a bounded review of an implemented trust boundary. Read individual **Matt Pocock** skills and test **Ponytail** on a small engineering task. Use visual skills when an actual screen, explanation, or diagram calls for them. **Superpowers is already available in the current Codex environment.**

These tools serve different purposes. A skill generally gives an agent instructions, references, or scripts; it does not automatically become a reliable subsystem in the second brain. Popularity counts in the original list are not evidence of fit or quality, and change over time. Repository descriptions and benchmark numbers below are authors' claims unless otherwise stated.

## Context and constraints

This note considers how agent skills might support software development, research, visual communication, and security review. Individual ASC instances have their own context and confidentiality requirements.

## Comparison

| Repository | Primary use | Fit | Suggested action |
|---|---|---|---|
| [Matt Pocock Skills](https://github.com/mattpocock/skills) | Composable engineering and research workflows | High for engineering; medium for knowledge work | Read and trial selected skills. |
| [Ponytail](https://github.com/DietrichGebert/ponytail) | Encourage smaller implementations | Medium–high for engineering | Compare on a bounded task with acceptance criteria. |
| [Cloudflare Security Audit](https://github.com/cloudflare/security-audit-skill) | Structured agent-assisted code security review | High for trust boundaries | Scope a targeted audit when suitable code exists. |
| [Impeccable](https://github.com/pbakaus/impeccable) | Interface design and critique | Medium for UI work | Try on a representative screen. |
| [Anatomy](https://github.com/wheresryan22/anatomy) | Interactive visual explanations | Medium–low, task-specific | Use for one concept that benefits from interaction. |
| [Diagram Design](https://github.com/cathrynlavery/diagram-design) | Styled, self-contained diagrams | Medium–high for communication | Try for an architecture or trust-boundary diagram. |
| [Graphify](https://github.com/Graphify-Labs/graphify) | Queryable graphs from project material | High for research and navigation | Run a small, isolated comparison with text search. |
| [Superpowers](https://github.com/obra/superpowers) | Development process skills | High; already available | Use selectively with existing project guidance. |
| [Taste Skill](https://github.com/Leonxlnx/taste-skill) | Frontend art direction and review | Medium for websites | Compare with Impeccable on a concrete UI. |
| [Hallmark](https://github.com/mHalo/hallmark-skill) | Themed interface design and critique | Low–medium at present | Defer until a specific design need. |

## Repository findings

### 1. Matt Pocock Skills

The [repository](https://github.com/mattpocock/skills) presents small, editable skills for engineering tasks including shaping requirements, design, testing, review, research and handoff. Their composability is attractive where a full development methodology would be too heavy. The project describes an installation route for Codex and other agents, with project setup for its engineering workflows.

**Potential use:** distill a question from the large research corpus, explore a domain model or architecture decision, or hand off a bounded task. Architecture and handoff workflows may help when navigating existing code and documentation.

**Limits:** skill names and contents evolve. Inspect the exact version and dependencies before adopting any particular skill. Compare with existing Superpowers and ASC instructions, and avoid installing overlapping bundles by default. A skill asking many questions or generating extensive artifacts may be a poor fit for a small change.

### 2. Ponytail

[Ponytail](https://github.com/DietrichGebert/ponytail) promotes simpler solutions and less unnecessary code. That is relevant to the reviews' concern with constrained resources and to keeping ASC extensions understandable. The author reports benchmark improvements in code volume, time, cost and tokens; those are author-reported results under their conditions, not measured outcomes for these projects.

**Potential use:** compare two solutions to a small ASC maintenance task. Judge whether the result meets the same behavior, test, error-handling and maintainability requirements—not just whether it has fewer lines.

**Limits:** minimal code is not a substitute for necessary validation, security checks, tests or clear boundaries. A general instruction to simplify must not override project-specific contracts.

### 3. Cloudflare Security Audit

[Cloudflare Security Audit](https://github.com/cloudflare/security-audit-skill) describes a multi-phase workflow: reconnaissance and coverage mapping, hunting, candidate validation, structured findings, independent verification and reporting. Its reference materials include AI/LLM risks, cloud and deployment, data isolation and lifecycle, and desktop/local IPC. Its findings distinguish confirmed issues, unresolved candidates and rejected candidates.

**Potential use:** review document ingestion, agent tool permissions, data isolation, local IPC, authentication paths, multisite isolation, or versioned infrastructure. A source review alone cannot establish the state of a running system.

**Limits:** the full workflow uses multiple isolated agents and may consume substantial time and tokens. Confirm that the environment supports the needed delegation and artifact locations. Specify authorized scope, avoid sending secrets or client data to unapproved services, and independently check important results. A clean report is not a security certification.

### 4. Impeccable

[Impeccable](https://github.com/pbakaus/impeccable) supplies a vocabulary and commands for designing, critiquing and polishing interfaces. It becomes useful once a project has a representative screen and real tasks to evaluate, such as finding a source, inspecting evidence, or moving between a graph and its underlying note.

**Limits:** visual polish cannot establish accessibility or retrieval quality. Check keyboard navigation, contrast, reduced motion, content density and actual task completion separately. Preserve established product constraints rather than applying a generic visual style.

### 5. Anatomy

[Anatomy](https://github.com/wheresryan22/anatomy) creates interactive isometric illustrations that explain concepts as working objects, with SVG and optional more elaborate graphics. It can support learning or public documentation, for example an interactive explanation of a retrieval pipeline, queue, cache, or indexing lifecycle.

**Limits:** an analogy can conceal important edge cases. Supply real assumptions and check the model behind any displayed values. This is not a general architecture-mapping tool. The project offers optional publication to a community gallery; private research and client information must not be published inadvertently.

### 6. Diagram Design

[Diagram Design](https://github.com/cathrynlavery/diagram-design) describes self-contained HTML/SVG diagrams with multiple diagram types and brand styling. Candidate uses include proposed control-plane boundaries, service relationships, and deployment topology.

**Limits:** styling does not verify topology. Cite or check source configuration and distinguish proposed from observed behavior. For small, maintainable in-repository diagrams, an existing Mermaid diagram may already be sufficient. Check the repository's privacy and network behavior before using brand-onboarding or export features with private material.

### 7. Graphify

[Graphify](https://github.com/Graphify-Labs/graphify) builds a queryable graph from project material, including code and documents. Its [skill documentation](https://github.com/Graphify-Labs/graphify/blob/v8/graphify/skill-aider.md) describes persistent outputs and distinguishes extracted, inferred and ambiguous relationships. That is relevant to exploring links across the literature reviews and navigating relationships between code and documentation.

**Potential use:** build a graph for a small, explicitly selected research subset, then ask real cross-document questions. Separately, a scoped codebase graph could help navigate a larger project. Treat outputs as derived artifacts that can be removed and regenerated; keep source files and scope boundaries authoritative.

**Limits and open questions:** inferred edges can be wrong or omit context; provenance labels do not independently establish correctness. Determine which files and generated excerpts may leave the machine in the actual chosen configuration. Measure indexing and refresh cost, model usage, graph staleness and answer quality. Confirm licensing, dependency behavior and exact version before installation. Do not combine personal and client corpora merely for a more connected graph.

### 8. Superpowers

[Superpowers](https://github.com/obra/superpowers) offers process skills for planning, debugging, testing and review. It is already available as a Codex plugin in the current environment; another installation is unnecessary for this evaluation.

**Potential use:** structured diagnosis and verification when the task warrants them, and planning or review for larger changes. Existing project instructions take precedence where applicable.

**Limits:** blanket process and overlapping skills can add latency, repeated questions or unnecessary artifacts. Scale the process to the task and honor the user's instructions and local project rules.

### 9. Taste Skill

[Taste Skill](https://github.com/Leonxlnx/taste-skill) emphasizes frontend art direction, reference imagery and checking work in a browser. It is potentially useful for a public project website or for comparing alternative directions for an actual app screen.

**Limits:** inspect its approach to external images and network requests before using it with private context. Its benefit for a dense personal knowledge interface is unproven; evaluate usability and accessibility, not visual novelty alone. It overlaps with Impeccable and Hallmark.

### 10. Hallmark

[Hallmark](https://github.com/mHalo/hallmark-skill) offers themes and checks intended to discourage generic generated interfaces. The number of themes described by a repository snapshot can differ from the original list, so verify the current version before relying on a count.

**Potential use:** explore a deliberate visual direction for a public page or prototype. **Priority:** lower than the other candidates while retrieval, storage and trust boundaries remain the immediate questions. Compare it against the other design skills on the same brief rather than enabling several overlapping instructions together.

## Proposed experiments

These are research options, not authorized implementation or installation decisions.

### A. Graphify versus ordinary search

1. Select a small, non-sensitive document subset. Record the source list and version, and keep personal and client material in separate scopes.
2. Before indexing, inspect the exact release, dependencies, model configuration, network behavior, output paths and deletion procedure. Choose a controlled environment and an explicit cost limit.
3. Write five to ten real questions before examining results, including cross-document questions and questions where a negative answer is possible.
4. Compare ordinary full-text search and Graphify on the same questions. Record relevant sources found, unsupported or missing links, time and cost, and whether a reader can locate the supporting passage.
5. Change or remove a source and check refresh behavior and stale edges. Delete the derived graph and verify that the original files remain intact.
6. Keep the approach only if it improves useful discovery enough to justify maintenance and privacy costs. Do not infer retrieval quality from a visually attractive graph.

### B. Bounded security review

Choose one implemented trust boundary and define in-scope paths, permitted techniques, data handling, artifact location and budget. Review the skill's current instructions and scripts. Compare findings with existing tests and configurations, reproduce material claims safely, and explicitly record unverified issues. Distinguish repository configuration from observed live state. The outcome is a prioritized evidence-backed review, not a blanket assurance.

### C. Compare interface skills

Give Impeccable and one of Taste or Hallmark the same representative screen and task. Compare keyboard access, readability, responsiveness, time, dependencies and consistency with the project's needs. Use Diagram Design or Anatomy only if a particular communication problem warrants the extra artifact. Existing Codex visualization and Figma capabilities may already cover some of these tasks.

### D. Compare engineering workflows

On a small, reversible task, compare a baseline with a single selected Matt Pocock skill or Ponytail. Hold acceptance criteria and validation constant. Record whether the result is easier to understand, its behavior and tests, interaction overhead, and maintenance cost. Avoid counting lines or tokens as the sole measure.

## Project-oriented shortlist

| Project | First candidates | Example question |
|---|---|---|
| Research-oriented project | Graphify, Security Audit, selected Matt Pocock skills | Can a graph answer cross-document questions with traceable evidence? Where are ingestion and IPC trust boundaries? |
| ASC | Ponytail, selected engineering skills, existing Superpowers | Can a bounded simplification preserve maintained ASC contracts and tests? |

## Research limitations and next decision

This note is based on repository descriptions, not a complete review of source code, licensing terms, supply-chain risk, all literature files, or the running systems. Repository capabilities and installation instructions change. No performance, privacy or compatibility claim was verified by running the candidates.

The most informative next decision is whether to run experiment A on a small sanitized corpus. Select the exact source files and evaluation questions first; then inspect and pin the tool version before any install or data processing.

## Proposed ASC skill-management entry points

### Intent and scope

An opt-in action in the existing `agent` extension could install a known agent skill into the current ASC project instance, making its complete package available under `.agents/skills/<name>/`. A complementary action could remove a skill that this mechanism installed. This is a proposal for review, not existing ASC functionality or an approved implementation.

The [ASC README](../../../../README.md) already describes the agent extension as a place for generic abstractions around agent instructions and skills. The [Compose write action](../../../../asc/extensions/compose/compose/write.sh) offers a useful precedent for an explicit action that materializes project-root files. Skills differ in one important respect: their destination can contain independently maintained files and local edits, so regeneration must not assume ownership of the whole destination.

### Naming and separation of concerns

| Proposed entry point | Intended meaning |
|---|---|
| `make skill-install foobar` | Install the known skill `foobar` in the current project instance. |
| `make skill-uninstall foobar` | Remove the instance copy when it is owned by this mechanism and has not been changed unexpectedly. |

These names are illustrative; argument forwarding and discovery must be verified before implementation. `install` and `uninstall` describe the file lifecycle more clearly than `setup`. `add` and `remove` could also be reasonable, but could mean adding or removing a declaration rather than the installed files. Avoid redundant aliases until an actual need appears.

Enabling an ASC extension and installing an agent skill are separate operations. The current extension mechanism uses `.asc_extensions_ignore` to determine which extensions are enabled. An extension could provide a skill source, but enabling the extension should not silently install that skill. Conversely, installing a skill should not silently enable an extension or imply that an agent is required to use the skill.

### Source and destination

Begin with a narrow use case: a known local skill package with a clear ASC-maintained source. Install the entire directory, including supporting references and scripts, into `.agents/skills/<name>/` relative to the current project instance docroot. Copying only `SKILL.md` can break a package that refers to other files. Whether an explicitly supplied local source is also needed should be decided from a concrete use case.

Do not assume every agent or host discovers the same directory, or that installation forces invocation. Additional agent-specific destinations, links or adapters should be considered separately and tested with the relevant agent. The home directory can itself be an ASC instance; in that case its `.agents/skills` destination may also be user-wide for some agents. The action must show the resolved destination and scope rather than presenting all instances as project-only.

Third-party acquisition adds provenance, version pinning, licensing, network access and trust concerns. It should be a separate future decision, preferably delegated to an appropriate existing installer rather than turning ASC into a general-purpose package manager. Installing a package that includes scripts also does not mean those scripts are safe or should be executed automatically.

### Ownership, collisions and removal

The destination can contain human-authored skills, existing ASC-managed skills, third-party installations and local edits. A possible first contract is:

1. **Install only into an absent destination.** If the destination already exists, report the collision and leave it untouched. Do not silently adopt existing files.
2. **Record ownership and provenance.** Associate the installed destination with its source and a version or content fingerprint. Decide whether the record belongs in committed project configuration or local state; its location and portability remain open questions.
3. **Uninstall only an owned installation.** Compare the installed package with the recorded state. If it was modified, report that fact and leave it intact until the user makes an explicit decision. Unknown or missing ownership must not authorize deletion.
4. **Handle path boundaries and symlinks explicitly.** Validate skill names and resolved paths, refuse traversal outside the intended destination, and specify how links inside or at the destination are treated.
5. **Avoid partial installations.** Define staging, failure and cleanup behavior so a failed copy or interrupted operation does not appear to be a complete installation.
6. **Keep updates separate.** A later update action must distinguish an unchanged installed copy from local customization. Re-running install must not silently overwrite a customized copy.

These are proposed behavioral requirements, not claims that ASC currently enforces them. A useful implementation would also make repeated operations and missing sources predictable, and give clear messages about the destination and the reason for refusing an operation.

### Interaction with core upgrade

The current [core upgrade script](../../../../asc/core/upgrade.sh) explicitly swaps four named ASC skill directories under `.agents/skills`; it does not treat the whole directory as one generated output. A new manager must not silently take ownership of those directories or conflict with their upgrade lifecycle. Decide whether the existing upgrade process stays authoritative or whether a separate, explicit migration is warranted.

There is a material documentation discrepancy to resolve independently: the README currently says upgrade overwrites the instance's `AGENTS.md`, whereas the current upgrade script preserves an existing file and creates one only when absent. Verify the script in the instance and selected upstream version when working on upgrade behavior; this idea does not change either source.

### Implementation shape and variants

Actions under the `agent` extension are plausible, subject to ASC action discovery and naming conventions. A direct local implementation may be sufficient for one known source and destination. A hook call becomes useful when there are real variants worth supporting, such as distinct source providers or destinations, rather than merely anticipating hypothetical flexibility. If such variants are justified, distinguish the generic action and hook call from the extension's hook implementation, and follow the existing selection and fallback contracts.

Before any code is proposed or written, inspect current builder templates, relevant anti-pattern records, enabled extensions and generated action inventories. Validate how Make forwards the skill name, how the instance is selected, and how an enabled `agent` extension exposes the action. An extension being present on disk does not establish that it is enabled or that an action is currently available.

### Open decisions and validation

- Which concrete ASC-maintained skill provides the first end-to-end use case, and where is its source maintained?
- Is installation declared in versioned project configuration, recorded only in local state, or both? How are these reconciled on another machine?
- What is the intended behavior for user edits, missing or altered ownership records, partial installs and symlinks?
- How should the mechanism interact with core upgrade and its existing managed skills?
- Is a local source sufficient, or is a separately delegated installer required? Which agent-specific discovery paths are actually needed?

A future implementation should exercise a successful install and uninstall, collisions with unmanaged files, modified installed files, invalid names, failure during installation, repeated actions, and the home-instance scope. It should also verify that enabling an extension alone does not install a skill. These tests are proposed validation, not tests run for this note.
