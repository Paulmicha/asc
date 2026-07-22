# ASC core concept : Wrappers

Table of contents :

1. batch (synonym : parallel)
1. chain (synonym : sequence)
1. cronjob (TODO or just use "raw" thread wrapper instead ?)
1. loop (TODO synonyms : deamon ? background task ? background job ? always-on ?)
1. nested
1. pipe
1. remote
1. rule (conditional and/or nested combinations)
1. sequence
1. stream ?
1. thread
1. tunnel

Wrappers are how ASC launches and supervises work: one job, many jobs, ordered steps, pipes, long runners, and nested contexts. Most day-to-day use goes through **logged** shortcuts that stack `log.wrap.sh` outside a more specific wrap (thread, loop, batch, sequence, pipe).

```text
make lt e:<entry>   → log.wrap → thread.wrap          → make <entry>
make ll e:<entry>   → log.wrap → loop.wrap (systemd)  → make <entry>
make lc e:1:… e:2:… → log.wrap → instance/chain → thread/sequence
make ls e:1:… e:2:… → log.wrap → thread/sequence
make lb e:… e:…     → log.wrap → thread/batch
make lp …           → log.wrap → thread/pipe
```

Plain `make chain`, `make parallel` / `thread-batch`, and `make pipe` / `thread-pipe` skip the log wrap. After changing `ASC_SYNONYMS` / make shortening maps: `make reinit`.

Wrap scripts live as `*.wrap.sh` (`log.wrap.sh`, `thread.wrap.sh`, `loop.wrap.sh`, …). Callers and tests must use those names.

---

## batch (synonym : parallel)

Concurrent fan-out of entry points, then join.

| Surface | Path | Make |
|---------|------|------|
| Thread batch | `asc/thread/batch.sh` | used by logged + parallel |
| Parallel (no log wrap) | `asc/instance/parallel.sh` | `make parallel` / `thread-batch` |
| Logged batch | `asc/instance/logged_batch.sh` | `make lb` / `logged-batch` |

- Shell model: background jobs (`&`) plus wait.
- Same-entry pile-up uses flock on `data/threads/<entry>.lock`; cross-entry parallelism stays free.
- Wrap emitter label: `parallel` (even when the make alias is `lb`).
- Optional batch knob: `workers:N` (batch family only).

Chooser: several independent jobs → `make lb e:a e:b`.

---

## chain (synonym : sequence)

Ordered multi-step runs. **Sequence** is both a synonym and a distinct make surface (`lc` vs `ls`).

| Surface | Path | Make |
|---------|------|------|
| Instance chain | `asc/instance/chain.sh` | `make chain` |
| Logged chain | `asc/instance/logged_chain.sh` | `make lc e:1:… e:2:…` |
| Logged sequence | `asc/instance/logged_sequence.sh` | `make ls e:1:… e:2:…` |
| Thread sequence | `asc/thread/sequence.sh` | (internal) |

- There is **no** `asc/chain/` folder: `make chain` routes into `thread/sequence`.
- Default join is fail-fast (`&&`); continue-on-error uses `;` (`join:&&` / `join:;`).
- Multi-step syntax: `make lc e:1:step-a e:2:step-b`; per-step args via `a:<arg>`.
- Prefer **`lc` / `chain`** when you want the instance-chain hop; **`ls`** for direct log → sequence.

---

## cronjob (TODO or just use "raw" thread wrapper instead ?)

Calendar ticks are **not** a core `asc/cronjob/` subject today.

| Piece | Location |
|-------|----------|
| Extension | `asc/extensions/crontab/` (opt-in via ignore file) |
| Job YAML | `{action}.{preset}.crontab.yml` beside the action |
| Host run | `make cron-run e:<entry>` |
| CRUD | `cron-sync`, `cron-status`, `cron-stop`, `cron-start`, … |

Preset whitelist examples: `every-{N}m`, `at-{HH}h{MM}`, `{N}x-per-{unit}`. Shipped patterns include log rotate and thread monitor jobs.

**Working stance:** keep **crontab** as the calendar/codegen surface; use **thread** (`lt`) / **loop** (`ll`) as the process wrappers those ticks launch. Do not invent a third core wrapper named `cronjob` until entity / `*.able` work forces a rename.

