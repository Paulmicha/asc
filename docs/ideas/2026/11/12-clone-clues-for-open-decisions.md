# Clues from the shallow clones for the open decisions

Status: open idea
Created: 2026-11-12
Updated: 2026-11-12
Decisions: [open decisions](12-agent-spec-open-decisions.md)
Context: [preliminary minimal agent control](11-preliminary-minimal-agent-control.md)
Proposed plan cited below: [thread control before agent-plan](../../../plans/2026/11/11-thread-control-before-agent-plan.md)

Read on 2026-11-12 from the shallow clones under the mother's `data/tmp/`, plus the docs shipped in those trees. Nothing here was executed. A later pass the same day corrected three facts (Hermes skill hashes, Hermes external skill directories, the host-index reader) and qualified two inferences (what `thread-stop` names, and what the examples do not decide about run ids and schema versions). A further pass corrected DeerFlow's cross-worker cancel, the conditions on Hermes's pid check, and the one idempotent retry in the Hermes queue.

Each row below has three parts:

- **Observed.** What that revision's code or doc does.
- **Inference.** What that suggests for an ASC choice, and where the suggestion stops.
- **Still open.** The decision this does not close.

Local paths are relative to the mother checkout. Upstream links are pinned to the cloned revision. Line numbers are where the claim was read; they will move.

## Revisions

The control note inspected older revisions of several of these trees. This pass used the HEAD that was checked out. DeerFlow's cancel route and DeepSeek's stop-reason union were re-read here. The older line-by-line stop survey was not repeated. OpenHands pause and SDK interrupt paths were not re-walked.

