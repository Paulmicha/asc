# Cooperative review loop for the four 2026-09-19 lazy-include plans

| Field | Value |
|-------|--------|
| **Date** | 2026-09-20 |
| **Status** | loop **skipped** (2026-09-20). Apply hunts in this chat. Garage clause **landed** ([20-garage-lightweight-rule.md](./20-garage-lightweight-rule.md)). Mirror-path pick still open. No code. |
| **Scope** | Strengthen four existing *plans* (not the runtime) via a short cooperative feedback loop. The same loop is a **continual memory-upgrade process**: every durable ASC fact that Cursor would otherwise forget is proposed as the smallest patch to the mother always-applied rule and/or this repo’s changelog — never as a new loader. Lens: [asc-lightweight.mdc](../../../.cursor/rules/asc-lightweight.mdc). |
| **Does not change (this step)** | The four source plans (until the apply step). Code, loaders, `README.md`, git. `.cursor/rules/*.mdc` except the garage clause already applied. |
| **Parent** | [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md) (split 2026-09-19). Adjacent docs SoT, not in the review set: [19-eager-vs-lazy-include-cases.md](./19-eager-vs-lazy-include-cases.md). |
| **Orientation** | Donella Meadows: intervene in **goals, information flows, feedback, and delays** before adding parts. Highest leverage in this loop: the always-applied rule that governs future agents. Existing ASC names: *lazy only after a real caller*, *two loaders not three*, *explicit `.` from `asc/core/utils/`*, *core / ext / contrib / instance*, *project instance*, parent **dev stack**. Do not add a parallel Meadows vocabulary. |

`$` in this file is the ASC docs placeholder (`$subject` / `$object` / `$action` / `$extension`), not a shell variable.

---

## Context

Four 2026-09-19 sub-plans split the parent “lazy `*.opt-inc.sh` + entry-point extraction” work so it is not one PR:

| Order (parent) | File | Job in one sentence |
|----------------|------|---------------------|
| 1 | [19-fs-archive-lazy-include.md](./19-fs-archive-lazy-include.md) | Move archive helpers off kernel `fs.inc.sh`; callers must `.` `asc/core/utils/fs.opt-inc.sh`. |
| 2 | [19-db-thin-inc-and-opt-inc.md](./19-db-thin-inc-and-opt-inc.md) | Keep creds/flags eager; dump/exec/restore cluster → `db/db/db.opt-inc.sh`. |
| 3 | [19-mysql-pgsql-hook-opt-inc.md](./19-mysql-pgsql-hook-opt-inc.md) | Extract shared mysql/pgsql hook helpers **only if grep shows sharing**. |
| later | [19-lazy-opt-inc-remaining-core-waves.md](./19-lazy-opt-inc-remaining-core-waves.md) | Everything else in the parent waves, one small PR at a time. |
| out | [20-host-scan-project-instances.md](./20-host-scan-project-instances.md) | Catalog ASC `$PROJECT_DOCROOT` trees on this host. **Not this loop.** |

This file is a **meta-plan**. It does not implement those slices. It prepares a real-time loop so the human and later agents can strengthen the four plans (and only later their implementation) while feeding durable ASC knowledge back into the rule that will run the next session.

---

## Goal

Strengthen the four plans so later implementation stays the smallest thing that still works — and so Cursor’s **global memory of ASC** gets the smallest durable upgrade that still works (intensive sufficiency: maximize learning per token/file, minimize standing process).

Map every review finding to **leverage**, not to more files. High leverage here looks like:

- **Paradigm / goal** — “match an existing script; stop when the action runs.” A finding that says “add a loader so every case is covered” is the wrong direction. The always-applied rule is the paradigm that future agents inherit.
- **Information flow** — make eager vs lazy vs explicit `.` obvious at the call site (one example: `utils/` never auto-derives `fs.opt-inc.sh`). Same for **where memory lives**: mother rule/changelog vs a project instance’s specifics.
- **Feedback** — tests that fail *before* a test sources the opt-inc, and pass after; hooks that would seed the wrong directory. Memory check at every agent step (below) is the same kind of cheap feedback, not a second bureaucracy.
- **Delays / order** — fs before db if dump/exec must `.` `fs.opt-inc.sh`; remaining-core waits; mysql may skip entirely. Rule patches wait until this plan is approved.
- **Low leverage** — new `*.opt-inc.sh`, extra wrappers, README matrices, a third loader (`ASC_OPT_INC`), a new `.mdc` file, dumping Projet Complexe paths into the mother rule.