**Planned:** durable outputs under `data/cronjobs/<item>.txt` (+ sidecar); retire the `data/asc/cron/` codegen forest.

---

## loop (TODO synonyms : deamon ? background task ? background job ? always-on ?)

Long-running / restartable runners (systemd user units on tip).

| Surface | Path | Make |
|---------|------|------|
| Loop wrap | `asc/loop/loop.wrap.sh` | inner wrap under `ll` |
| Logged loop | `asc/instance/logged_loop.sh` | `make ll e:…` |
| Status / CRUD | `asc/loop/status.sh`, … | `loop-status`, `loop-sync`, `loop-stop`, `loop-start`, … |

- Stack: `log.wrap` → `loop.wrap` → entry.
- Reboot survival needs linger (`loginctl enable-linger`); wrap warns if absent.
- Optional `{action}.loop.yml` beside the action.
- Distinct from crontab: process lifetime vs clock ticks.

Open naming: daemon / background task / always-on — not settled.

**Planned path layout:** prefer durable `data/loops/*.yml` over burying intent only in `data/asc/loop/` codegen.

---

## nested

Controlled recursion into other docroots / repos / extension trees — not unbounded make self-calls.

| Kind | Mechanism | Role |
|------|-----------|------|
| **nested-asc** | extension `nested_asc` | Child ASC instances; host-level concerns should climb up (crontabs, logs) |
| **nested-git** | extension `nested_git` | Child git clones / work trees |
| **nested-extension** | `.asc_subjects_ignore` | Nested subject folders under an extension point |
| **nested-blueprint?** | builder + sub-modules | Open — see [builder.md](builder.md) |

Further nested kinds from working notes (open — not separate extensions yet):

| Sketch | Intent |
|--------|--------|
| Nested Cursor / nested piloting | Agent or IDE session inside a child context |
| Nested sudo / nested VM | Elevated or VM-isolated child (e.g. tiny VM / SBC dedicated to agents) |
| Nested entity | Entity graph climb via `$nest.able` |
| Nested condition system | Rules that nest (and/or trees), not only flat variant hooks |

`.asc_subjects_ignore` is the **submodule list** for nested-extension (attention: most-specific weight must match the nearest non-nested extension point).

### nested-asc

```sh
make nested-asc-list
make nested-asc-exec <ref> e:reinit
make nested-asc-exec <ref> -- git status
```

- Virgin env (`env -i` allowlist); child bootstraps with its own globals/cache.
- `ref` = short folder id (qualify on collision); absolute paths work.
- Forms after `<ref>`: make entry / `e:<entry>`, path-like raw command, or `-- <cmd…>`.
- Emitter label in wraps: `nested-asc`.

Core-ignored by default; enable via override omit + `make reinit`.

---

## pipe

Stdout → stdin between stages (real `|`, `pipefail` on, ≥2 stages).

| Surface | Path | Make |
|---------|------|------|
| Thread pipe | `asc/thread/pipe.sh` | (internal) |
| Instance pipe | `asc/instance/pipe.sh` | `make pipe` |
| Logged pipe | `asc/instance/logged_pipe.sh` | `make lp` / `logged-pipe` |

Plain `pipe` / `thread-pipe` skip log wrap. Logged `lp` stacks `log.wrap` → pipe. Conceptually a **bridge** (I/O emitter → receiver); see [entities.md](entities.md) § relationships.

---

## remote

Remote connectivity is mostly **extensions**, not a core wrap peer of thread/loop.

| Extension | Role |
|-----------|------|
| `remote` | SSH sync utilities; `remote_instances.yml` → codegen under `data/asc/remote-instances/` |
| `remote_asc` | Remote ASC helpers |
| `remote_db` | DB dump sync via `db` + `remote` |
| `remote_traefik` | Traefik / TLS defaults |

Ideas for a dedicated remote wrap subject are still empty. Broader “connectivity” (ssh/curl/dns as first-class wrap) remains open. Agent designs (when revived) should fail closed on remote actuators unless explicitly allowed.

### Open: tailed remote sync

Working notes sketch a **tail** family that materializes remote flux locally (every flux must land on disk — no invisible streams):

```text
data/remote-<entity>/…          # e.g. remote-instance, remote-host, remote-s3
data/remote-instance/           # ≈ REMOTE_INSTANCE_DOCROOT mirror root
data/remote-instance/$subdir/*.tailsync.txt
```

