# Record conventions: ids, time, hosts, paths, status words

> **2026-11-13 update:** The [active-claim direction](13-local-action-records.md) removes thread files after confirmed completion. Older proposals below about retained thread records are historical; identity, timestamps, investigation and recovery still need a concrete contract.

- **Date:** 2026-11-11
- **Status:** open idea / reconciliation list. Nothing here is decided.
- **Scope:** the small conventions every agent-related record shares, and where the current docs and code disagree.
- **Method:** mother code and plans read on 2026-11-11; earlier review notes kept outside this repository.
- **Specs this feeds:** all four `agent-*` specs.
- **Related:** [simplify disk entities](../../../plans/2026/11/06-simplify-disk-entities-contracts.md), which inventories what ASC writes and already lists the datestamp spellings.

## Why one page

Threads, chats, plans, needs and gates were each designed alone. Each picked its own id, time format and status words. A cross-host or cross-record view needs them to agree on four things. Agreeing on more than four is over-design.

## 1. Time

| Where | Format | Offset |
|---|---|---|
| Thread record, host index, log sidecar | `%Y-%m-%dT%H:%M:%S.%3N` | none (local) |
| Needs inbox (proposed) | ISO 8601 inside the record | yes |
| Database dumps | `%Y-%m-%d.%H-%M-%S` | none |
| File names | `DD-$name.md`; `HHhMM-$slug-need.md`; `HH.MM.SS.MS.$name.md` (README); `HH-II-SS-$name.txt` (concert-order plan) | — |

Proposal to compare: inside records, RFC 3339 with offset (`date +%Y-%m-%dT%H:%M:%S.%3N%:z`). One character class changes; local time stays readable. In file names, keep one spelling per precision: day (`DD-$slug`), minute (`HHhMM-$slug`). The second-and-millisecond file names have no writer today.

Never use file mtime as a record's time. Sync and copy rewrite it.

## 2. Identity

| Record | Id today | Problem |
|---|---|---|
| Thread | the entry name | one per entry; runs indistinguishable |
| Host index | first 16 hex of sha256 of `docroot::entry` | opaque; same limit |
| Chat | `chat_id`, `provider_session_id` | relation undefined |
| Plan, idea | path | fine; renames break links |
| Need (proposed) | path relative to the inbox root | fine |
| Gates row | plan path + `order` | fine |

Candidates for a run id, cheapest first:

- `$started_compact-$pid`, for example `20261111T141502-48213`. Sortable, readable, no tool. Unique per host.
- The systemd invocation id, if runs become units. Free, 128-bit, not sortable.
- A ULID or UUIDv7. Sortable and global. Needs a generator; bash has none built in (`uuidgen` gives v4, and v7 only in recent util-linux).

The reviews disagree with themselves here (ULIDs in one place, `(ts, kind, task, call)` tuples in another, ad-hoc `t-YYYY-MM-DD-NNNN` in a third). Lean: the first form, qualified by host when merged.

"Path is not the id" is a sound rule for records that move. Plans and ideas do not move; their path is fine.

## 3. Host

No record carries one. Candidates: `hostname -s`, the `HOST_TYPE`-style globals, or a name chosen per machine in the host registry.

- A hostname in a record is private information as soon as the record leaves the machine. Thread records are git-ignored; keep it that way.
- For provider endpoints, name the role (`lan-box`), not the brand or the address. The address belongs in instance configuration.
- The reviews use three tokens for the same slot in a file name: `<host>`, `<instance>`, `<writer>`. One is enough: the machine that wrote the file.

## 4. Where host-level files go

| Path | Holds | Status |
|---|---|---|
| `$HOME/.local/state/asc/registry/host/` | host registry keys | accepted |
| `$HOME/.local/share/asc/threads/` | host thread index | implemented |
| `$HOME/.local/state/asc/needs/` | needs inbox | proposed |

The XDG base directory specification describes the state directory as data that should persist between restarts but is not important or portable enough for the data directory; logs and history are its examples. A thread index is state by that definition. The simplify plan accepts "three directories with three jobs". The alternative is one tree, `$XDG_STATE_HOME/asc/{registry,threads,needs}`, and one sentence to explain it. Moving the index is a small change with one reader.

Neither tree should be synced between machines or committed.

## 5. Status words

| Record | Words |
|---|---|
| Thread | `running`, `exited`, `stale` |
| Chat turn | `completed`, `failed`, `empty_reply` |
| Desktop reply | `accepted`, `not sent`, `delivery unknown` |
| Plan document | `draft`, `ready`, `in-progress`, `completed`, `abandoned`, `superseded` |
| Plan review verdict | `blocking`, `ready_for_named_step`, `needs_human_or_evidence` |
| `plan-is` answer | `yes`, `no`, `unknown` |
| Evidence check | `pass`, `fail`, `missing` |
| Need (proposed) | `new`, `reviewed`, `planned`, `addressed`, `deferred`, `duplicate` |
| Gates row | `approved` yes/no, `go` yes/no, `lane` |
| Spec | `draft`, `current`, `superseded`, `retired` |
| OSC 7501 (external) | `idle`, `working`, `done`, `blocked`, `error` |

These should stay different. They describe different things, and a shared vocabulary would need a mapping layer nobody asked for. Two rules are worth sharing instead:

- **Unknown is a value.** `unknown`, `missing`, `delivery unknown`, `stale` all refuse to guess. Never coerce them to success.
- **Say how you know.** The reviews' basis labels (`reported`, `observed`, `inferred`, `unknown`) fit any status a tool writes on a model's behalf. A thread `exited 0` is observed; a harness saying "done" is reported.

## 6. Exit codes

Used today: `thread-status` 0 / 2 / 1; desktop reply 0 / 2 / 3; wrappers treat 75, 126, 130 as "needs a human", 130 and 143 as "do not retry". A review proposes a wider table (2 usage, 3 policy refusal, 4 budget, 5 no result, 64 catalogue violation) and hook codes (0 pass, 2 refuse with the reason on stderr).

These collide on 2 and 3. No table should be adopted until two entry points need to agree. Until then each entry point documents its own, as today.

## 7. Formats

The rule the storage reviews converge on, and that the tree already mostly follows:

- prose a human writes: Markdown, optional front matter;
- structure a human edits: YAML the shell can read (`f_yaml_parse` limits apply);
- lines a machine appends: JSON lines, never rewritten, a trailing partial line ignored;
- one object passed between processes: JSON on stdout, built with a real encoder (`jq -n --arg`).

A YAML schema the shell cannot read is on the reviews' refuse list.

## Open questions

- Is the offset change worth touching every thread record reader?
- Which host name, and may it appear in anything tracked?
- One host tree or three?
- Does any record need a schema version field before it has a second version?