| Tree | HEAD | Control-note revision | Upstream at this HEAD |
|---|---|---|---|
| `aider` | `5dc9490bb35f` | same | [Aider-AI/aider](https://github.com/Aider-AI/aider/tree/5dc9490bb35f) |
| `deepseek-harness` | `e8f7b93a3449` | same | [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness/tree/e8f7b93a3449) |
| `OpenHands-CLI` | `283c6ac3610f` | same | [OpenHands/OpenHands-CLI](https://github.com/OpenHands/OpenHands-CLI/tree/283c6ac3610f) |
| `open-operator` | `12615a28d0e9` | same | [OpenHands/open-operator](https://github.com/OpenHands/open-operator/tree/12615a28d0e9) |
| `deer-flow` | `04a9833763f7` | `13e6fc29e542` | [bytedance/deer-flow](https://github.com/bytedance/deer-flow/tree/04a9833763f7) |
| `goose` | `249316032104` | `392ccbf20a72` | [aaif-goose/goose](https://github.com/aaif-goose/goose/tree/249316032104) |
| `hermes-agent` | `2bfa6b07a14a` | `a84025ade22d` | [NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent/tree/2bfa6b07a14a) |
| `OpenHands` | `754abee4f086` | `2071c036fade` | [OpenHands/OpenHands](https://github.com/OpenHands/OpenHands/tree/754abee4f086) |
| `software-agent-sdk` | `10be259c4fc8` | `89469eb670b6` | [OpenHands/software-agent-sdk](https://github.com/OpenHands/software-agent-sdk/tree/10be259c4fc8) |
| `ai-engineering-coach` | `c5cfba17e732` | not in that note | [microsoft/ai-engineering-coach](https://github.com/microsoft/ai-engineering-coach/tree/c5cfba17e732) |

`open-operator` is still a catalogue. It has no run, session, or stop implementation.

## Run id

**Observed.** Hermes mints a session id as local `YYYYMMDD_HHMMSS` plus 8 hex characters (`hermes_state_ids.py`, `new_session_id`). The id does not contain the pid. `worker_claim_is_live` returns false unless the pinned run id, the claim lock, and an unexpired lease on both the task row and the run row all match (`agent/kanban_turn_recovery.py`). Pid comparison is separate. It runs only when `verify_pid` is true, which is the default. A managed worker passes `verify_pid=False` because the stored `worker_pid` names the dispatcher-spawned submitter, not the interpreter doing the check; that path uses its own `worker_bound` event for interpreter identity. When `verify_pid` is true, a stored pid that is `None` is not rejected. A stored pid that is present and different from `os.getpid()` is rejected. DeerFlow cancel takes both a thread id and a run id.

**Inference.** The checks that always run are the run id, the claim, and the unexpired lease. Pid verification is an additional check, and it can be turned off or skipped when no pid was stored. An ASC signal still needs an identity check separate from "the entry name is the one I remember": a timestamp-plus-pid id can name a run while `pid_start` or an invocation id addresses liveness, and a random id alone does not make the signal safe. The examples do not choose between those shapes.

**Still open.** Which run id ASC writes. The plan proposes `$started_compact-$pid` and `pid_start`. This note does not promote one of them over the other.

**Sources.** [hermes_state_ids.py](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/hermes_state_ids.py#L56) (`data/tmp/hermes-agent/hermes_state_ids.py`). [kanban_turn_recovery.py](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/agent/kanban_turn_recovery.py#L189) (`data/tmp/hermes-agent/agent/kanban_turn_recovery.py`). Plan: record fields and the two stop forms.

## Unit of record

**Observed.** DeerFlow keeps many runs under one thread. Hermes keeps many messages under one session, and a separate run row for a claimed kanban task.

**Inference.** One overwritten file per entry cannot represent that history. A run id on the latest record can name the current run and still drop the previous one.

**Still open.** Whether ASC needs history in the record, or only an id on the latest YAML. The plan keeps one file per entry.

**Sources.** [DeerFlow run status](https://github.com/bytedance/deer-flow/blob/04a9833763f7/backend/packages/harness/deerflow/runtime/runs/schemas.py#L21) (`data/tmp/deer-flow/backend/packages/harness/deerflow/runtime/runs/schemas.py`).

## Host field

**Observed.** DeerFlow cancel returns 404 when the run is missing or belongs to another thread. A run active on another worker is not, by itself, a conflict: `CancelOutcome.requested` durably notifies a live owner, and `taken_over` terminalizes the run when that owner's lease has expired. `lease_valid_elsewhere`, `not_active_locally`, and `not_cancellable` are the conflict outcomes (`thread_runs.py`, `cancel_run`). The worker id is not part of the run id string read here. Aider's default chat history path is `.aider.chat.history.md` inside the git root (`aider/args.py`).

**Inference.** Ownership of a run can be a field checked at stop time rather than a syllable of the id. A history file inside the repository is a path that can be committed. ASC thread records are git-ignored; Aider's default is not evidence that they should stop being ignored.

**Still open.** Which host string, and the ban on it appearing in tracked files.

**Sources.** [thread_runs.py](https://github.com/bytedance/deer-flow/blob/04a9833763f7/backend/app/gateway/routers/thread_runs.py#L1365) (`data/tmp/deer-flow/backend/app/gateway/routers/thread_runs.py`). [aider/args.py](https://github.com/Aider-AI/aider/blob/5dc9490bb35f/aider/args.py#L274) (`data/tmp/aider/aider/args.py`).

## Two chat ids, and where a turn result is kept

**Observed.** Hermes stores a Codex thread id on the Hermes session (`agent/codex_runtime.py` comments the column `sessions.model_config.codex_thread_id`). Goose exposes `provider_session_id` beside its own session id (`crates/goose/src/acp/provider.rs`). Current Goose stores the session in SQLite (`sessions.db`, schema version 18) under the data directory (`session_manager.rs`, `paths.rs`). Hermes stores session metadata and message history in `~/.hermes/state.db` (sessions doc in the clone). OpenHands persists one directory per conversation UUID (`conversation/base.py`, `get_persistence_dir`).

**Inference.** A product that owns the conversation stores the body, and a wrapper that also calls another product can store that product's id beside its own. ASC does not own the Cursor or Codex transcript. Those stores do not decide whether ASC should also keep a small turn result (the proposed stdout JSON, or a pointer) for audit or recovery. They do show that a full second transcript is what the owner keeps, not what a caller has to copy.

**Still open.** One id or two. Stdout only, a field on the thread record, a pointer file, or a ledger line. `chat-read` and `chat-archive` exist in Hermes because Hermes owns the store; that does not by itself justify ASC actions that open a provider's files.

**Sources.** [codex_runtime.py](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/agent/codex_runtime.py#L502) (`data/tmp/hermes-agent/agent/codex_runtime.py`). [provider.rs](https://github.com/aaif-goose/goose/blob/249316032104/crates/goose/src/acp/provider.rs#L682) (`data/tmp/goose/crates/goose/src/acp/provider.rs`). [session_manager.rs](https://github.com/aaif-goose/goose/blob/249316032104/crates/goose/src/session/session_manager.rs#L33) (`data/tmp/goose/crates/goose/src/session/session_manager.rs`). [paths.rs](https://github.com/aaif-goose/goose/blob/249316032104/crates/goose/src/config/paths.rs#L48) (`data/tmp/goose/crates/goose/src/config/paths.rs`). [conversation/base.py](https://github.com/OpenHands/software-agent-sdk/blob/10be259c4fc8/openhands-sdk/openhands/sdk/conversation/base.py#L366) (`data/tmp/software-agent-sdk/openhands-sdk/openhands/sdk/conversation/base.py`).

## Stop status word

**Observed.** DeepSeek's settled reason is the closed union `completed`, `cancelled`, or `error` (`packages/workflow/workflow/src/types.ts`). The count of agents started degrades to what the host observed after termination. Goose's ACP mapping includes `Cancelled`, `Refusal`, `MaxTokens`, and `EndTurn` (`crates/goose/src/acp/server.rs`, `prompt_stop_reason`). DeerFlow's run status enum is `pending`, `running`, `success`, `waiting_for_input`, `error`, `timeout`, `interrupted` (`schemas.py`).

**Inference.** Each of these uses a word that is neither success nor an undifferentiated crash. DeepSeek and Goose put that word on a reason beside a settled result. DeerFlow puts `interrupted` in the status enum. None of the three uses exit code 143 as the only signal. That does not require ASC to add a fourth status word; a `stop_reason` beside `exited` is one of the shapes present.

**Still open.** `exited` with code 143, a reason field, or a fourth status such as `stopped`.

**Sources.** [types.ts](https://github.com/deepseek-ai/deepseek-harness/blob/e8f7b93a3449/packages/workflow/workflow/src/types.ts#L57) (`data/tmp/deepseek-harness/packages/workflow/workflow/src/types.ts`). [server.rs](https://github.com/aaif-goose/goose/blob/249316032104/crates/goose/src/acp/server.rs#L755) (`data/tmp/goose/crates/goose/src/acp/server.rs`). [schemas.py](https://github.com/bytedance/deer-flow/blob/04a9833763f7/backend/packages/harness/deerflow/runtime/runs/schemas.py#L21).

## What `thread-stop` names

**Observed.** DeerFlow's cancel route is `POST /{thread_id}/runs/{run_id}/cancel`. The route loads that run id. Outcomes `cancelled`, `requested`, and `taken_over` are success. `requested` durably notifies the live owner on another worker and returns 202, or 204 when `wait=true` and the bridge can wait for completion. `taken_over` terminalizes the run after the owner's lease has expired. `wait=false` returns 202 on those success outcomes. `wait=true` can return 204 after a local task finishes. `lease_valid_elsewhere`, `not_cancellable`, `not_active_locally`, and `unknown` raise 409. A conflict is one outcome, not the rule for every run that is not local. Hermes's kanban retry returns false when `current_run_id` is missing or no longer matches the pinned run id. The pid comparison beside that check is conditional, as described under Run id.

**Inference.** Both checks refuse to act on a different run id from the one named. That supports an explicit expected-run form, and it supports not signalling some other run. The [thread-control plan](../../../plans/2026/11/11-thread-control-before-agent-plan.md) already proposes that form (`thread-stop e:$entry run:$run_id` signals only if the file's `run_id` is still that id) and a second form (`thread-stop e:$entry`) that means stop whichever run is current when stop resolves, after the identity is read under the record mutex and checked again before the signal. The clone evidence does not rule out the current-run form. Naming only an entry is unsafe when the operator meant a run they saw earlier. It is a different operation when the contract says "current at resolve time" and the identity is captured under the mutex. DeerFlow's `requested` path is also a reminder that "not on this worker" can mean "forward to the owner," which ASC's single-host stop does not have to copy.

**Still open.** Whether ASC ships both forms, only the expected-run form, or only the current-run form. The plan proposes both. This note does not withdraw the current-run form.

**Sources.** [thread_runs.py](https://github.com/bytedance/deer-flow/blob/04a9833763f7/backend/app/gateway/routers/thread_runs.py#L1365). [kanban_turn_recovery.py](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/agent/kanban_turn_recovery.py#L263). Plan, "Two stop forms".

## Hold scope, and who is told

**Observed.** DeerFlow's `ThreadOperationKind` is one exclusive admission per thread: a run, a checkpoint write, an artifact write, and so on (`schemas.py`). `waiting_for_input` is a run status. Pending interrupts are returned on the thread to the client that is reading it (`routers/threads.py` describes thread status `idle`, `busy`, `interrupted`, `error`). Hermes's durable queue, below, is per session.

**Inference.** Their admission grain is the conversation, not the host. A project-wide hold and a per-entry hold are both outside that grain. Recording "needs a person" as a status is present. A separate notifier is not in the run manager that was read.

**Still open.** Hold file per project, per host, or both. Who is told when `needs_interactive` is set.

**Sources.** [schemas.py](https://github.com/bytedance/deer-flow/blob/04a9833763f7/backend/packages/harness/deerflow/runtime/runs/schemas.py#L10).

## Queue and priority

**Observed.** Hermes's CLI `/queue` submits a prompt onto the gateway's durable FIFO while a turn is running (`hermes_cli/gateway_queue.py`, `submit_queued`). The module docstring says an earlier in-memory pending list was lost on owner restart, and that the owner now commits the prompt and runs it once, in order. `submit_queued` mints one `submission_id`. If the submit was never sent, it raises immediately. If the answer is lost, it asks once more with that same id. The docstring says the owner keys the admission by principal, session, and request id, and answers the retry with the admission it already holds, so the prompt is queued once. If the second answer is also lost, it raises `QueueOutcomeUnknown`. That class's docstring tells the user to check `/queue list` instead of sending the prompt again. The CLI does not keep a second copy of the text to submit as a new request. No CPU weight or slice appears in that file.

**Inference.** This is a queue of conversation inputs for one session, built after an in-memory list was dropped. The useful mechanism is one idempotent retry under a stable submission id, then a stop: unknown means look at the queue, not send a new prompt. It does not show that ASC needs a queue of OS processes. That depends on a different workload: more than one unattended entry waiting for a slot.

**Still open.** Whether ASC has that process waiting list. Priority as `nice` or slices is not addressed by this queue.

**Sources.** [gateway_queue.py](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/hermes_cli/gateway_queue.py#L38) (`submit_queued`; the unknown-outcome class is above it at line 28). `data/tmp/hermes-agent/hermes_cli/gateway_queue.py`.

## Host index

**Observed.** Goose puts `sessions.db` under the data directory and logs under the state directory. If the platform has no state directory, state falls back to data (`paths.rs`). A 2025 blog post in the Goose tree still shows a JSONL path under `~/.local/share/goose/sessions/`. This clone's `session_manager.rs` opens SQLite, and `session/legacy.rs` can load an older file. The blog and the code at this HEAD disagree; the code is the store that was read.

ASC's host index is read by `f_thread_monitor_default` in `asc/thread/monitor.hook.sh`. After refreshing from `data/threads/*.yml`, it parses each index file for the current docroot, deletes the index file when the local YAML is gone, and republishes when a `running` index pid is dead. The mother's crontab extension calls that hook for `thread-monitor` (`asc/extensions/crontab/cron/run.hook.sh`, `asc/extensions/crontab/thread/monitor.every-1m.crontab.yml`). `.asc_extensions_ignore` lists `crontab`, so that caller is not on the mother's default path. Other callers, including ones that exist only in an instance, were not surveyed.

**Inference.** Goose's data-versus-state split is a real layout, not a reason to move ASC's index by itself. The index is not a file nothing reads. Deleting it, or stopping the publish, requires replacing or removing this consumer, and checking consumers this pass did not survey. Keeping it requires a reason beyond "the monitor already heals it": the monitor's job is to make the index match the YAML, which a reader of the YAML alone would not need.

**Still open.** Heal the index, delete it, or move it. One XDG tree or three. Whether the monitor stays the consumer.

**Sources.** [paths.rs](https://github.com/aaif-goose/goose/blob/249316032104/crates/goose/src/config/paths.rs#L48). [session_manager.rs](https://github.com/aaif-goose/goose/blob/249316032104/crates/goose/src/session/session_manager.rs#L33). `asc/thread/monitor.hook.sh` from the host-index loop. `asc/extensions/crontab/cron/run.hook.sh`. `.asc_extensions_ignore`.

## Trace store and schema version

**Observed.** At this HEAD, Goose's durable session store is SQLite with `CURRENT_SCHEMA_VERSION` 18. JSONL remains the shape of foreign transcripts it imports (Codex rollouts, Pi sessions) and of the legacy loader. Hermes's session store read in the sessions doc is SQLite. DeepSeek's workflow result is an in-memory value with a `stopReason`, not a log file.

**Inference.** SQLite shows up where the same process resumes and searches. JSONL shows up as an import and legacy format. Goose's version constant exists because that SQLite schema has changed many times. A version on the first JSONL record can make a later mixed-format reader simpler. Omitting it until a second shape exists can also be reasonable. The examples do not decide that. Choosing SQLite for an ASC run log would meet a version field immediately, because that is how Goose's store is written. That is a cost of the store, not a proof that JSONL must be versioned from line one.

**Still open.** Short JSONL, a longer envelope, or a database. Whether the first JSONL line carries a version. When a columnar reader would be worth it: DuckDB was not a session store in these trees.

**Sources.** [session_manager.rs](https://github.com/aaif-goose/goose/blob/249316032104/crates/goose/src/session/session_manager.rs#L33). [legacy.rs](https://github.com/aaif-goose/goose/blob/249316032104/crates/goose/src/session/legacy.rs) (`data/tmp/goose/crates/goose/src/session/legacy.rs`).

## Skills

### Ownership record

**Observed.** Hub install records a content hash of the installed directory in the lock file (`tools/skills_hub_install.py`, `content_hash` then `HubLockFile().record_install`). Update compares that hash to the directory and skips the skill when they differ, unless `force` is set (`hermes_cli/skills_hub.py`, `_has_local_edits`, `do_update`). The docstring says an update would otherwise `rmtree` the directory and replace the user's edits. Bundled-skill sync stores an origin hash per skill in `.bundled_manifest` and updates an existing copy only when the bundled bytes changed and the user copy still matches that hash (`tools/skills_sync.py`, module docstring and `_matches_origin_hash`). Hub uninstall removes a skill that the lock lists as hub-installed. The `uninstall_skill` function that was read checks the lock and the path boundary. It does not compare the content hash before `rmtree`.

**Inference.** A hash recorded at install, and checked before a replacement, is a working safeguard for local edits. That supports ASC's proposed ownership record and update rule. It does not establish that Hermes's uninstall matches the proposal to refuse removal of a modified copy. Hermes uninstalls a hub skill because the lock says it is one.

**Still open.** Where the ASC ownership record lives, and whether uninstall refuses a modified tree or only update does.

**Sources.** [skills_hub_install.py](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/tools/skills_hub_install.py#L187) and [uninstall](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/tools/skills_hub_install.py#L205) (`data/tmp/hermes-agent/tools/skills_hub_install.py`). [skills_hub.py](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/hermes_cli/skills_hub.py#L1029) (`data/tmp/hermes-agent/hermes_cli/skills_hub.py`). [skills_sync.py](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/tools/skills_sync.py#L1) and [`_matches_origin_hash`](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/tools/skills_sync.py#L202) (`data/tmp/hermes-agent/tools/skills_sync.py`).

### User-wide directory

**Observed.** The skills doc in this clone says a shared `~/.agents/skills/` directory is an example of a path you add under `skills.external_dirs` (`website/docs/user-guide/features/skills.md`, "External Skill Directories"). It is not described there as a directory scanned by default. The same doc's project-local section is separate: inside a git checkout Hermes looks at `<repo>/.hermes/skills/` and `<repo>/.agents/skills/`, and loads them only after `hermes skills trust`. Precedence, once those tiers exist, is project, then `~/.hermes/skills/`, then `skills.create_dir`, then `external_dirs`.

**Inference.** Supported-when-configured is different from default discovery. Pointing ASC's user-wide scope at `~/.agents/skills` because Hermes "already scans it" was wrong. Project-local `.agents/skills/` is a third mechanism, trust-gated, and is the one that matches a repository checkout.

**Still open.** Whether the home instance's `.agents/skills` is the user-wide location, or whether ASC also tells other tools to add that path. Hermes's external-dir example shows the configuration step, not a default.

**Sources.** [skills.md external dirs](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/website/docs/user-guide/features/skills.md#L406) (`data/tmp/hermes-agent/website/docs/user-guide/features/skills.md`). Project-local section in the same file.

### Who may edit, description, front matter, Claude path, install

**Observed.** Hermes front matter in that doc is `name` and `description`, plus optional `version`, `platforms`, and nested `metadata.hermes`. The sample body has When to Use, Procedure, Pitfalls, and Verification. `skills.write_approval` defaults to false (the agent writes). When true, writes are staged under `~/.hermes/pending/skills/` until approved. The doc says the curator does not modify project skills, and that new agent-created skills go to `~/.hermes/skills/` or `skills.create_dir`. The same external-dir section says an existing skill is patched where it was found, including under `external_dirs`, if that directory is writable. The coaching repo's `skills/README.md` uses `name`, `description`, and `when_to_use`, and discovers other products by a per-file symlink into `.claude/skills/` and `.github/instructions/`.

**Inference.** "The agent does not write repo skills" is too broad for this revision. Project skills are excluded from the curator, and new skills are created in the Hermes home, but a writable external directory can still be patched in place. The four upgrade-managed ASC skills are closer to the project tier than to `~/.hermes/skills/`. Description-plus-When-to-Use is the Hermes body. Pitfalls is a section, not a required third front-matter field. `when_to_use` as a top-level key is the coaching repo's choice; the published Agent Skills validator's rejection of unknown top-level fields was checked earlier against the specification, not against this clone. A symlink is how the coaching repo exposes one file to Claude Code. That resembles the commented directory link in `asc/core/upgrade.sh` only in being a link rather than a copy.

**Still open.** Who may edit an ASC skill. Description shape. Extra front matter. Claude Code discovery. Whether `skill-install` has a customer beyond the upgrade swap of the four shared directories.

**Sources.** [skills.md format and write approval](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/website/docs/user-guide/features/skills.md#L194) (`data/tmp/hermes-agent/website/docs/user-guide/features/skills.md`). [ai-engineering-coach skills/README.md](https://github.com/microsoft/ai-engineering-coach/blob/c5cfba17e732/skills/README.md) (`data/tmp/ai-engineering-coach/skills/README.md`). `asc/core/upgrade.sh` for the commented `.claude/skills` link.

## Supervisor, lingering, journal

**Observed.** The loops read here stay up as a resident process and store state in a database (Hermes gateway, DeerFlow run manager, Goose session database). User systemd units, lingering, and journal caps were not found in those paths.

**Inference.** Their durability is the shape the specs already refuse: something that listens, plus a database. Absence of systemd in these trees does not answer whether a transient user unit is a good ASC supervisor. It also does not answer whether the journal cap is acceptable history.

**Still open.** Wrapper only, wrapper plus units for long entries, or units as the default on systemd. Lingering. Journal cap.

## Plans, routing, and rows with no clone evidence

**Observed.** DeerFlow's cancel route requires a cancel permission distinct from read (`thread_runs.py`, `require_permission("runs", "cancel", ...)`).

**Inference.** That is an action gate. It does not choose among the gates file, a plan status, a checklist, and a direct instruction.

**Still open**, with no relevant code in this set: backlog `order:` as dependency or priority, the next-steps generator, gates storage, the plan header, checkbox marks, where `agent-plan` evidence is kept, a decision-model hook, a plan budget, OSC 7501 (searched; hits were unrelated bytes), Ollaya, a default model hop, redaction rules, embeddings, a gap graph, `publish`, Kiwix, when a KnowledgeGap opens a trail, and Requirement versus Condition.

Goose's importer for Pi session JSONL (`crates/goose/src/session/import_formats/`) treats those files as a foreign transcript, in the same list as Codex rollouts. That does not say whether a small machine should run stage-1 work.

MCP appears as optional tool transport in Hermes skill docs, DeerFlow's task runtime, and OpenHands cleanup code. It is not the cancel or session supervisor in the files read here. That leaves an adapter as a later addition. It does not pick "after two foreign tools" as the count.

## Limits

Docs inside a clone can lag the code. The Goose blog path and `session_manager.rs` are the example above. Where they differ, the code was treated as the observation.

Instance-specific readers of the host index were not surveyed. OpenHands pause behavior was not re-checked at `754abee4f086` or SDK `10be259c4fc8`.