Success for *this* file: the human can approve or cut the agent set — and the later one-line rule evolution — without anyone having launched or edited `.mdc` files.

---

## Continual memory upgrade (mother vs project instance)

This is **the same loop**, not an extra phase. Intensive sufficiency: hunt the smallest durable memory upgrade that still works; refuse completeness-for-its-own-sake; prefer **one lighter rule line** over a new file.

### Names that already exist (reuse these)

| Existing term | Where | Meaning for this plan |
|---------------|--------|------------------------|
| **This repo** / ASC **core** | `/home/paul/Documents/asc` | The tree instances are born from (copy/`asc/` replace). **Mother.** Global Cursor memory of ASC lives here. |
| Parent **dev stack** repo | README § Placement | Usual place `asc/` sits: `$PROJECT_DOCROOT` for a stack that may nest app git repos. This mother repo is that shape of source. |
| **Project instance** | README: `$PROJECT_DOCROOT` | A client install that consumes/extends ASC. Not the place global ASC memory lives. |
| **Projet Complexe** | README § Example project | One client: [projet-complexe-asc](https://github.com/Paulmicha/projet-complexe-asc) is the *project-specific ASC (stack)* repo; [projet-complexe](https://github.com/Paulmicha/projet-complexe) is the UI. Instance-local notes only when the fact is Projet Complexe–specific. |
| core, ext, contrib, instance | [asc-lightweight.mdc](../../../.cursor/rules/asc-lightweight.mdc) | Any ASC tree. Contrib = `scripts/asc/contrib/…`. **Specifics** / project-specific = `scripts/asc/extend/` (README). |
| Two always-applied rules | `.cursor/rules/` | **`asc-lightweight.mdc`** (`alwaysApply: true`, no globs) — the rule to evolve. **`asc-dollar-prefix.mdc`** — `$` in prose only; do not hang self-improvement on it. |

Do **not** invent a parallel vocabulary (no second “CWT memory” layer; CWT appears only in old `data/ideas/` notes). Do **not** confuse this with `asc/extensions/memory` (runtime memory *hooks*). Do **not** add an `asc/extensions/agent` file as the Cursor-memory vehicle.

**Mother / client** in this file is only a short alias for: *this ASC core repo* vs *a project instance* (example: Projet Complexe). Prefer those README words in the later rule patch.

### Rule (garage clause applied 2026-09-20)

**File:** `/home/paul/Documents/asc/.cursor/rules/asc-lightweight.mdc` — see [20-garage-lightweight-rule.md](./20-garage-lightweight-rule.md).

It is no longer a frozen checklist: garage / wild-but-minimal / literal ASC tests / improve this rule every step. Instance-only facts still stay out of this mother rule. Opt-inc **mirror paths** are not in the rule yet (apply with the four plans).

### Per-step memory opportunity check

Every prepared agent (review, mistakes, improvements, optional synthesis) and the human coordinator, **at each step**, runs this cheap check — one breath, not a subagent:

1. Did this pass surface a durable fact about ASC (include policy, lazy vs eager, mother vs project instance, hooks, `*.opt-inc.sh`) that Cursor will otherwise forget?
2. If yes: propose the **smallest** reflection into **(a)** `asc-lightweight.mdc` and/or **(b)** this mother-repo changelog (this file or a later dated note). Never dump client-instance specifics into the mother rule.
3. A project instance (e.g. Projet Complexe / `projet-complexe-asc`) receives instance-local notes **only** when the fact is client-specific.
4. Do not open a new loader, hook, wrapper, or always-sourced file as the memory vehicle. The always-applied rule and existing changelog are the preferred sinks.
5. **Skip the write** when the knowledge is already in the rule or is one-off.

Output shape when something *is* worth remembering (example of one line, not a template to fill every time):

```text
Memory: skip | rule: <one clause> | changelog: <pointer>
```

Most steps should print `Memory: skip`. That is success.

---

## What this plan does NOT do

- Launch review / mistakes / improvements / synthesis agents (or Bugbot / security-review / other subagents).
- Edit the four source plans, the parent, or the eager/lazy case table.
- Change code, add includes, hooks, wrappers, or globals.
- Edit `README.md`.
- Edit `.cursor/rules/*.mdc` until the human approves this plan **and** the later rule-patch open task.
- Commit.
- Create the later review-output files listed below; those are proposed paths only.
- Write Projet Complexe (or other instance) notes into this mother repo unless a finding is actually about ASC core.
- Implement or review [20-host-scan-project-instances.md](./20-host-scan-project-instances.md). No extra review sibling for it.

---

## Lightweight conflicts already visible (hunt list)

Later agents should start from tensions **already on the page**, not from a completeness inventory. One example per idea; do not paste the four plans. Each item is also a candidate **memory** fact (usually: already implied by the lightweight rule — then `Memory: skip`).

1. **README table as a gate.** Parent split says do not start code sub-plans until the case table is agreed. Lightweight says agents do not fill README with exhaustive matrices. Hunt: are code plans waiting on a README row that should stay in changelog?

2. **A file so the table has a row.** Mysql/pgsql is partly “a real contrib example for the README table,” and already says **skip** if grep finds no sharing. Hunt: keep that skip; do not create empty `db.opt-inc.sh` next to `dump.mysql.hook.sh`.

3. **Move vs drop.** Fs moves `f_fs_watch_poll` (tests / comments only) into the new opt-inc. Hunt: dropping unused is higher leverage than relocating it.

4. **Thin wrappers left in place.** Db keeps `dump.sh` → `f_db_dump` because the functions call each other. Hunt: that pick is probably right (avoids a source web); do not “complete” by extracting every body into `*.sh`.

5. **Cross-plan delay.** Db wants `. asc/core/utils/fs.opt-inc.sh` at the top of the dump/exec opt-inc. Fs allows splitting format unification (`tar czf` named `.gz` vs gzip of SQL) to a follow-up. Hunt: order and “do both in one PR” vs two, not a new helper file. **Path rule:** opt-inc mirrors eager (see pre-launch review) — do not treat `$extension/$extension.opt-inc.sh` as a spelling mistake.

6. **Wave list as a matrix.** Remaining-core restates parent waves A–D plus “ext rest.” Hunt: first concrete leftover (yaml dual-source) is enough to start; do not grow a per-subject table in that plan.

Agents may add other hunts; they must not invent files that do not exist yet.

---

## Prepared agents — lifecycle only, not launched

**Trigger for every agent below:** the human names it (or says “launch the prepared set”) *after* approving this plan. Nothing auto-starts from writing or reading this file.

**Coordinator is not launched.** It is the human plus this chat.

No extra “memory agent.” The check is a line on every existing role.

### How many agents and why

| Role | Count | Why this number |
|------|-------|-----------------|
| Coordinator | 0 launched | Human holds the loop, including which memory proposals are worth a rule line. A “manager agent” would add delay and rewrite temptation. |
| Plan review | **4 siblings, one shared spec** | Independent coverage is the point. One sequential agent would contaminate later passes. Four *different* prompts would be extra machinery — same spec, four input files. |
| Cross-plan mistakes | 1 | Only this job needs all four plans at once (order, paths, hook vs opt-inc, eager vs lazy). |
| Lightweight / leverage improvements | 1 | Separate so “what’s wrong” does not default to “add a file.” Runs **in parallel with mistakes** after reviews land (two information channels, one delay). Natural owner of ranked *rule-line* proposals; still not a second memory bureaucracy. |
| Synthesis | **0 by default** | Human merging three kinds of short feedback is higher leverage than a seventh rewrite. Optional later if volume actually hurts. Same memory check if used. |

No other agents. Do not add a “README agent,” “test agent,” “implementation agent,” or “memory agent” in this loop.

### Shared constraints (every launched agent)

- **Read:** the assigned inputs. **Must not edit** any file, especially the four source plans, parent, case table, `README.md`, `.cursor/rules/*.mdc`, or this meta-plan.
- Lightweight: no new include / hook / wrapper / global without a **named existing caller**. Prefer fewer always-sourced lines. Changelog suggestions may be long; README and runtime paths may not.
- Run the **memory opportunity check** (above). Default `Memory: skip`. If proposing a rule line, it must be generic ASC (mother), not Projet Complexe specifics.
- One example per idea. No exhaustive loader tables. No hypothetical files.
- `$` only for ASC conceptual placeholders. Do not write `$index` / `$extract` / `$relate` and the like for ordinary names (write index, extract, relate).
- Stop when the output is a short findings list plus one memory line. Incomplete-and-honest beats inventing work.
- Do not launch further agents.

### Output (default: chat, not new files)

Default: each agent returns markdown in chat. The coordinator pastes a short digest into this file under **Findings (filled after launch)** *or* keeps the chat as the record. Memory proposals that survive human filter wait for the later `asc-lightweight.mdc` patch — they are not applied by the review agents.

Create a sibling file **only if the human asks to persist** a long review. Proposed names (do not create now):

| Agent | Proposed path if persisted |
|-------|----------------------------|
| Review-fs | `changelog/2026/09/20-review-fs-archive-lazy-include.md` |
| Review-db | `changelog/2026/09/20-review-db-thin-inc-and-opt-inc.md` |
| Review-mysql | `changelog/2026/09/20-review-mysql-pgsql-hook-opt-inc.md` |
| Review-remaining | `changelog/2026/09/20-review-lazy-opt-inc-remaining-core-waves.md` |
| Mistakes | `changelog/2026/09/20-review-cross-plan-mistakes.md` |
| Improvements | `changelog/2026/09/20-review-lightweight-improvements.md` |
| Synthesis (optional) | `changelog/2026/09/20-review-delta-list.md` |

---

### Coordinator (human + this chat)

| | |
|--|--|
| **Job** | Hold the loop. Approve launches. Collect three kinds of feedback **and** memory-opportunity lines. Apply (or reject) high-leverage edits to the four plans. After that (or instead, if a fact is already true and the plans need no wait): consider the smallest `asc-lightweight.mdc` clause. Refuse implementation until the plans are strengthened. Refuse dumping client specifics into the mother rule. |
| **Starts** | Already in this conversation. Does not rewrite the four plans or the rule until the human chooses those apply steps. |
| **Inputs** | This file; after launch, agent outputs. |
| **Must not** | Launch agents before approval; treat “prepared” as “running”; edit `.mdc` in the same breath as “the plan is still under review.” |
| **Success / stop** | This plan is reviewed. After later apply steps: four plans updated or explicitly left as-is; rule either patched one short section or explicitly skipped. Loop ends; no standing agent roster. Memory check does **not** keep the loop alive by itself. |
| **Feeds** | Human decision → optional launch → findings + memory lines → apply to plans and/or rule → optional second pass. |

---

### Plan review (four siblings, one spec)

**Name / job:** Review-fs, Review-db, Review-mysql, Review-remaining. Each is one instantiation of the spec below. Job: read **one** source plan as a reviewer would — clarity, missing callers, eager vs lazy picks, test claims, open tasks — without fixing the other three. End with the memory check.

**When it starts:** Human approval, then four parallel launches (or four sequential *independent* chats that must not see each other’s output). Never auto-start.

**Inputs (exactly one plan each):**

| Instantiation | Must read (primary) |
|---------------|---------------------|
| Review-fs | `/home/paul/Documents/asc/changelog/2026/09/19-fs-archive-lazy-include.md` |
| Review-db | `/home/paul/Documents/asc/changelog/2026/09/19-db-thin-inc-and-opt-inc.md` |
| Review-mysql | `/home/paul/Documents/asc/changelog/2026/09/19-mysql-pgsql-hook-opt-inc.md` |
| Review-remaining | `/home/paul/Documents/asc/changelog/2026/09/19-lazy-opt-inc-remaining-core-waves.md` |

May also read, if needed to check a claim: [asc-lightweight.mdc](../../../.cursor/rules/asc-lightweight.mdc), parent [11-lazy-opt-inc-and-entry-point-extraction.md](./11-lazy-opt-inc-and-entry-point-extraction.md), [19-eager-vs-lazy-include-cases.md](./19-eager-vs-lazy-include-cases.md). Do **not** require reading the other three source plans (independence). Point at code paths named in the plan; do not implement.

**Must not edit:** anything (including the rule).

**Output:** Short review: (1) what is already the right shape, (2) mistakes or gaps **inside this plan**, (3) lightweight risks (eager include, wrapper with no caller, table-for-completeness), (4) leverage of the plan’s own open tasks, (5) `Memory: skip | rule: … | changelog: …`. Cap: about one screen. No patch dump.

**Success / stop:** Findings returned for that one file. Stop even if grep was not run against the whole tree — say what was not verified.

**Feeds:** Coordinator collects four independent reviews (and their memory lines). Mistakes and improvements read them **after** this phase.

**Prompt-as-spec** (same text for all four; only the primary path changes):

```text
You are a plan reviewer for one ASC changelog plan. Do not edit files. Do not launch agents.
Lens: smallest thing that still works; no new include/hook/wrapper/global without a named existing caller.
This workspace is ASC core (mother / usual parent dev stack). Do not write Projet Complexe specifics into a mother-rule proposal.
Read the primary plan at: <PATH>
Optional: asc-lightweight.mdc; parent 11-lazy-opt-inc-and-entry-point-extraction.md; 19-eager-vs-lazy-include-cases.md.
Do not read the other three 2026-09-19 sibling sub-plans.
Return: keep / mistakes-or-gaps / lightweight risks / leverage of open tasks.
Then the memory check: durable ASC fact Cursor would forget? If no: Memory: skip. If yes: smallest rule line and/or changelog pointer — never a new file.
One example per idea. Stop.
```

---

### Cross-plan mistakes (one agent)

| | |
|--|--|
| **Name / job** | Mistakes. Find contradictions **across** the four plans: naming, include path (opt-inc must **mirror** eager: `$subject/$action.inc.sh` ↔ `$subject/$action.opt-inc.sh`, `$extension/$extension.inc.sh` ↔ `$extension/$extension.opt-inc.sh` — same path must work both ways; today’s caller opt-inc vs that rule is the hunt, not “pick one abbreviation”), hook seeding vs caller opt-inc, duplication, missing callers, eager vs lazy, wave order, README-as-gate. Memory check at the end: a cross-plan contradiction that is actually an ASC law (two loaders, mirror paths) may deserve a mother-rule line; a one-off ordering note does not. |
| **Starts** | After all four reviews have returned. Human trigger. Not parallel with reviews (needs their output). Parallel with improvements is intended. |
| **Inputs** | The four source plan paths above; the four review outputs; lightweight rule; parent split order if needed. |
| **Must not edit** | Anything. Must not “resolve” by proposing a new loader or a new `.mdc`. |
| **Output** | List of contradictions (or “none material”). Each item: where the two (or more) plans disagree, why it matters at runtime or as delay, suggested **information** fix (clarify order / caller / skip), not a new file. Plus one `Memory:` line. |
| **Success / stop** | Cross-plan list complete enough to apply or to skip. Do not then review each plan again. |
| **Feeds** | Coordinator (and optional synthesis). Improvements may read this but must not wait if the human launched both in parallel. |

**Prompt-as-spec:**

```text
You are the cross-plan mistakes agent. Do not edit files. Do not launch agents.
Read the four plans:
  changelog/2026/09/19-fs-archive-lazy-include.md
  changelog/2026/09/19-db-thin-inc-and-opt-inc.md
  changelog/2026/09/19-mysql-pgsql-hook-opt-inc.md
  changelog/2026/09/19-lazy-opt-inc-remaining-core-waves.md
and the four sibling review outputs from this loop.
Hunt naming, include order, hook vs opt-inc, duplication, missing callers, eager vs lazy, wave ordering, README-as-gate.
Map each contradiction to leverage (order, skip, clarify caller) not to more files.
Memory check: only propose a mother-rule line if the contradiction is a durable ASC law (e.g. two loaders, utils/ never auto-derives). Else Memory: skip.
One example per idea. Stop.
```

---

### Lightweight / leverage improvements (one agent)

| | |
|--|--|
| **Name / job** | Improvements. Fewer files, fewer always-sourced lines, better information and delays. **Refuse completeness-for-its-own-sake.** Meadows via ASC wording only. Rank memory proposals here if several reviews suggested rule lines — still `skip` unless a line is missing from `asc-lightweight.mdc`. |
| **Starts** | After reviews. Human trigger. Prefer **parallel with mistakes** so this channel is not a rewrite of the mistakes list. |
| **Inputs** | The four source plans; four reviews; lightweight rule. Mistakes output optional (do not block on it). |
| **Must not edit** | Anything. Must not recommend `ASC_OPT_INC`, ArcadeDB opt-incs, per-action `dump.opt-inc.sh` without a dump-only helper, README matrices, or a new always-applied rule file. |
| **Output** | Ranked suggestions (keep / shrink / skip / delay). Example of high leverage: mysql plan’s “skip if no sharing.” Example of low leverage: a wrapper whose only job is to exist. Plus one `Memory:` line (the best single candidate for the later rule patch, or skip). |
| **Success / stop** | A short ranked list. Stop rather than covering every leftover in remaining-core. |
| **Feeds** | Coordinator. Apply step prefers these over adding parts. Later rule patch prefers this agent’s single memory candidate over four overlapping review lines. |

**Prompt-as-spec:**

```text
You are the lightweight/leverage improvements agent. Do not edit files. Do not launch agents.
Lens: smallest thing that still works; changelog may be long; README and runtime paths may not.
This repo is ASC core (mother). Project instances (e.g. Projet Complexe) are clients — do not put their specifics in a mother-rule proposal.
Read the four 2026-09-19 lazy-include sub-plans, the four review outputs, and .cursor/rules/asc-lightweight.mdc.
Prefer skips, order/delay, and clarifying callers over new includes. Refuse completeness tables and files with no caller.
Rank: keep / shrink / skip / delay.
Memory check: at most one proposed clause for asc-lightweight.mdc if a durable ASC fact is not already there; else Memory: skip. Prefer one lighter rule line over a new file.
One example per idea. Stop.
```

---

### Optional synthesis (do not prepare a standing role)

Only if the human finds six short artifacts harder than one delta list. Then one agent merges review + mistakes + improvements into **edits the human can apply to the four plans** (bullet deltas per file), plus **at most one** surviving memory proposal for the mother rule. Still must not edit those files, must not launch, must not implement, must not patch `.mdc`.

If the artifacts are already short, **skip this role** — the human applying is the loop’s high-leverage step (including deciding `Memory: skip`).

---

## The loop (information flow)

```text
[now]  Human reviews THIS meta-plan
          │  cut or keep the agent set
          │  cut or keep the later asc-lightweight.mdc clause
          ▼
[later] Human approves launch  ← nothing starts before this
          │
          ▼
        Four review siblings in parallel (independent; no shared findings)
          │  each ends with Memory: skip | rule | changelog
          ▼
        Mistakes  ∥  Improvements   (same delay; two channels)
          │  same memory check; improvements may keep at most one rule candidate
          ▼
        Human reads (synthesis only if volume hurts)
          │
          ├─► high-leverage edits to the four source plans
          └─► smallest mother-rule / changelog memory upgrade
              (or skip: already in the rule, or one-off)
          │
          ├── remaining contradictions are material?  → one optional second pass
          │     (same roles; same memory check; do not add a standing roster)
          └── otherwise stop this loop
          │
          ▼
        Implementation of the four plans is OUTSIDE this loop
        Project-instance (Projet Complexe) notes stay OUTSIDE the mother rule
```

Real-time means: one session (or a short series) after approval, human in the loop between phases, not a standing bureaucracy of agents.

Cooperative means: agents do not rewrite the plans or the rule; the human decides what is leverage vs noise.

The memory check does not add a phase. It is an information-flow tap on every step, aimed at the **paradigm** (the always-applied rule), which is higher leverage than adding process.

---

## Safety

- Launch is a **later human-approved step**. Preparing the lifecycle is not permission to run it.
- Reviews must not silently “fix” the four plans or `.mdc` files in the same turn as findings.
- A second pass is exceptional (material leftover contradictions), not a cadence. Memory: skip must not be used as an excuse to keep looping.
- Implementation, README paste, and commits stay on the source plans’ own open tasks, after this loop.
- Mother rule stays generic. Client stack (`projet-complexe-asc`) and UI (`projet-complexe`) are not this workspace.

---

## Pre-launch review (this chat)

**Path (item 2).** Opt-inc mirrors eager. Same path, other suffix; both must work:

- `$subject/$action.inc.sh` ↔ `$subject/$action.opt-inc.sh`
- `$extension/$extension.inc.sh` ↔ `$extension/$extension.opt-inc.sh`

Do not “fix” that by pinning only `db/db/db.opt-inc.sh`. If caller opt-inc does not load `$extension/$extension.opt-inc.sh` today, that is a plan/loader gap to apply — not a docs abbreviation.

**Overview (the rest).** Loop shape is fine (human holds it; no launch from this file). Gaps: hunt list is not in the prompts; four independent reviews hide cross-plan issues and are extra machinery; case table is the filename SoT but out of the apply set; chat-only reviews have no handoff. Extra hunts: mysql `exec` tar workaround is a third compression site; remaining-core says wait for fs+db *and* yaml anytime; `data/asc/` is gitignored so `active.sh` dual-`yml.inc.sh` is easy to miss; `dump.sh` always runs `f_db_dump` (test claim).

**Memory:** the mirror rule is a durable ASC fact — candidate one-liner for `asc-lightweight.mdc` after approval, not a new `.mdc`.

---

## Monitoring, judgement, testing, quality

No new harness, test agent, dashboard, or include. Reuse `make test-core`, `type -t`, `hook -t` / `hook_ms -t`, and grep. This loop watches **plans**; implementation (outside this loop) watches **runtime**.

### Monitoring strategy

**This loop (until apply):**

| Signal | Healthy | Unhealthy |
|--------|---------|-----------|
| Launch | Human named the set | Anyone launched from writing this file |
| Output | Short findings + `Memory: skip` | Patch dumps, new files, new `.mdc` |
| Apply | Four plans **and** the case table get the mirror rule / hunts, or an explicit skip | Path “fixed” by pinning only `db/db/db.opt-inc.sh` |
| Stop | One apply pass, loop ends | Second pass as cadence; memory check keeps the roster alive |

**After implementation (each source plan’s own tasks):**

1. **Absence first.** In a shell that only did kernel + `ASC_INC` (not the moved caller), `type -t f_fs_extract` / `f_db_dump` is empty. Then `.` the opt-inc (or run the real action) and it is a function. Today’s `*.test.sh` files all `. asc/bootstrap.sh` at the top — they **cannot** see absence until a test starts a nested bash or skips `ASC_INC`.
2. **Caller still works.** `make test-core`. Then one real action per slice: non-db `make` (fs not pulled), `make db-list-ids` (eager only), `make db-dump` only if this instance has a driver (instance-coupled — do not fake it in mother tests).
3. **Hook path.** `hook -t` does not define opt-inc symbols; a non-dry `hook` / `hook_ms` does. After adding a colocated opt-inc: `make cc` (or wipe `data/asc/cache/hook/`) or the cache still sources the old list (parent caveat 5).
4. **Mirror.** `$extension/$extension.opt-inc.sh` next to `$extension/$extension.inc.sh` must load for the same bootstraps that load the eager file **or** the plans must say it is explicit `.` — same as utils. `primitives.test.sh` today only checks **caller-dir** 2-level vs 3-level (`foobar.opt-inc.sh` next to `run.sh`), not the eager twin.
5. **Do not monitor** README row counts, parse-line dashboards, or a standing agent roster. Parse win is a follow-up `wc -l` on the moved files if someone cares; it is not a gate.

### Honest current judgement

The **loop** is the right shape (human-held, no auto-launch). It is already heavier than the four short plans: memory overlay + six prepared agents + optional synthesis. Cut to mistakes ∥ improvements unless the human keeps siblings on purpose.

The **four plans** are good enough to review, not good enough to implement as written:

| Plan | Judgement |
|------|-----------|
| Fs | Right split (explicit `.` from `utils/`). Unresolved: gzip-of-SQL vs `tar czf *.gz`; `f_fs_watch_poll` should likely **drop**, not move. |
| Db | Right pick (one subject-wide opt-inc, creds eager). **Collides with the mirror rule:** it calls `$extension/$extension.opt-inc.sh` wrong and puts the cluster in `db/db/db.opt-inc.sh`. Test claim sources `dump.sh` without running dump — wrappers always run `f_db_dump`. |
| Mysql | Correct **skip** unless grep shows sharing. Least need of a dedicated review agent. |
| Remaining | A pointer at the parent, not a slice. Status “wait for fs+db” vs “yaml anytime” is unresolved. Yaml dual-source is still true (`bootstrap.sh` **and** `ASC_INC` via gitignored `data/asc/cache/core/active.sh`). |

**Biggest unresolved design fact:** opt-inc must mirror eager, but caller opt-inc derives from `BASH_SOURCE[1]`’s directory, so `make db-dump` does not load `asc/extensions/db/db.opt-inc.sh` today. Apply must pick: change what the loader looks at, explicit `.` of the eager twin, or drop the “everywhere” claim for nested `$extension/$subject/$action.sh`. Do not invent a third loader (`ASC_OPT_INC`).

Case table is still **proposed**. Parent still gates code on agreeing it. This loop’s apply must touch that file or the gate stays folklore.

### Testing gaps

Already on disk and useful: `test_f_fs_compress_and_extract`, `test_f_hook_opt_inc_append_candidates`, `test_asc_bootstrap_opt_inc_two_level` / `_three_level`. Parent also lists wrap-vs-action dummy opt-inc — **not** implemented as a fail-before-source check.

Missing, one example each:

- **No absence test.** Compress tests pass today because `fs.inc.sh` is kernel. After the move they will fail until the test `.`s `fs.opt-inc.sh` — that fail-then-pass is the fs plan’s claim, and it is not written yet.
- **No kernel-only process.** `make test-core` → `asc/test/core.sh` → hook, full bootstrap. A “non-db action must not define `f_fs_extract`” needs a nested script whose caller is e.g. `asc/git/…`, not the test file itself.
- **Db wrappers are not sourcable.** No `BASH_SOURCE` guard; you cannot `. dump.sh` to define `f_db_dump` without dumping.
- **`make db-dump` / restore** need a live driver and a dump file. Mother `test-core` does not replace that. Mysql plan’s “still produces a dump” is instance QA, not a unit test. Restore/exec can be destructive — not a casual `make`.
- **Mysql exec tar workaround** (`exec.mysql.hook.sh`) is untested relative to `f_fs_extract_in_place` + `tar czf` in `f_db_dump`. Format unification has three sites, tests name two.
- **Mirror path** has no test. Candidate discovery for `dump.mysql.hook.sh` is specified; loading `$extension/$extension.opt-inc.sh` on `make db-dump` is not.
- **Hook cache / `-w`.** Parent caveat 13: warmup writes `. opt-inc` lines without defining functions in that shell. Easy to false-pass.
- **Remaining-core** has no tests of its own (yaml duplicate, `hook -s asc -a bootstrap -t` before moving `global()`).
- **No CI.** `make test-core` is local. Nothing fails a PR if an agent “reviews” a test claim without running it.
- **This loop** explicitly has **no test agent**. Coordinator (or later implementation) must run or mark **unverified**. Incomplete-and-honest.

### Other quality (easy to miss)

- **Prompt ≠ role table.** Hunts, mirror rule, and case table are in this file; prompt-as-spec still omits them. Agents will follow the short block.
- **Wrap ≠ action.** `call_wrap.make.sh` is another bash; caller opt-inc in the wrap does not see `db/dump.sh`’s opt-inc. In-process tests ≠ `make`.
- **Stale `@see`.** Wrappers still point at `db.inc.sh` and `asc/extensions/mysql` (contrib lives under `scripts/asc/contrib/`). Comment drift will teach the wrong path after the move.
- **Overrides.** Single-segment `asc` → `scripts/asc/override`. A lazy file that only exists under contrib is not found from a core hook path (parent caveat 4).
- **Other trees.** Parent caveat 9: CWT twins / `u_*` in other repos. This workspace is mother ASC only; a move can break a project instance without failing `make test-core` here.
- **Process eating the goal.** Memory-upgrade + six agents can become the work. Success is four clearer plans (and maybe one rule line), then **stop**. Parse-line counts and README matrices are not success.

---

## Findings (filled after launch)

*Empty until the human approves launch. Coordinator pastes a digest here or points at persisted `20-review-*.md` files. Include which `Memory:` lines were skip vs kept.*

---

## Next steps

- [ ] Approve **cut** (mistakes ∥ improvements only; synthesis off) or keep the four review siblings.
- [ ] Put this file’s hunt list + **mirror rule** in those prompts; require the case table as input; allow apply to touch it.
- [ ] Handoff: persist reviews only if siblings stay; otherwise nothing to forward.
- [x] Small [`asc-lightweight.mdc`](../../../.cursor/rules/asc-lightweight.mdc) garage clause ([20-garage-lightweight-rule.md](./20-garage-lightweight-rule.md)). Mirror paths still later. No new `.mdc`.
- [ ] Launch only after that. Then apply high-leverage edits to the four plans **and** the case table (still not code). Resolve mirror vs caller opt-inc in writing (loader look / explicit `.` / narrowed “everywhere”) — not a third loader.
- [ ] During apply and later implementation: use **Monitoring, judgement, testing, quality** above. Mark test claims run vs unverified. No test agent in this loop.
- [ ] Optional second pass only if leftover contradictions are material. Implementation stays on each source plan’s open tasks.
