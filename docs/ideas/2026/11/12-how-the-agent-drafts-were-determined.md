# How the November agent drafts were determined

- **Date:** 2026-11-12
- **Status:** process record. It authorizes nothing. It does not change the drafts, the control plan, or the revival note.
- **Subject:** the session of 2026-11-11 that filled four empty spec files and wrote seven idea notes, and how later documents used that result.
- **Drafts this explains:** [agent threads](../../../specs/asc/agent-threads.md), [agent chats](../../../specs/asc/agent-chats.md), [agent plans](../../../specs/asc/agent-plans.md), [agent skills](../../../specs/asc/agent-skills.md), and the seven idea notes listed in §8.
- **Later documents that consume those drafts:** [thread control before agent-plan](../../../plans/2026/11/11-thread-control-before-agent-plan.md), [preliminary minimal agent control](11-preliminary-minimal-agent-control.md), and the Projet Complexe revival note named in §11. Those three were not sources of the drafts. They were written after, and they add material the 2026-11-11 session did not have.

## 0. Redaction, before anything else

This note is a working record. It names every place that was opened, including paths outside this repository, because the request for it asked for that list and said a later pass would decide what to remove before any publication.

Present on purpose, and worth a redaction pass:

- Absolute paths under the home directory. They contain a personal name.
- The local literature review path in §4.2. It contains a volume identifier.
- The path of the sibling research repository in §4.4 and §11.
- Shelf filenames. They are the author's private review notes, not mother content.

Not copied into this note, and not present in the four specs or the seven idea notes:

- Network addresses, hardware addresses, and account identifiers from the home rules.
- Mail addresses, ticket identifiers, and quotations from private chats.
- The contents of product transcripts. Shapes and path patterns only.
- The filename of the one YAML under `data/entities/host/`. It was flagged during the session as something to verify against the README fixture before treating it as public. The string is not repeated here.

A search of the four specs and seven idea notes, on the day they were written, found none of the withheld categories. Relative links inside the mother tree all resolved. That search is not a publication approval.

## 1. The request that started the session

The workspace was the public mother, `Documents/asc`. Four files under `docs/specs/asc/` existed and were empty, untracked: `agent-chats.md`, `agent-plans.md`, `agent-skills.md`, `agent-threads.md`. `documentation.md` was already there and had status `current`.

The request was documentation only:

1. In each empty spec, a terse but thorough recap of contracts and spec ideas about data formats, data flows, and storage, including unsettled decisions. Specs may carry `status` in front matter to say they are unstable. They should record contracts, formats, locations, and naming.
2. The point of the recap was to start deciding two things that were not yet decided: where a running agent is recorded when work may happen on this laptop (a local decision model) and on a LAN inference endpoint (a small computer serving a larger model), and which control actions are missing (list, stop, queue, prioritise).
3. Gates, next-steps files, and host-level storage such as the needs inbox were to stay marked unsettled.
4. Improvements and alternatives were welcome. The bias to apply was: lightweight, delegate to existing tools, and steer coding agents away from extra abstractions.
5. Detailed explanations and ideas found along the way were to go into as many new files as needed under `docs/ideas/2026/11/`.
6. Own research on top of the existing reviews was allowed.

What the request did not authorize, and what the session did not do: editing `README.md`, committing, pushing, creating a branch or worktree, enabling the `agent` extension, or implementing any of the leans.

## 2. Rules that changed the shape of the result

These were applied before writing, and they are why the specs look the way they do.

**Document homes.** [documentation.md](../../../specs/asc/documentation.md) puts exploration in `docs/ideas/YYYY/MM/DD-subject.md` and shared contracts in `docs/specs/asc/subject.md`. Specs use `draft | current | superseded | retired`. A spec must separate required behavior, observed implementation, limitations, and proposed changes. That is why each spec is built as observed / proposed / not decided, and why the comparisons live in idea notes instead of inside the specs.

**Status means nothing about permission.** The same spec says a `ready` plan does not authorize execution. Every draft says the same about its own proposals.

**README stays human text.** Concepts were read from `README.md` and not redefined. Where the README and the code disagree, the disagreement was recorded as a loose end, not repaired.

**Mother guard.** Client names, ticket ids, private hostnames, domains, docroots, and mail addresses do not go into mother files. Review notes that live outside the repository were mined for generic constraints (laptop as control plane, nothing listens, JSONL append-only, timer not broker) and cited without their private path in the specs. This process note is the exception the later request asked for: the path list is here, in one file, for a redaction pass.

**Pull before planning.** A gap survey of ASC parts is supposed to start with `git -C` pull of the mother. The work tree was already dirty: `changelog/README.md` deleted, `CHANGELOG.md` untracked, and the four empty spec files untracked. The rule says to stop and leave the checkout. No pull was run. The drafts describe the dirty tree of 2026-11-11, not a freshly pulled upstream. That limit is still true.

**No second model, no branch.** Workers inherited the session model. No feature branch was created. The files were written on the branch that was already checked out.

**English in the files.** The specs and idea notes are English, matching the documentation convention. The session's closing message to the operator was French, because that was the language of the running chat at the end. The files were not translated afterward.

**Header shape was not unified.** Existing ideas use a status line, a bullet list, or a field table. The new ideas use the bullet list, close to `11-agent-skills-manager.md`. The four specs use YAML front matter (`status: draft`, `updated: 2026-11-11`) because the request asked for a status field in front matter. `documentation.md` itself uses a plain `Status:` line. That inconsistency is recorded in the loose-ends note and was left in place. Unifying it would have been an edit to a current spec, which was out of scope.

## 3. Order of work

The session did not write first and read second. The order was:

1. Read the documentation spec, the README, the gates specimen, the next-steps files, and the agent-plan design, enough to know the vocabulary.
2. Count the AI review shelves. They were about three megabytes of markdown. Reading them in the main session would have crowded out the code. Six workers were started, with no model override, each told to separate observed fact, proposal, and external claim, and to answer the two questions (where a run is recorded, which control verbs are missing). They did not write files.
3. While they ran, the main session read the thread and log implementation, the agent extension entry points, the upgrade script, and the plans named in §4.1.
4. When the workers returned, their reports were treated as leads. Claims that became sentences in a spec were re-checked in the mother tree with a file read or a search. Claims about the home directory and about product stores were not re-opened file by file in the main session; the specs mark those as external or as observations from one host.
5. Web pages were fetched for tools the reviews named and for the headless command lines the chat contract would wrap. Each page is labeled external in the idea notes. Nothing from those pages was executed except the one systemd probe in §6.
6. A second systemd probe, meant to list and stop a live unit, was blocked by the session's own review of tool use. It was not retried and not worked around. List and stop of a live unit stayed "documented, not tested."
7. Seven idea notes were written first, specs second, so the specs could link to the reasoning instead of containing it.
8. While writing, several statements were checked again and corrected. The corrections are in §9. They matter because a few of them change what "observed" is allowed to mean.
9. Before the closing message: a relative-link check on the eleven new files, a search for the withheld categories, and a read of `git status`. No commit.

## 4. Everything that was reviewed

"Reviewed" has three strengths, and the drafts depend on keeping them apart.

- **Read in the main session.** A file was opened or searched, and a sentence in a spec rests on that.
- **Read by a worker.** The worker's report was the source. The main session did not re-read the whole file. Where a spec states such a point as observed, it was re-checked; where it states it as a review constraint, it was not.
- **Not opened.** Named by a worker or a plan, then left alone. The drafts do not describe these as fact.

