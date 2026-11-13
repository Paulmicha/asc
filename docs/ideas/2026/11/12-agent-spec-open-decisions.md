# Open decisions in the agent specs

Status: open idea
Created: 2026-11-12
Sources, all `status: draft`: [agent threads](../../../specs/asc/agent-threads.md), [agent chats](../../../specs/asc/agent-chats.md), [agent plans](../../../specs/asc/agent-plans.md), [agent skills](../../../specs/asc/agent-skills.md). The later sections are the open choices in Projet Complexe 2026 Revival (v6), §19, read on 2026-11-12. That note lives in the Projet Complexe repository, not in this one.

This is the list of choices those texts leave open. A lean is a preference written in the source. It is not a decision, and this note does not approve one. Nothing here is an implementation go-ahead.

The earlier [thread-control plan](../../../plans/2026/11/11-thread-control-before-agent-plan.md) needs revision for the newer [active-claim direction](13-local-action-records.md). Its run identity, stop and recovery details remain to be reconciled; its existing contract is not ready to implement.

## Threads

| Decision | Candidates | Lean in the spec |
|---|---|---|
| Unit of record | one file per entry, as today, or one record per run | run |
| Run id | `$started_compact-$pid`, systemd invocation id, or ULID/UUIDv7 | the first |
| Host field | short hostname, or a name from the host registry | undecided; never in a tracked file |
| Timestamps | add a numeric UTC offset | yes |
| Thread file lifetime | active claim removed after confirmed completion; uncertain or unusually old claim investigated | current direction; separate wrapper logs may remain; cleanup and recovery details are open |
| Supervisor | today's background subshell, a `systemd-run --user` unit, a queue daemon, or a terminal runtime | try one transient unit on one long entry |
| Host index location | `$HOME/.local/share` (today) or `$HOME/.local/state` beside the registry | undecided |
| Stop | process-group signal, or stop the unit | needed; a cgroup is the reliable form |
| Stop all | a unit glob, or a hold file the wrapper refuses to start under | undecided |
| Queue | `flock` wait, a queue tool, or a spool directory plus a timer | none until a waiting list exists |
| Priority | CPU/IO weight, or `order` in the backlog | weight first |
| Other hosts | pull over SSH, with per-host files merged by the reader | pull; no listener |
| LAN inference endpoint | hook variant or instance configuration; a status probe only | not a tracked host |
| Status signal | OSC 7501 from the wrapper | only when something on the host reads it |
| Provider pivot names | keep `agent-*`, or move model-server lifecycle to `llm-*` | move |

## Chats

| Decision | Candidates |
|---|---|
| `chat_id` versus `provider_session_id` | one string, or an ASC name mapped to a provider id |
| Where a turn result is kept | stdout only, a field on the thread record, a pointer file per chat, or a ledger line |
| Pointer file, if any | `data/chats/$chat_id.yml` with provider, role, session id, created time, last status |
| `chat-read` and `chat-archive` | print the product's transcript path, drop the pointer, or remove both actions |
| Which endpoint serves the model | a hook variant, or instance configuration |
| Export field names | OpenTelemetry GenAI names as a mapping only |
| Claude Code | deferred |

## Plans

Gates and next-steps are marked under review in the plans spec as well as here.

| Decision | Candidates |
|---|---|
| What authorizes a step to start | the gates file, a status in the plan, a checklist in the plan, or a direct human instruction only |
| Backlog order | `order` in gates, line order in a next-steps file, or a `workflow-next` action that prints runnable rows |
| Next-steps generator | point it at `docs/plans/`, or retire it |
| Gates storage | the docroot file, as today, or registry keys |
| Plan header | one shape for status, date, and scope |
| Step progress inside a plan | none, or checkboxes `[ ]` `[~]` `[x]` `[!]` |
| Where loop evidence is kept | staging only, or a dated directory under `data/` |
| Decision-model readiness hook | deferred; the deterministic merge stays the default |
| Plan budget | a declared count of new files, globals, and entry points |

## Skills

`skill-install` / `skill-uninstall` is a proposal in the skills spec. Adopting it is open, and it depends on the ownership-record row.

| Decision | Candidates |
|---|---|
| Structured skill source | none, as today, or a `skill` entity rendered to product paths |
| Ownership record for an installed skill | a committed project file, or host state |
| Extra front matter | none, or `metadata` keys for provenance and last review |
| Description shape | free text, or three parts: what, use when, not for |
| Claude Code discovery | the commented `.claude/skills` link, a copy, or nothing until Claude Code is in use |
| Who may edit a skill | a human only, with agents proposing changes in their report, or agents editing under review |
| A skill for agent tracking | none until the actions are settled |
| User-wide skills | the home instance's `.agents/skills`, or a separate user directory |

## Revival note, not already in the tables above

Same choices, not repeated: unit of record, run id, host string, offset, history, supervisor, stop mechanism, queue, priority, other hosts, LAN endpoint, one chat id or two, where a turn result is kept, whether `read` and `archive` stay, endpoint as a hook variant or as configuration, Claude Code deferred, authorisation surface, next-steps generator, skill ownership record, extra front matter, Claude Code discovery path.

v6 sharpens a few of those without closing them:

| Decision | Candidates | Where it sits above |
|---|---|---|
| Supervisor, once systemd is available | wrapper only; wrapper plus units for long entries; units as the default on systemd | Supervisor |
| Lingering | off until a named job needs logout survival | Supervisor |
| Journal cap | acceptable as the only history, or not | History |
| What `thread-stop` names | the entry, or a run id | Stop |
| Hold file scope | per project, per host, or both | Stop all |
| What `order:` means | a dependency, or a priority | Backlog order |
| Model-server pivot | `llm-*`, or the call folded inside `run-agent` | Provider pivot names |
| First skill that would justify `skill-install` | none yet; whichever concrete skill needs an install action | A skill for agent tracking |

Open in v6 and absent from the four specs:

| Decision | Candidates |
|---|---|
| September host index | heal it, or delete it |
| Host-level directories | one XDG tree, or three (`registry`, threads, needs) |
| Stop status word | `exited` with code 143, or a fourth word `stopped` |
| Who is told when `needs_interactive` is set | undecided; no mechanism named |
| Trace store | a short JSONL line, the ten-field envelope, or Postgres |
| When a columnar reader is worth it | DuckDB over the JSONL files, later; the note does not ask whether, only when |
| Schema version field | not before a record has a second version |
| Default hop once a LAN box exists | small local, then the box, then a metered CLI or API |
| Redaction on a cloud hop | rules not chosen |
| Embedding strategy | by evaluation on the corpus, for the locales that project already treats as requirements |
| Ollaya | a real `plan-is` hook, or a name kept reserved |
| Pi as a stage-1 worker | yes or no; v5 left it, v6 did not reopen the evidence |
| MCP adapter | after two foreign tools, or not yet |
| Constrained DSL | for tiny models that cannot call tools; shape not chosen |
| Gap graph | how far it grows before Postgres |
| `publish` | in the v1 catalog, or not |
| Offline lookup | Kiwix, or dumps |
| When a KnowledgeGap opens a new trail | not chosen |
| Requirement versus Condition | one entity type, or two |

## Treated as constraints, not open choices

The specs carry these as constraints:

- The control host owns state.
- Nothing listens for work.
- A model never writes a record.
- Unattended agent runs are not yet allowed.

The revival note also refuses, and does not put back into the open list: a broker or a collector, Kafka, Redis as memory, a second `stop-agent` pivot beside `thread-stop`, and a schema version field before a second version of a record exists.