| Sketch | Stack (debated) |
|--------|-----------------|
| `make tail` | loop wrap (follow) |
| `make logged-tail` | log wrap → loop wrap ? |
| `remote-tail` / `remote-logged-tail` | remote + tail |

Treat as design only until named make targets and paths exist. Related: [stream ?](#stream-), [loop](#loop-todo-synonyms--deamon--background-task--background-job--always-on-), local inbox materialization for agents (capture all messages to `data/…`, not only an ephemeral UI).

---

## rule (conditional and/or nested combinations)

Conditional gates for whether work runs.

| Piece | Status |
|-------|--------|
| Extension `rules` | Stub actions (`rule-*`), bodies `# TODO` |
| Extension `views` | Projection stubs; often paired with rules |

No core `asc/rule/` wrap exists. Until `rules` ships real bodies, treat this as an **extension-level contract** that should compose with [organization.md](organization.md) variants/hooks and nested wrappers — not a launch-stack peer of `lt`/`ll`.

Working model from notes:

- **Rules ≈ `$wrap.able` + `$nest.able`** — conditional execution that can nest (like hooks, but explicit).
- **Logged-wrapped + rules-wrapped** — same launch stack as `lt`/`lc`/…, with a condition gate before the entry runs.
- Emitter/receiver is a **differentiator** on wrap traces; rules use a **comparator** (include/exclude, and/or) — do not merge the two vocabularies.
- Pair with `break.able` / circuit breaker for emergency stop (see [entities.md](entities.md) § capabilities).

---

## sequence

Direct ordered multi-entry execution under `asc/thread/sequence.sh`.

- Logged: `make ls e:1:a e:2:b` → log wrap → sequence.
- Related: [chain](#chain-synonym--sequence) (`lc` / `make chain` go through `instance/chain` first).

Keep both make surfaces; document which path you mean when writing runbooks.

---

## stream ?

**No** first-class `asc/stream/` subject today. Closest live surfaces:

| Concept | Where |
|---------|-------|
| Flat stdout/stderr | `data/logs/<entry>.txt` |
| Launch audit / sidecar | `*.sidecar.txt` beside durable files (shared wrap still TODO) |
| Continuous loop output | [loop](#loop-todo-synonyms--deamon--background-task--background-job--always-on-) |
| Stage I/O | [pipe](#pipe) |

Open: is “stream” a synonym of pipe + loop, or a distinct chunked/evented contract? Remote **tail sync** (follow a remote file into `data/remote-*/…/*.tailsync.txt`) may be the missing stream-shaped wrap — see [remote](#remote).

---

## thread

Supervised single-job lifecycle.

| Surface | Path | Make / role |
|---------|------|-------------|
| Wrap | `asc/thread/thread.wrap.sh` | Inner wrap under `lt` |
| Helpers | `asc/thread/thread.inc.sh` | YAML read/write |
| List / status | `list.sh`, `status.sh` | `thread-list`, `thread-status` |
| Monitor | `monitor.hook.sh` | Host sibling awareness |

### Paths

| Path | Role |
|------|------|
| `data/threads/<entry>.yml` | pid, status, owner, attempts, … |
| `data/threads/<entry>.lock` | pile-up flock |
| `$HOME/.local/share/asc/threads/` | Host-wide index when monitoring allows |
| `data/logs/<entry>.txt` | Captured stdout/stderr (log wrap is sole writer) |

### Contracts

- Logged entry: `make lt e:<entry>`.
- Retry: `ASC_WRAP_RETRY_MAX` / `ASC_WRAP_RETRY_DELAY` (default off).
- Noninteractive children: stdin `/dev/null`, `ASC_WRAP_NONINTERACTIVE=1`; refuse `@requires interactive` / `@requires sudoing` without root.
- Wrappers never call `sudo` themselves; EUID is inherited. Thread YAML records owner (prefer human via `SUDO_USER` when elevated).

---

## tunnel

Placeholder in the TOC — **no core implementation or extract facts yet**.

Intended direction (open): a supervised channel between contexts (host ↔ remote, nested ↔ parent) distinct from [pipe](#pipe) (local stdin/stdout) and [remote](#remote) (SSH sync helpers). Do not add make targets named `tunnel` until the contract is specified under [entities.md](entities.md) / ideas.