### 4.1 Mother tree, read in the main session

Documentation and orientation:

- `README.md`, in full. Used for the open status items (workflow stabilization, agents not implemented), the TODO data directories (`data/entities/queue`, `data/entities/thread`, `data/logs`, `data/skills`, `data/prompts`), the canonical dated-file pattern, the non-goals, and the skills section. Disagreements with the code were listed, not fixed.
- `docs/specs/asc/documentation.md`. Document homes, status words, the rule that readiness is not authorization, and the stale relative links noted in §9.
- `AGENTS.md`, `AGENTS.asc.md`.
- `.agents/skills/asc-actions-priority/SKILL.md`, `asc-author-code/SKILL.md`, `asc-author-docs/SKILL.md`, `asc-mother-guard/SKILL.md`. Front matter and line counts only, plus the routing text of `AGENTS.asc.md`.
- `asc/core/upgrade.sh`. Swap list and the `AGENTS.md` / `AGENTS.asc.md` behavior. The `.claude/skills` link is present as comments.
- `.asc_extensions_ignore`. `agent`, `crontab`, `workflow`, and others are ignored in the mother.
- `.gitignore`, enough to confirm `data/threads/` and `data/logs/` are ignored.
- `gates.core.yml`, `SPECIMEN.gates.yml`. The specimen is the shape quoted in the plans spec. `gates.core.yml` was read far enough to see that real rows already use `docs/plans/...` in the `changelog:` key, while the specimen still says `changelog/YYYY/MM/DD-example.md`. The spec quotes the specimen and then says the key still names a note path that now lives under `docs/plans/`. Both are true. The specimen was not "fixed" to match the live file.
- `NEXT_STEPS.core.md`, `NEXT_STEPS.agent.core.md`, `NEXT_STEPS.agent.dev.md`. Presence and the generated-section names. Not every row.
- `asc/doc/next_steps.sh`. Default scan directory `changelog`, taken from the variable default near the top of the file.

Plans read closely enough to lift a contract:

- `docs/plans/2026/11/10-agent-plan-cursor-codex-ollaya.md`, as that path existed on 2026-11-11. Sections 1 through 8, the decisions table, and the failure table. This is the source of the chat JSON, the review JSON, `plan-is`, staging, promotion, and isolation. It was re-read in slices while the chats spec and the plans spec were being written, not trusted from the first pass. On 2026-11-12 that design note is at `docs/ideas/2026/11/10-agent-plan-cursor-codex-ollaya.md`, and the plans directory keeps the implementation plan only. The chats spec's related link was retargeted to the ideas path sometime after the writing session. This process note does not re-audit every edit made to the drafts after 2026-11-11.
- `docs/plans/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md`. The file map, the minimality paragraph, and the "Do not create" list. Those three are why the drift note treats a file map and a negative list as the cheapest guards already in use.
- `docs/plans/2026/11/06-host-needs-and-skill-feedback.md`. The inbox path, the record shape, the status words, and the sentence that says the inbox is not a queue. Also the citation of `asc/extensions/agent/skill/`, which the tree does not contain. That citation is a loose end, not a feature.
- `docs/plans/2026/11/06-simplify-disk-entities-contracts.md`. The empty-file counts (25 entity files, 126 ability files, 17 and 122 of them empty), the competing host directories, and the datestamp spellings. The counts were re-found by search while writing the drift note, so the numbers in that note match the plan's own paragraph, not a fresh count.
- `docs/plans/2026/09/27-desktop-agent-terminal-reply.md`. Outcomes `accepted`, `not sent`, `delivery unknown`, and the instruction not to write a session database.
- `docs/plans/2026/09/30-asc-guidance-as-project-skills.md`. The proposed layout table and the discovery paragraph. The plan says this checkout has a `.claude/skills` link. The tree does not. Recorded as a loose end.
- `docs/plans/2026/09/22-xdg-state-store.md`. Opening only. The accepted path is `$HOME/.local/state/asc/registry`.
- `docs/plans/2026/09/27-backlog-priority.md`. Opening only. It is a reading order for dated notes, and it says it is not a second permanent queue.

Plans and files identified, then not re-read line by line. They are linked from the specs because the workers or the first pass established that they hold the relevant decision, not because every paragraph was in the session context:

- `docs/plans/2026/09/22-workflow.md`, `09/22-gates-like-env.md`, `09/22-gates-registry-alternative.md`, `09/22-gates-prune-approved-work.md`, `09/22-doc-next-steps.md`, `09/22-next-steps-like-env.md`, `09/22-agent-llm-entry-point.md`.
- `docs/plans/2026/09/25-concert-order.md`.
- `docs/plans/2026/09/20-host-scan-project-instances.md`.
- `docs/plans/2026/09/28-agent-instructions-travel.md` (headings), `09/27-agent-guidance-from-antipatterns.md`, `09/26-patterns-and-antipatterns.md`.
- `docs/ideas/2026/11/10-gates-and-next-steps.md`, `11-agent-skills-manager.md`, `11-host-software-provisioning.md`, `11-llm-space-evaluation.md`. The skills-manager idea was read through the proposed entry points. The other two were identified and not used as contracts. LLM Space was linked from the chats spec as a related evaluation, not as a source of fields.

Code read or searched:

- `asc/thread/thread.wrap.sh`, `asc/thread/thread.inc.sh` (`f_thread_yml_write` key list, `f_thread_host_publish`, `f_thread_host_index_dir`, `f_thread_pileup_should_skip`, the exit codes 75, 126, 130).
- `asc/thread/list.sh`, `asc/thread/status.sh` (exit 0, 2, 1), `asc/thread/batch.sh` (exit 1 on bad invocation only; the "worst exit of the wave" claim comes from the file's own contract comment and was not re-executed).
- `asc/thread/monitor.hook.sh`, `asc/extensions/crontab/thread/monitor.every-1m.crontab.yml`, `asc/extensions/crontab/cron/run.hook.sh` (the `thread-monitor` branch and the call to `hook_ms` on `thread` / `monitor`).
- `asc/log/log.wrap.sh`, `asc/log/storage.hook.sh` (the sidecar line and the `nohup` launch), `asc/log/rotate.sh` (default 1048576 bytes, rotation to `.1` and `.2`).
- `asc/instance/logged/thread.sh`, `loop.sh`, `batch.sh`, `chain.sh`, `pipe.sh`, `sequence.sh`.
- `asc/instance/chain.sh` exists. `asc/loop/` does not. `asc/extensions/agent/agent/wrap.sh` does not. Confirmed by listing.
- `asc/extensions/agent/` tree: `agent/*.sh`, `chat/*.sh`, `prompt/generate.sh`, `prompt/refine.sh`, `instance/logged_agent.sh`, `llm/llm.entity.yml` (empty), `agent/agent.entity.yml` (not empty; synonyms only, not treated as a contract).
- `asc/thread/thread.entity.yml`, `sidecar.able.yml`, `sidecar.sh` are empty.
- `scripts/asc/contrib/asc/{claude,codex,cursor,ollama,ollaya}/` contain only `.gitkeep`.
- `asc/core/global.vars.sh` synonym list: `logged-thread/lt`, `logged-batch/lb`, `logged-chain/lc`, `logged-sequence/ls`, `logged-loop/ll`, `logged-pipe/lp`.
- `data/entities/anti-pattern/asc/hook_call_existence.md`, opening only, to see the "don't / do" shape.
- `data/` top level: `asc`, `entities`, `logs`, `test-results`, `threads`, `tmp`. No `data/entities/queue/`, no `data/entities/thread/`, no `data/skills/`.

Not read as prose, though named by the README or by plans: `asc/make/call_wrap.make.sh` beyond what the agent-plan document quotes about quote stripping; `asc/core/hook.manual-inc.sh`; the body of `thread-pipe` and `thread-sequence`; `asc/extensions/workflow/` entity files. The plans spec does not claim behavior for those beyond what the agent-plan document already states.

### 4.2 AI review shelves

These were not read end to end in the main session. Six workers mined them. The specs never link this path. They absorb the constraints that survived comparison across shelves. Where two shelves disagreed, the idea notes say so instead of picking a winner. The revival note's §20 describes the same mining and is consistent with this list.

Agentic shelf, `agentic-ai, rag, retrieval, packing, workflow, anonymization/`:

| File | What was taken, if anything |
|---|---|
| `00-map-of-the-shelf-and-selection-criteria.md` | Scope of the shelf. Not a contract. |
| `01-harness-doctrine-hooks-tools-skills-mcp.md` | Hooks as the extension point. MCP is a transport, not a control plane. A model does not own the scheduler. |
| `02-context-packing-clr-triage-observability.md` | Per-call trace sketches. OSC 7501 as a status signal a program may emit. These became "optional, only when something reads it," not a required field. |
| `03-retrieval-rag-graph-rag-hybrid-cascade.md` | Not used. Retrieval is outside the four specs. |
| `04-memory-claims-gaps-and-the-research-loop.md` | Verification basis: reported, observed, inferred, unknown. Taken into the record-conventions note as a rule for status words, not as a trace schema. |
| `05-routing-cascading-local-inference-modest-hardware.md` | A technology entry has an endpoint and a way to turn it off. The LAN box is a tier, not a brand, and is disabled until wanted. Decision models are one-shot CLI calls, not a daemon bound for the network. |
| `06-agentic-software-work-specs-evals-cli-ergonomics.md` | Plan gates, a reviewer from another model family, external plan-file conventions. Used as alternatives in the plans spec, not as the ASC plan format. |
| `07-injection-redaction-anonymization-at-the-llm-boundary.md` | Not used for these drafts. Redaction of prompts is a different spec. |
| `08-language-multilingual-nlp-and-publish.md` | Not used. |
| `09-industry-folklore-and-drift-what-to-refuse.md` | The refuse list: named runtime, gateway, agent-owned scheduler, multi-agent topology by default, a YAML schema the shell cannot read. "Record the need before picking a mechanism." This is the backbone of the drift note and of the control-actions table. |
| `10-synthesis-v6-delta-strategy-and-staged-roadmap.md` | Staged roadmap. Not copied. The drafts refuse the stage that needs a listener. |

Data-store shelf, `data stores, databases, wiki, plain file storage (md, json, yaml)/`:

| File | What was taken, if anything |
|---|---|
| `00-map-of-the-shelf-and-selection-criteria.md` | Scope only. |
| `01-files-as-system-of-record-plain-text-formats-and-layout.md` | Format rule: Markdown for prose, YAML for human-edited structure, JSONL for machine append, JSON for one object between processes. Front-matter key lists were not adopted. "Path is not the id" was recorded as a candidate rule and then limited: plans and ideas do not move, so their path is a fine id. |
| `02-postgresql-as-derived-store-schema-bitemporal-roles-migrations.md` | Not used. A derived database is the central store the drafts refuse. |
| `03-search-indexes-meilisearch-pgvector-sqlite-fts5-embeddings-lifecycle.md` | Not used. |
| `04-wiki-second-brain-knowledge-graphs-argument-maps-and-interop.md` | Not used, except as a reminder that a second brain is a different project. The README already says complex agent work belongs in a dedicated instance. |
| `05-traces-ledgers-evals-and-logs-as-data-retention-and-analytics.md` | The JSONL envelope, one file per day per writer, no lock, append a supersession instead of rewriting, trailing partial line ignored, a model never writes a trace line. DuckDB over the files was recorded as a later reader, not as a store. This shelf also contradicts itself on roll policy and on whether the path token is host, instance, or writer. The record-conventions note keeps that contradiction open. |
| `06-synthesis-data-architecture-v6-delta-and-rebuild-first-roadmap.md` | Used only to see which of the above the shelf itself still treated as open. |

Devops shelf, `devops, linux, servers, networking, hosting, security, privacy/`:

| File | What was taken, if anything |
|---|---|
| `00-map-of-the-shelf-and-selection-criteria.md` | Scope only. |
| `01-topology-what-runs-where-compose-k3s-argocd-and-parity.md` | Three places: the laptop, the LAN, a remote server. The laptop is the control plane. The LAN box is stateless inference. Agent work stays on the laptop. A cluster on the box is on the refuse list. |
| `02-debian-13-workstation-and-lan-inference-box-systemd-jobs-local-models-sync.md` | `systemd --user` timers, transient units, slices, `journalctl` as "that a job ran," JSONL as "what it did." The canonical `systemd-run` line in the reviews uses a `pc-` prefix; the drafts do not adopt that prefix. They use it as evidence that the tool already exists. |
| `03-networking-and-remote-access-vpn-mesh-dns-tls-ingress-and-exposing-nothing.md` | Nothing listens. Remote access is SSH, initiated from the laptop. A mesh address for an inference API is configuration, not a run record. |
| `04-security-and-privacy-operations-secrets-keys-container-hardening-supply-chain-gdpr-lgpd.md` | Sandbox is `bwrap` plus a kernel mechanism the reviews name; the drafts keep `bwrap` because the agent-plan document already specifies it, and they do not add the kernel mechanism. Unattended agent runs are not allowed yet. That sentence is a review position, not a new policy written by the session. |
| `05-operations-backups-restore-drills-observability-energy-and-the-runbook-habit.md` | Journald stays local. Logs are not shipped. The host thread index is the kind of thing backups should treat as disposable. |
| `06-synthesis-the-recommended-stack-remediations-and-place-staged-roadmap.md` | Used to check that the shelf's own summary still says pull, not push, and still refuses a daemon on the box. |

Worker split, so a later reader can see who was responsible for which compression:

| Worker id | Scope |
|---|---|
| `0f3eea7e-234e-49de-8375-0886c310e716` | Agentic shelf, harness, traces, skills doctrine |
| `0ea14097-eca5-4230-9ea1-0073b053c58e` | Agentic shelf, routing, specs, drift, refuse list |
| `ce2adec8-84bb-4e7d-98fd-17ef57e8b583` | Data-store shelf |
| `b809299c-b664-42ab-a636-4206f81860e4` | Devops shelf |
| `8f625038-b578-4224-8da7-df576675d434` | Projet Complexe repository |
| `07a02da8-fbc5-4949-a18a-3aedaeb618f1` | Home directory as an ASC instance, and the product stores on that host |

These ids are taken from the compacted session summary of that chat. A search of the transcript file on 2026-11-12 did not find them, because that file does not retain tool results. Treat the ids as summary records. The workers were `explore` or general-purpose, blocking, and they inherited the session model. No worker was given a different model.

### 4.3 External pages read that day

Fetched or searched on 2026-11-11. None of these tools was installed. None of these commands was run, except `systemd-run` as described in §6.

| Topic | Page | What entered the drafts |
|---|---|---|
| Remote user systemd | systemd issue 24261, and the `systemd-stdio-bridge` manual | `systemctl --user --host=` is refused. Another machine is `ssh` then `systemctl --user` on that machine. This killed the idea of a native cross-host unit view. |
| User manager on the same host | systemd issues 11216 and 44071, issue 22674 | `--machine=user@.host` exists and is brittle. Not proposed. |
| Queue tools | `pueue` command list; a comparison table published by the `spoolctl` project | Feature grid in the queue note. Marked as a vendor comparing itself. `pueue` is the only one that covers queue, priority, groups, and stop. It is also a daemon. The lean is not to install it yet. |
| Agent Skills format | `agentskills.io` specification and the reference validator | The front-matter table in the skills spec. Required `name` and `description`. `name` must match the directory. Unknown fields: the reference validator rejects them; some products ignore them. The spec says both. |
| OpenTelemetry GenAI | semantic-conventions agent spans, attribute registry | Names for a future export mapping only: `gen_ai.conversation.id`, `gen_ai.provider.name`, `gen_ai.operation.name`. Status of that convention was Development. Not a reason to rename ASC fields. |
| Cursor CLI | Cursor parameters and headless docs, plus two third-party notes | `agent -p --output-format json`, `session_id`, `--resume`. Third-party event tables were not promoted to the spec. The spec keeps identifier, continue, and final text. |
| Codex | ChatGPT non-interactive mode docs, plus two third-party notes | `codex exec --json`, `thread.started` / `thread_id`, `codex exec resume`. |
| Claude Code | sessions and CLI reference | `claude -p --output-format json`, `--resume`, transcript path pattern. One open report that a resumed run prints a new id. The spec says keep the id from the first turn. |
| Ollaya | CLI reference, quickstart, model list | `ollaya run … --format json` prints a decision response. The CLI starts its own server when none answers. The named large model and the named small computer from the original request do not appear as Ollaya models. The drafts therefore treat "LAN endpoint" as a provider, and do not write those product names into a schema. |
| herdr-core | project page and command reference | `hc machine add` over SSH, `hc ls` across machines, OSC 7501 with states `idle`, `working`, `done`, `blocked`, `error`. Study only. A new daemon from a young project. |
| `AGENTS.md` | agents.md, the Agentic AI Foundation note, Codex discovery docs | No required fields. Closest file wins, except that products concatenate differently. The spec says test the products in use. |
| AgentTrail | README and the PLAN.md convention notes | Checkbox marks `[ ]`, `[~]`, `[x]`, `[!]`, `needs:`, `files:`. Recorded as an alternative plan shape, not adopted. AgentTrail reads product logs and does not run agents. That supported "do not write a parser." |

Pages that were fetched in full into the session's tool cache and then not mined line by line: the Microsoft Learn copy of the Agent Skills page, the long OpenTelemetry span page, the Claude CLI reference dump. The tables in the specs come from the specification pages and the vendor summaries above, not from those dumps.

### 4.4 Projet Complexe, as it stood that day

Repository: `/home/paul/Documents/projet-complexe`. A worker read it. The main session did not re-read it file by file.

What was taken:

- ASC is authoritative about execution. That project is authoritative about interpretation. The drafts stay on the execution side.
- Proposed event names (`thread.started`, `thread.finished`, and others) and a small envelope. Not adopted. The drafts refuse a second event protocol beside the thread record.
- The laptop remains the control plane. A LAN box is a technology provider, not a host and not a memory.
- Named pivots `run-agent`, `inspect-agent`, `stop-agent` were a sketch. The control-actions note rejects duplicating `thread-*` with `agent-*`.
- Layout there (`data/ideas/`, `data/research/`, `data/changes/`) is that project's. It was not proposed for the mother.

What was not taken: any private chat export, any personal name, any mail address. A raw explanation file was known to exist and was not quoted.

The revival note in §11 did not exist yet as a source. It was written later and cites the drafts.

### 4.5 Home directory as an ASC instance

The home directory is itself an ASC instance. A worker surveyed it. The main session did not re-walk it. Categories, not values:

- `asc/thread` and `asc/log` matched the mother. The same gaps apply there.
- The home crontab still called a `cron-run` target the mother no longer has, so the minute-by-minute thread monitor was effectively dead.
- The host index had a handful of files, including at least one ghost `running` record. No gates file and no next-steps file at the home root.
- `$HOME/.local/state/asc/registry/host/` was empty.
- Cursor transcripts, Cursor plans, Cursor hooks, Codex session JSONL, Codex SQLite (threads, spawn edges, a queue of pending items), Ollama as a system unit on loopback. Claude Code was not installed. Ollaya was not installed. A separate agent product was installed under its own directory and was not made part of the contracts.
- Tools present: systemd 257, `flock`, `bwrap`, `jq`, `journalctl`, cron, Python with a sqlite module. Lingering was off. User timers: none.
- Tools absent: `tmux`, `tsp`, `pueue`, `nq`, `at`, the `sqlite3` and `yq` and `duckdb` command-line tools. `sshd` was inactive. Avahi was active.

The absent-tool list is why the queue note can say "not installed, not reviewed by running them" and still compare them from documentation. It is also why a lean that needs `pueue` or `duckdb` is a provisioning change, not a config change.

Older home documents, `docs/monitoring.md` and `docs/observability.md` in that instance, describe a logging layout (`emitter` / `receiver` / dated directories) and a systemd user unit per long loop. None of those paths exist now. They were treated as abandoned design, not as a contract to revive. The `ll` synonym still points at a loop wrapper that is gone, which is the same residue.

The home rules file contains a block describing a rented server (address, hardware address, provider). That block was not copied and was not used. The drafts do not discuss that server. Cross-host in the drafts means "a second machine that starts ASC entry points," which the reviews locate on the LAN, not on that server.

### 4.6 What was deliberately not reviewed

- The body of every dated plan from September. The index was listed. Only the files in §4.1 were opened.
- Test fixtures under `data/test-results/frozen/`.
- `asc/vendor/**`.
- Product transcript contents. Path patterns and one description of line shape from the worker.
- Whether `foobar` in the README and the host-entity filename are the same string. Left as a human check.
- Upstream, because the pull was skipped.
- Any live `agent-plan`, Cursor, Codex, or Claude invocation.

## 5. The two questions, and the answers the files actually give

The request asked where running agents are recorded, and which controls are missing. The drafts do not settle either. They split each question until a small next step fell out. That split is the main intellectual result of the session. Later documents adopted it.

### 5.1 Three things were being called one thing

A thread is a process tree started from a make entry on one host. ASC already writes its record.

A session is a conversation owned by Cursor, Codex, or Claude Code. It outlives any process. The product already stores it. Copying it would create a second database the desktop-reply plan had already forbidden.

A model server is Ollama, Ollaya, or a LAN endpoint. It is a service. `agent-start` and `agent-stop` already mean "load and unload a model," which is why those names are a trap: a reader thinks they control a run.

A decision-model call lasts milliseconds and returns JSON. It is a line in the caller's trace, not a run. That is why Ollaya does not appear in the thread spec as a location of state.

This split is why the four files exist as four files. Threads, chats, plans, and skills were empty filenames chosen before the session. The session kept all four, but it refused to let "agent" become a fifth record type that mixes the four.

### 5.2 The LAN box is not a second ASC host

The motivating example was a laptop running a decision model, and a small computer on the LAN serving a larger model. Every shelf, and the Projet Complexe notes, already said the laptop is the control plane and the box serves inference. The session added only the consequence: a thread that calls the box still runs on the laptop, so its record is local. A cross-host record is needed only when a second machine starts `make` entry points itself. Designing a unified store for the motivating example would have built the thing the reviews refuse.

The schema consequence is in the threads spec: the endpoint is a provider selected by hook variant or by configuration, and the brand is not a field. The original request named a device and a model. Those names are not in the specs. They are not Ollaya models, and a schema that contains a brand has to change when the box changes.

### 5.3 What the code already records, and why it cannot answer the question

Observed, and re-checked in the files named in §4.1:

- One YAML per entry, overwritten. Keys are the list in the threads spec. There is no `run_id` and no `host`.
- Timestamps are local, with milliseconds, and without a numeric offset.
- The host index is sixteen hex characters of sha256 of `docroot::entry`, under `$HOME/.local/share/asc/threads/`, with seven fields, also overwritten.
- It is rewritten on every YAML write, and healed only by the `thread` `monitor` hook. The only caller of that hook found was the crontab extension, which the mother ignores. So with defaults the index is written and never corrected.
- Liveness is `kill -0` on the recorded pid. A reused pid looks alive.
- The log sidecar appends one launch line and never an end line.
- The wrapped command is backgrounded. The log path uses `nohup`. The thread path uses a backgrounded subshell. Neither creates a process group for the tree. The recorded pid is the supervising subshell. `tree` is a snapshot of `pid:comm` at start.
- `thread-status` exits 0, 2, or 1. There is no stop action.
- `ASC_THREAD_LOCK_MODE=wait` blocks on `flock`. Waiters are processes. A reboot drops them. Order among waiters is not guaranteed.

That list is why "add a database of agents" was not the proposal. The record exists. It is latest-only, local, and unsupervised. The smallest change that makes it mergeable is three fields: run id, host, offset. Everything else (history, another host, a stop that means something) needs those three first. That is option A in the run-tracking note, and it is recommendation 2 of the later revival note.

### 5.4 Why systemd was the candidate supervisor, and why it was not adopted

The reviews already contained a `systemd-run --user` line, slices, and "the journal says that it ran." The session checked the part that decides whether ASC must still keep its own record:

- A throwaway unit returned the child's exit code through `--wait`.
- The journal stored start, the child's output, the exit status, and a result, queryable as JSON by `USER_UNIT=` and by a custom field set with `LogExtraFields=`.
- `USER_INVOCATION_ID` is a per-start id. That is a free run id if the supervisor is a unit.
- `--collect` removed the unit after it failed. Nothing named `asc-probe-*` remained in the unit list.

Documented and not tested: `list-units` with a pattern, `stop` of a cgroup, `Nice=` and slices as priority, `RuntimeMaxSec=` as a time limit. The second probe that would have tested list and stop was blocked and not replaced with a weaker command.

Limits that kept this as a candidate rather than a decision:

- Lingering was off on the host. A user unit's survival of logout was not claimed.
- Unit state is runtime. History is the journal, which is capped and local. Whether that cap is acceptable is an open question, not a yes.
- Remote `--user` is refused. Cross-host stays SSH.
- No TTY, so an interactive harness session does not fit this supervisor.
- Hosts without systemd still need today's wrapper. Two implementations, selected by the existing `hook_ms` variant on `HOST_OS`, which is how `log` `storage` is already chosen. The session did not pretend that variant selection is free.

The lean written down: do the three fields now; try one transient unit on one long entry before writing a JSONL ledger; if the journal answers "what ran today," do not add the ledger on systemd hosts. The later control plan accepts the three fields and turns the unit trial into a probe task. It does not make units the default. See §11.

### 5.5 Stop is the missing verb

List, status, batch, sequence, pipe, and retry already exist. Queue and priority do not, but they also do not have a demonstrated waiting list. Stop has a demonstrated hole: a harness starts shells and further agents, and killing the recorded pid leaves them.

The control-actions note gives two mechanisms and does not pick:

- Without systemd: `setsid`, record the process group, signal the group. Children that change group escape. The note says so.
- With systemd: one cgroup per unit. This is the strongest argument for transient units, and it is an argument, not a measurement. The later plan's probe is the measurement that was missing.

The note also says the wrapper must write a final status itself after a stop. Leaving `running` for a cron sweep to notice is how the ghost records in the home index happened. The sweep is optional. The final write is not.

Stopping the process does not end the product session. That was deliberate. Resume stays a product feature.

### 5.6 Two queues, so that neither gets built by accident

The word "queue" was doing two jobs.

The work-item queue is an ordered list of things a human has accepted as worth doing. Gates rows already have `lane` and `order`. Next-steps files already have sections. The needs plan already says the inbox is not a queue. `plan-is 'ready'` already says it does not authorize. So the missing piece at this level is a decision among files that exist, which is the question in `10-gates-and-next-steps.md`. The session did not answer it. Answering it would have chosen a backlog design the request said was unsettled.

The process queue is commands waiting for a slot. Today that is `flock` in `wait` mode, and it loses the waiters on reboot. `pueue` would cover it. A spool directory and a timer would be the start of a home-made broker, which the reviews refuse unless a named need exists. One model on one GPU is already a slot the model server serialises. Codex already queues pending turns in its own SQLite. None of that is a customer for an ASC queue.

"Priority" split the same way. Which work item goes first is `order:` in a backlog. Which process gets the CPU is `nice` or a slice. The stated discomfort (an agent build should not starve the editor) is the second. It needs no queue.

The words suggested, and not adopted as code, were "backlog" and "queue."

### 5.7 Chats: a pointer, not a store

The agent-plan document had already fixed the turn JSON: one object on stdout, `chat_id` and `provider_session_id` nullable, status `completed | failed | empty_reply`, orchestrator error `missing_result_json`. The session did not reopen that schema. It asked where the object lives after the process exits.

Four candidates, in the chats spec: nowhere but stdout; a field on the thread record; a pointer file per chat; a line in a ledger. The lean was stdout now, a field on the thread when a thread first drives a chat, and a pointer file only when a second run must resume a chat by an ASC name. Starting with the pointer file would have been the session database the earlier plan forbade.

`chat_id` versus `provider_session_id` was left open because the plan has both and never says whether they are the same string. `chat-read` and `chat-archive` have no implementation and, under a pointer-only design, may not need one. The spec says so instead of inventing a behavior.

Headless command lines were checked so the JSON contract is something the three products can actually fill: each returns an id and a final text, and each can resume. The details differ. The spec's rule is one hook per product and role, using `hook_ms` as it exists. No adapter layer. That rule is the agent-plan document's minimality paragraph, applied to chats.

### 5.8 Plans: four questions, four files

The plans spec's opening table is the session's reading of the agent-plan document, the gates specimen, and the needs plan, put side by side:

| Question | Answered by |
|---|---|
| What does the work need? | the plan |
| What did the reviewer find? | the review JSON, bound to a digest |
| Is this revision ready for a named step? | `plan-is 'ready'` |
| May the step start? | gates, or a direct human instruction |

Nothing in the session merged those. Merging them is how a plan status becomes a silent go-ahead. The documentation spec already forbids that for the word `ready`. The drafts repeat it for `yes`.

The prerequisites block, the staging lock, the isolation modes, and the answer JSON are copied in condensed form from the agent-plan document. They are labeled proposed. The session did not audit that document for implementability. Where the session added anything, it was the surrounding files: gates shape, next-steps files, needs inbox, and the statement that product plan files under the home directory are foreign artefacts.

### 5.9 Skills: a brief a human writes

Observed layout matched the guidance-as-skills plan: `.agents/skills/$id/SKILL.md`, `AGENTS.asc.md` for shared routing, `AGENTS.md` owned by the instance. Upgrade replaces four named skill directories and `AGENTS.asc.md`, and leaves `AGENTS.md` alone. The README says the opposite about `AGENTS.md`. The skills spec states the script. The loose-ends note states the disagreement.

The published Agent Skills format was checked so the spec would not invent front-matter fields. The four mother skills already conform to the required pair `name` and `description`. Optional fields were not added.

The needs plan's render path (`skill.entity.yml`, `skill/render.sh`, hooks that write product skill files) is not in the mother. A worker reported it on the home instance. The reviews had reversed that design: the hand-written `SKILL.md` is the source, and ability files are empty candidates for deletion. The skills spec records the structured source as a rejected earlier idea, not as a plan. Install and uninstall remain the proposal in `11-agent-skills-manager.md`, with the constraints that note already had: install only into an absent directory, uninstall only an owned unmodified copy, do not take over the four upgraded directories.

`docs/specs/asc/` is on the upgrade swap list. The four drafts will be copied into every instance, where their relative links to `docs/plans/` and `docs/ideas/` do not resolve. The loose-ends note says a spec that travels should stand without those links. The drafts do not yet. They were written to be read in the mother, next to the idea notes. That is a known defect, not an oversight discovered later.

### 5.10 Drift, as a constraint on the other files

The request asked that the work steer agents away from extra abstractions. The drift note is the collection of practices that already do that in this tree, plus four proposed additions that were not written into a skill:

- A "Do not create" list. Already in the agent-plan implementation plan.
- A file map. Same plan.
- Selection through `hook_ms`, stated as a prohibition on a new selection API. Same plan, section 1.
- Existence rules in the authoring skill, and anti-pattern records with a don't and a do.

The additions the session proposed and did not apply:

- One line per capability: which existing tool does this, and what ASC adds. The control-actions table is that line, repeated. Half the rows end in "no new action."
- A budget of new files, globals, and entry points, declared before writing.
- "Would deleting this change behavior?" as a review question.
- A new stored thing needs a named reader and a named writer in the same change.
- Prefer a field, then a file, then a directory, then a service. Applied to tracking: `run_id` is a field, a ledger is a file, a host tree is a directory, a queue daemon is a service. Stop at the first level that answers the question.

The empty-file counts from the simplify plan are the evidence that the last two rules would have mattered. They are not a claim that the session deleted anything.

## 6. The systemd probe, exactly

One command was run, from `/tmp`, so it would not write into the repository.

A transient user unit named `asc-probe-` plus a timestamp was started with `systemd-run --user --unit=… --collect --wait --quiet`, a description, `LogExtraFields=ASC_RUN=$unit`, the same value in the environment, and `bash -c 'echo hello from probe; exit 3'`.

Observed:

- The command's exit code was 3.
- `journalctl --user ASC_RUN=$unit -o json` returned records. One of them carried `ASC_RUN`.
- Filtering by `USER_UNIT=$unit.service` returned four records: started, the echo line, the main process exited with status 3, and the unit failed with result `exit-code`.
- Those records included `USER_INVOCATION_ID`, `EXIT_STATUS` of `3`, and `UNIT_RESULT` of `exit-code`.
- After `--collect`, `systemctl --user list-units 'asc-probe-*'` printed nothing.

Not observed, because the follow-up command was blocked and not reissued:

- `list-units` while a unit is still running.
- `systemctl --user show` of a live unit.
- `systemctl --user stop` of a live unit.
- Whether a child started with `setsid` dies with the unit. The later control plan's Task 3 is this experiment, and it had not been run when this note was written.

The unit name and the journal lines remain in the user journal of that host. They contain the probe string and a generic description. They do not contain repository files.

Systemd on that host was 257. That version is a fact about one machine, not a contract.

## 7. How a sentence earned its way into a spec

A sentence was allowed into a spec only if it fell into one of four bins. This is the rule that determined the current text, more than any particular source.

| Bin | Wording in the specs | Source required |
|---|---|---|
| Observed | "Observed" in the opening, and a table of keys or actions | A file in the mother tree, re-read or searched that day |
| Proposed | "Proposed" | A plan or idea already in the mother, or a lean the session wrote and labeled as a lean |
| External | "External" | A vendor page or a product file pattern. Marked as changing without notice |
| Not decided | The closing table of each spec | Two or more candidates, neither implemented |

What that rule excluded:

- Worker reports about product file formats, until the path pattern was either seen by the worker on the host or documented by the vendor. The chats spec says "external" for both, and the session-stores note says which host was inspected.
- Performance numbers for models. None were measured. None are in the drafts.
- A recommended architecture diagram. The request asked for contracts. The comparisons stayed in idea notes.
- New pivot names as if they existed. `thread-stop`, `skill-install`, and `llm-*` appear as candidates. The threads spec's action table contains only actions whose scripts exist.
- Exit-code tables borrowed from the reviews (usage 2, policy 3, budget 4, and so on). They collide with `thread-status` and with the desktop-reply exits. The record-conventions note says each action documents its own codes until two actions must agree. The later control plan follows that: it defines exits for `thread-stop` and for hold refusal only.

The specs are shorter than the idea notes on purpose. A reader who treats a spec as the decision will miss the leans. A reader who treats a lean as a decision will miss the "not decided" table. Both misreadings were anticipated. The opening paragraph of each spec says nothing proposed is approved.

## 8. The eleven files, and what each one is for

Written on 2026-11-11, untracked, not committed.

| File | Lines at the time of writing | Job |
|---|---|---|
| `docs/specs/asc/agent-threads.md` | 121 | Record, index, log, actions, limits, and the candidate table |
| `docs/specs/asc/agent-chats.md` | 118 | Entry points, turn JSON, desktop outcomes, product stores, headless commands |
| `docs/specs/asc/agent-plans.md` | 219 | Plan file, `agent-plan`, review JSON, `plan-is`, gates, next-steps, needs |
| `docs/specs/asc/agent-skills.md` | 107 | Layout, format, upgrade, discovery, install proposal |
| `docs/ideas/2026/11/11-agent-run-tracking.md` | 157 | Options A through F and the cross-host lean |
| `docs/ideas/2026/11/11-agent-control-actions.md` | 77 | Verb table, stop, hold file, the `agent-*` naming trap |
| `docs/ideas/2026/11/11-agent-queue-and-priority.md` | 93 | Backlog versus process queue, tool grid |
| `docs/ideas/2026/11/11-agent-session-stores.md` | 89 | Product stores and where a turn result should live |
| `docs/ideas/2026/11/11-record-conventions.md` | 111 | Time, id, host, directories, status words, exit codes, formats |
| `docs/ideas/2026/11/11-agent-drift-guardrails.md` | 82 | Practices and proposed additions, none applied |
| `docs/ideas/2026/11/11-agent-tracking-loose-ends.md` | 48 | Mismatches found while checking |

Line counts are from `wc -l` that day, including the skills-manager note which was already there and was not rewritten. The loose-ends note gained two bullets after the skills spec was written (the missing `.claude/skills` link, and the missing `skill/` directory). The count above is after that edit.

Why seven notes and not one: the request said as many as were useful, and a single note would have mixed a record format with a product survey with a list of bugs. The specs link to the note that holds the reasoning for each open row. A later decision can supersede one note without rewriting the others.

Why the loose ends are an idea and not a fix list: each one is a behavior change or a documentation change that was outside the request. Fixing the `ll` synonym, the missing `wrap.sh`, or the links in `documentation.md` would have been a code or spec edit with its own review. Listing them was the way to keep them from being forgotten without pretending they had been fixed.

## 9. Corrections made during writing

These are the places where the first draft of a sentence was wrong, and the file on disk is the corrected one. A later reader who compares the session's rough notes with the files should expect these differences.

| First version | Correction | Why it matters |
|---|---|---|
| `logged-chain` described as a log wrap around a thread action of the same name | It wraps `asc/instance/chain.sh` | The other `logged-*` actions wrap `asc/thread/`. Chain does not. The threads spec says so. |
| The wrapped command is `nohup … &` in every path | The log storage hook uses `nohup`. The thread wrapper backgrounds a subshell. The recorded pid is that subshell | Stop design depends on which pid was recorded. The control-actions note was edited to say this. |
| "17 empty entity files and 122 empty ability files" as a fresh count | Those numbers are the simplify plan's count, re-found by search in that plan | The drift note does not claim a new census. |
| A paraphrase of the XDG state-directory definition presented as a quotation | Rewritten as a description of what the specification says | The record-conventions note must not invent a quote. |
| The guidance-as-skills plan's claim of a `.claude/skills` link, repeated as fact | The mother has no `.claude/` directory, and the link step in `upgrade.sh` is commented out | Discovery for Claude Code is not set up in the mother. |
| The needs plan's `skill/render.sh`, repeated as a mother file | The mother's `agent` extension has no `skill/` directory | A render pipeline is not an observed mother feature. It may exist on an instance. The spec does not say it does. |
| Anti-pattern records described as "a bad example and a good example" | The file that was opened uses the headings "don't" and "do" | The drift note uses the file's own words. |
| A second systemd probe as evidence of list and stop | Not run | Those verbs stay documented, not tested. |

One correction that was not a factual error but a scope cut: the threads spec's first action row for `logged-chain` was written, then replaced in a follow-up edit the same day. The file on disk is the replacement.

## 10. Leans, in one place

These are the session's judgements. They are written into the idea notes as leans and into the specs as the preferred row of an open table. They are not decisions. The later plan and the revival note repeat most of them. Repeating them there still does not approve them.

1. Record runs, not "agents." The ASC record is a thread. The session is a pointer. The model server is a probe.
2. Add `run_id`, `host`, and a numeric UTC offset before adding any new store.
3. Prefer `$started_compact-$pid` as the run id until a unit's invocation id is actually available. Do not take a dependency on `uuidgen`.
4. Try the journal as history before writing a JSONL ledger. If a ledger is written, extend the sidecar before adding a host-level tree.
5. Try one transient user unit on one long entry before building a stop that kills a single pid. A cgroup is the reliable form of stop. It is not yet shown.
6. Keep `flock`. Do not install a queue tool until a waiting list exists. If one does, try `pueue` before writing a spool.
7. Weight (`nice`, slices) is the priority that has a customer. `order:` is backlog priority, and only after the backlog file is chosen.
8. Do not answer the gates versus next-steps question inside the tracking work.
9. Readiness, `yes`, and `go` stay three different answers. `unknown` is never coerced to `yes`.
10. Stdout JSON is the turn contract. No transcript database. No adapter above `hook_ms`.
11. One hook per product and role. `CHAT_ROLE` for `new` and `reply`. `CHAT_TYPE` for `read` and `archive`, renamed from `chat_TYPE` only when those actions are touched.
12. Move provider lifecycle names toward `llm-*` when they are next edited. Leave `thread-*` for runs. Do not add `agent-run` beside `thread-wrap`.
13. A hold file that the wrapper refuses to start under is the smallest "stop all," and it does not stop work already running.
14. Emit OSC 7501 only when something on the host reads it.
15. Skills stay hand-written. Do not revive a renderer. Do not build `skill-install` until a specific skill needs it.
16. A new file needs a reader and a writer in the same change. A new service needs a refused alternative that was actually tried.
17. The model never writes the record. The wrapper does.
18. Nothing listens. A timer may start work a human already authorized. SSH may pull another host's files. No broker, no collector, no LAN run registry.
19. Git-ignore is part of the design. Thread records, logs, and any listing of product stores contain project names and arguments. They do not enter a shared repository.
20. Unattended agent runs stay disallowed until a human changes that. The drafts do not change it. Tracking design should not outrun it.

## 11. How the three later documents relate to these leans

This section is the bridge the request for this note asked for. It was checked against the three documents on 2026-11-12. It is a reading of them, not a claim that their authors adopted every row.

### 11.1 Preliminary minimal agent control

File: `docs/ideas/2026/11/11-preliminary-minimal-agent-control.md`.

It takes the three-way split and the operation dependency: before a real long-running `agent-plan` loop is operated, an operator can identify the run, refuse new starts, and stop a running instance with a known result. It says host checks and isolated tests may proceed meanwhile. That matches leans 1, 5, 13, and 20, and it matches the scope cut in the control-actions note.

It then adds a survey the 2026-11-11 drafts did not contain: DeerFlow, DeepSeek Harness, Goose, Aider, OpenHands, and Hermes, including source at named revisions. Those sections orient the same leans (stop is not rollback, a session id is not authorization, sandbox is not process stop, a settled result with a reason). They are not evidence that the drafts were derived from those codebases. Anyone using this note as a source list should not add those repositories to §4. They belong to the later idea.

The idea's own "next useful steps" are the sequence the control plan then writes as tasks. The idea says it stays the orientation and the plan is not a go-ahead.

### 11.2 Thread control before `agent-plan`

File: `docs/plans/2026/11/11-thread-control-before-agent-plan.md`.

This is the first document that turns a subset of the leans into a proposed contract with a file map. It is explicit that the contract is not an implementation go-ahead, and that if a task needs a daemon, a ledger, or a second supervisor, the plan stops.

What it takes from the drafts and makes specific:

| Draft lean | Form in the plan |
|---|---|
| `run_id` as compact time plus pid | UTC `date -u +%Y%m%dT%H%M%S`, then `-$pid` of the supervisor. Written in `f_thread_yml_write` |
| `host` | `hostname -s`, only in untracked thread files and the host index |
| Offset | `date +%Y-%m-%dT%H:%M:%S.%3N%:z` on `started_ms`, `ended_ms`, and the index `mtime` |
| Pid reuse | New key `pid_start`, field 22 of `/proc/$pid/stat`. Liveness requires the start field to match. Empty means liveness `unknown` |
| Stop | `thread-stop`, two forms: with `run:` and without. Exit 0 means the procedure finished, including when completeness is `degraded` or `unknown`. Exit 2 means the named run is no longer current |
| Hold | `data/threads/hold`, taken under a new `data/threads/admit.lock`, in the foreground, before the supervisor is backgrounded. Exit 3 on refusal. A hold does not cancel a start that has already passed that point |
| Final record | `final`, `final_writer` (`supervisor` or `stop`), `stop_reason`, `completeness` (`cgroup`, `degraded`, `unknown`). The supervisor trap is not trusted to survive `SIGKILL` |
| Systemd | A probe task, using `sleep` and `setsid`, with `KillMode=control-group`. Not the default supervisor. A failed probe does not authorize the long loop under a process-group fallback |
| No queue, no ledger, no chat copy, no `agent-*` rename, no gates change | Stated as global constraints |

What the plan found that the drafts missed:

- The foreground wrapper can exit 0 on a pile-up skip, and the per-entry lock is taken inside the function that then runs in the background. A hold refusal has to be decided before the `&`, or the caller will not see it. The drafts said the lock exists. They did not describe this race.
- The `EXIT` trap command is `u_thread_supervisor_exit`, and the function that writes `exited` is `f_thread_supervisor_exit`. No definition of the `u_` name was found under `asc/` when the plan was written. The drafts never checked that the trap name resolves. A normal-exit test is Task 1 of the plan for that reason.
- The long `flock` cannot stay on the same file stop needs to lock, or stop waits on a lock held by the process it is trying to signal. The plan splits an occupy lock from a record mutex. The drafts did not design that.

What the plan leaves open, on purpose:

- Whether the probe's cgroup rows match. Until that note exists, completeness `cgroup` is not allowed.
- Logout survival. Lingering is recorded and not changed.
- Artifact state after stop. A later read of the plan file and of any chat pointer is a separate observation. Stop is not rollback.
- The wider exit-code table. The plan cites the record-conventions note and does not adopt it.
- Everything in leans 6, 7, 8, 11, 12, 14, and 15. The plan says those are out of its slice.

The plan tells the probe note to be written at `changelog/2026/11/11-thread-control-probe.md` when the probe runs. The documentation convention and the changelog migration put new dated notes under `docs/plans/` or `docs/ideas/`. That path is another residue of the `changelog/` default. It is not a reason to ignore the probe. It is a reason to decide the path when the probe is actually run.

### 11.3 The revival note

File, in the other repository: `/home/paul/Documents/projet-complexe/data/research/Projet Complexe 2026 Revival (v6) - ASC, Projet Complexe and Projet Complexe ASC.md`.

Its §20 says it is the long form of the four specs and the seven idea notes, plus the gates idea and the skills-manager idea. Its §4 says the thread code was checked again while that note was written. So v6 is a second compression, not an independent survey, except for the material it brings from its own earlier versions.

Its recommendations 1 through 13 match leans 1 through 19 in compressed form. Recommendation 14 points at an earlier version's list and at amendments. Those earlier recommendations were not re-derived in the 2026-11-11 session. Using v6 as a source for the drafts reverses the order.

Its §19 is the best inventory of what was still open after the drafts. Several of those rows now have a proposed answer in the control plan (run id formula, host string, hold path, stop by run id or by current run, completeness words). They are still open in the sense that the plan is not approved and the probe has not been run. The rows the plan does not touch are still open in the stronger sense: no document has proposed a contract for them.

Rows still without a contract, after all three later documents:

| Topic | State |
|---|---|
| One YAML per entry, versus one file per run | The plan keeps one file per entry and adds `run_id`. A file per run was not chosen. |
| Invocation id versus the compact id, once units exist | The plan stores `invocation_id` only when `supervisor` is `systemd-user`. The compact id remains the ASC id. |
| Which host string is safe in which files | The plan uses `hostname -s` and confines it to untracked files. A ban on tracked files is stated, not tested by a fixture. |
| One XDG tree or three | Untouched. Index stays in `.local/share`. |
| Journal cap as the only history | Untouched. The plan refuses a ledger in this slice, which leaves the journal as the only history if units are adopted, without deciding that the cap is acceptable. |
| Who is told when `needs_interactive` is set | Untouched. |
| Backlog file, `order:` as dependency or priority, next-steps generator | Untouched, by request. |
| One chat id or two; stdout versus a thread field versus a pointer file; fate of `read` and `archive` | Untouched. The preliminary idea says a chat pointer is not required for the minimum control outcome. |
| Trace envelope versus a short JSONL line versus a database | Untouched. v6 keeps the contradiction visible. The drafts refused a trace store in this pass. |
| Skill ownership record, extra front matter, Claude Code path, first `skill-install` candidate | Untouched. |
| Provider pivot rename to `llm-*` | The control plan explicitly does not do it. |
| Routing, embeddings, and the interpretive catalog in the revival note | Those are that project's. They were not inputs to the drafts. |

## 12. What would close a remaining decision

The drafts are not a menu to implement from top to bottom. Each open row has a different closer.

| Decision | What would close it | What would be the wrong closer |
|---|---|---|
| Run id, host, offset | The control plan's Task 1, on a sleeper, with the YAML round-trip checked through `f_yaml_parse` | Adopting UUIDv7 in the same change |
| Hold | Task 2 of that plan: a start in the foreground sees the hold and exits 3, and a start that has passed admission is not cancelled | A hold file with no lock, described as a guarantee |
| Stop completeness | Task 3's three descendant rows, written down with the unit properties that were actually set | Killing one pid and calling it stop |
| Journal as history | The falsifier in the revival note: `journalctl --user` answers "what ran today" for one entry, including exit code and entry name, under the host's cap | Adding a ledger in parallel "just in case" |
| Process queue | A real waiting list: more than one unattended run that must wait, on a host where the model server's own queue does not already serialize them | Installing `pueue` because the grid has an empty cell |
| Backlog | A human choice among gates, next-steps, and a checklist, recorded as its own decision | A registry key added beside the gates file |
| Chat pointer | The first caller that must resume a chat by an ASC name rather than by the provider id already on stdout | A `data/chats/` directory created with the turn JSON |
| `llm-*` rename | The next edit that touches `agent-start` or `agent-stop`, with the old names left as synonyms until callers are gone | A rename inside the control-plan slice |
| Specs that survive upgrade | Either links that still mean something in an instance, or specs that do not need the mother plans | Copying `docs/plans/` into every instance |
| Unattended operation | A human authorization that names the probe result | The existence of the probe |

## 13. Checks performed on the drafts, and the limits of those checks

On 2026-11-11, after the eleven files were written:

- Every relative link in the eleven files was resolved from the file's directory. None was broken. Links to plans that were not fully re-read still point at files that exist.
- A search of the eleven files for home directory prefixes, the local literature review, mail addresses, dotted IP addresses, hardware addresses, and the device and model names from the original request. No hits. The four specs do not discuss Ollaya as a product. The string appears in links to the agent-plan documents, which already used that name, and in the run-tracking note as the CLI that was read.
- `git status` showed the eleven files untracked, plus the pre-existing `CHANGELOG.md` untracked and `changelog/README.md` deleted. Nothing was staged.

Not done then, and not done for this process note either:

- A pull.
- A test run of any make target.
- A second pair of eyes.
- A check that `f_yaml_parse` accepts the keys the control plan later proposed. That check is the plan's Task 1, and it is still ahead.

This process note was searched, before it was handed over, for mail addresses, dotted IP addresses, and hardware-address patterns. The paths in §0, §4.2, §4.4, and §11.3 are the ones the redaction pass should look at. They are here because the request for this note asked for the review list in full.
