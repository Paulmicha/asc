# Plan: ASC DSL in filename patterns

| Field | Value |
|-------|--------|
| **Date** | 2026-07-24 |
| **Status** | plan / review (not implemented; multi-shell groundwork WIP on branch) |
| **Scope** | ASC repo `/home/paul/Documents/asc` — filename grammar for subjects, actions, hooks, wraps; matching runtime actions; MAKE_TASKS_SHORTER abbreviations; **shell-agnostic runtime** (`ASC_SHELL`, multi-shell `inc` / `opt-inc`); primordial layout under `asc/asc/` |
| **Related** | Prior idea `data/ideas/2026/07/23/dsl.md` (**syntax superseded** by this plan); `data/ideas/2026/07/23/wrappers-nest-bridges.md`; `data/ideas/2026/07/23/genericity-taxonomy.md`; `docs/asc/organization.md` (subjects/actions/hooks); `docs/asc/wrappers.md`; `docs/asc/archive/hooks.md`; naming plan `changelog/2026/07/23-f-e-naming-convention.md` (`p_` / `o_` / `f_*`); WIP on `naming-convention-changelog`: `648a4d7` (begin multi shell), `8f3faa8` (utilities → `asc/asc/`), `f971316` (**final primordial layout**: eager `*.inc.sh` core + `asc/asc/utils/*.opt-inc.sh`) |
| **Lifecycle** | Local review stub: `data/plans/review/2026-07-24-filename-dsl.md` (dir mostly gitignored — **this changelog is the tracked SoT**, same pattern as `23-f-e-naming-convention.md`). Move stub across `review` → `iterate` → `accepted` / `rejected` per `data/ideas/2026/07/23/idea-changelog-workflow.md`. |

---

## Context

ASC already treats **folders as subjects** and **files as actions**, with hooks as dotted / prefixed filename events (`*.hook.sh`, optional `-c yml`) and wraps as `*.wrap.sh`. Make shortcuts and synonyms (`lt`, `ll`, …) shorten operator surface; living docs still describe lookup mostly as dotted variants (`init.local.dev.hook.sh`).

Operators want a **filename DSL** so a single path under `$subject/$action/` can encode wrap stacks, nest chains, and arg/option payloads — and so each DSL construct maps to a concrete **matching action** (`wrap`, `nest`, `arg` / option semantics).

The same filename / include surface must stay **shell-generic**: today’s default runtime is bash, but bootstrap `inc` / `opt-inc` (and eventually DSL suffixes) need to select implementations by **`ASC_SHELL`** (posix, powershell, cmder, …) without forking the subject/action model.

**Groundwork already pushed (WIP, incomplete):** see [Multi-shell groundwork](#multi-shell-groundwork-already-pushed). Completing that wiring is **in scope for this plan** (before or alongside DSL parser work) — not a separate abandoned experiment.

**This document is plan-only for the DSL parser / loaders.** Do not implement parsers, generators, or new hook loaders until the plan is accepted and implementation is explicitly requested. Completing the already-pushed multi-shell groundwork is an explicit work item below; still do not expand it until go-ahead.

---

## Goals

1. Define a **filename grammar** for ASC DSL fragments used in paths under any `$subject` (and especially `$subject/$action/…`).
2. Bind each construct to a **matching action** name and semantics.
3. Align **MAKE_TASKS_SHORTER** abbreviations (`arg`, `o`, `f`) with synonyms and **variable prefixes**.
4. Require that **`$action` files are explicitly created** (including when generated under `data/asc`) — no invisible “function-only” actions.
5. Leave room for **smart YAML defaults** (`*.hook.yml`) with future `asc.extendable` / `asc.overridable` knobs.
6. Keep the DSL / include runtime **shell-agnostic**: default `ASC_SHELL=bash`, alternate shells via filename / lookup conventions; **finish implementing** the multi-shell groundwork already on the branch.

Non-goals for this plan: shipping the full DSL parser; rewriting existing `*.hook.sh` trees wholesale; changing make synonym maps in code; implementing non-bash shell bodies in v1 (convention + lookup first).

---

## Filename DSL grammar

Informal EBNF (filename / path fragment level; separators are literal characters in the name):

```text
fragment     := atom ( nest | wrap | args )* ( '.' token )* suffix?
atom         := name
name         := [A-Za-z0-9_-]+
nest         := '.' atom          # nester: foo.bar
wrap         := '(' fragment ')'  # wrapper: foo(bar)
args         := '[' arglist ']'
arglist      := arg ( ',' arg )*
arg          := positional | option
positional   := freeform          # no o- prefix
option       := 'o-' freeform     # option token
freeform     := [A-Za-z0-9_.-]+   # agnostic token (may itself nest/wrap in full grammar — see phases)
suffix       := '.' ( 'hook' | 'wrap' | 'inc' | 'opt-inc' | … ) ( '.' shell_id )? ( '.' variant )* ( '.' ext )
shell_id     := 'posix' | 'powershell' | 'cmder' | …   # omitted ⇒ ASC_SHELL default (bash)
ext          := 'sh' | 'yml' | 'ps1' | …                 # ext may follow shell_id / shell family
```

**Shell in the suffix:** default bash implementations keep today’s shapes (`*.inc.sh`, `*.opt-inc.sh`, `*.hook.sh`). Non-default shells insert an explicit **`shell_id`** before the extension (or as a compound suffix), e.g. `shell.opt-inc.posix.sh`. Lookup prefers `ASC_SHELL`-qualified files, then falls back to the unqualified default when appropriate (open: strict vs fallback).

### Constructs → matching actions

| Construct | Shape | Matching action | Semantics |
|-----------|--------|-----------------|-----------|
| **Wrapper** | `foo(bar)` | `wrap` | Outer `foo` wraps inner `bar` (call/supervision stack). Same family as today’s `*.wrap.sh` / logged wrappers (`lt`, `ll`, …). |
| **Nester** | `foo.bar` | `nest` | `bar` is nested under / relative to `foo` (scope, subject nesting, or nested entry). Distinct from wrap — see wrappers-vs-nesters. |
| **Args (bracket list)** | `foo[…]` | `arg` (and option rules below) | Declares arguments for `foo`; list is ordered; members classified as positional vs option. |

#### Arg list variants

| Pattern | Matching action / rule | Notes |
|---------|------------------------|-------|
| `foo[bar]` | positional `arg(*)` | Agnostic / **freeform** synonym: single positional payload `bar`. |
| `foo[bar,o-option-bar]` | `option("o-*")` \| `arg(*)` | Mix: freeform positional + option token(s) prefixed `o-`. |
| `foo[bar,o-option-bar,bar_2,o-option_other-bar_2]` | `arg(o("o-*") \| *)` | Ordered list: each member is either an `o-*` option or a freeform positional (`*`). |

**Option token rule:** any bracket member starting with `o-` is an **option**; everything else in `[]` is a **positional / freeform** argument.

**Nest vs wrap (do not conflate):**

- `foo.bar` → **nest** (structure / ownership / nested subject plane).
- `foo(bar)` → **wrap** (runtime supervision / launch stack).
- Earlier raw idea (`data/ideas/2026/07/23/dsl.md`) swapped these punctuation roles (`.` = wrap, `()` = nest). **This plan is SoT;** that idea is historical and should be marked superseded when docs are updated.

---

## MAKE_TASKS_SHORTER abbreviations

Proposed shortening map entries (name illustrative; wire into the same synonym / make-shortening machinery as `ASC_SYNONYMS` / existing `lt`/`ll` maps when implementing):

| Key | Expansion | Synonyms | Variable prefix |
|-----|-----------|----------|-----------------|
| `arg` | argument | positional arg, positional argument | `p_` |
| `o` | option | option, optional arg, optional argument | `o_` |
| `f` | function | entry point, action (workflow-equivalent) | **none** |

### Variable prefix rules

| Class | Prefix | Rule |
|-------|--------|------|
| Argument (positional / freeform) | `p_` | Shell locals / params for DSL positionals (aligns with naming plan + organization ideas). |
| Option | `o_` | Shell locals / params for `o-*` DSL options (aligns with `changelog/2026/07/23-f-e-naming-convention.md`). |
| Function / entry point / action | *(none)* | Do **not** invent a `f_` *variable* prefix for actions. From a workflow standpoint, “function”, “entry point”, and “action” name the **same operable unit**. |

### Explicit `$action` files (hard rule)

Corresponding **`$action` files must be explicitly created**, even when generated under `data/asc/`:

- Discovery remains “files = actions” (`docs/asc/organization.md`).
- Generated trees may *emit* action files, but must not invent callable make/hooks that have no on-disk `$subject/$action…` artifact.
- `f` / function / entry-point abbreviations shorten **task names**, not a hidden symbol table.

**Note:** The separate naming-convention plan uses `f_*` for **shell utility functions** (`u_*` → `f_*`). That is a **code symbol** prefix, not a filename-DSL / make-task variable prefix. Do not confuse `MAKE_TASKS_SHORTER[f]` (no action var prefix) with `f_*` utility renames.

---

## Shell genericity (`ASC_SHELL` + multi-shell includes)

The DSL must be able to express **what ASC does today** (bash as default shell) while remaining **implementation-generic** across shells. Filename grammar, subject/action layout, and bootstrap include kinds (`inc` / `opt-inc`) stay the same; **which file body loads** depends on `ASC_SHELL`.

### `ASC_SHELL`

| Rule | Detail |
|------|--------|
| Default | `ASC_SHELL=bash` (current behavior; no qualified suffix required) |
| Source of truth (config) | Instance / specimen YAML already sketches `asc.shell` / `includes.default.shell` (see groundwork) |
| Runtime export | Wire YAML → exported `ASC_SHELL` (and keep overrideable from env) |
| Alternates (illustrative) | `posix`, `powershell`, `cmder`, … — especially relevant on Windows hosts |
| Constraint | Bootstrap and include discovery must select files by `ASC_SHELL` without hard-coding only bash paths forever |

### Filename convention for shell-specific includes

Settled path pattern (default bash vs explicit shell target), using the locked primordial layout:

```text
# Default shell (ASC_SHELL=bash) — unqualified:
asc/asc/utils/shell.opt-inc.sh

# Explicit shell target:
asc/asc/utils/shell.opt-inc.posix.sh
asc/asc/utils/shell.opt-inc.powershell.ps1   # ext policy still open
```

Same idea applies to eager `*.inc.sh`, hooks, wraps, and DSL-bearing stems: **unqualified = default bash**; **`.{shell_id}.` before ext = that shell’s body**.

### Primordial layout (settled in `f971316`)

Core lives under the **`asc` subject** (`asc/asc/…`) — not a separate `asc/shell/` subject for utilities.

| Kind | Path pattern | Role |
|------|--------------|------|
| Eager core | `asc/asc/{core,global,hook,autoload}.inc.sh` | Bootstrap-critical includes (`*.inc.sh`); `asc.opt-inc.sh` **renamed → `core.inc.sh`** (avoid subject/action name clash with subject `asc`) |
| Lazy utils | `asc/asc/utils/{array,fs,shell,string}.opt-inc.sh` | Optional utilities under nested `utils/` |
| Other (current) | `asc/asc/yaml.opt-inc.sh` | Still at subject root as `*.opt-inc.sh` (not moved into `utils/` in this push) |

**Decided:** keep helpers under `asc/asc/` (+ `utils/` nest); do **not** reintroduce `asc/shell/` as the home for these files. Suffix convention + `ASC_SHELL` lookup remain the hard multi-shell rules.

### Bootstrap `inc` / `opt-inc` refactor (multi-shell)

Today’s model (eager `*.inc.sh` → `ASC_INC`; lazy phase-90 `*.opt-inc.sh`) must be refactored so discovery:

1. Resolves **`ASC_SHELL`** early (phase 10 / pre-utilities; default `bash`).
2. Loads include candidates as **shell-qualified first**, then unqualified default (policy TBD).
3. Stops assuming only `#!/usr/bin/env bash`, `BASH_SOURCE`, and `shopt` for all future shells — bash remains the reference implementation; other shells get parallel entry/bootstrap later.
4. Updates phase **20** (core includes) and phase **90** (caller opt-inc) — and hook-cache opt-inc seeding — to the **settled** paths (`asc/asc/*.inc.sh`, `asc/asc/utils/*.opt-inc.sh`) + suffix rules.
5. Keeps **genericity of implementation**: same subject/action/`inc`/`opt-inc` taxonomy; shell is a dimension of the filename / lookup, not a fork of ASC’s organization model.

---

## Multi-shell groundwork (already pushed)

Branch `naming-convention-changelog` (ahead of `main`) already started this. **Complete implementing that WIP** as part of this plan (before treating multi-shell as “done”).

| Commit | What landed | Still incomplete |
|--------|-------------|------------------|
| `648a4d7` *wip: begin multi shell support* | `SPECIMEN.env.yml`: `asc.shell: bash` (+ TODO); `SPECIMEN.remote_instances.yml`: `includes.default.shell: bash` wired into env includes; intermediate rename toward `asc/shell/utilities.opt-inc.sh` | No `ASC_SHELL` export; bootstrap still bash-only; no `.opt-inc.{shell}` lookup |
| `8f3faa8` *wip: move utilities to asc/asc (primordial genericity)* | Core utilities relocated under `asc/asc/*.opt-inc.sh`; removed `utilities` from `asc/.asc_subjects_ignore` so `asc` can be a real subject | Superseded path layout by `f971316`; bootstrap still pointed at old `asc/utilities/` |
| `f971316` *wip: update primordial implementation* | **Final primordial layout:** eager `asc/asc/{core,global,hook,autoload}.inc.sh` (`asc` → **`core`**); lazy `asc/asc/utils/{array,fs,shell,string}.opt-inc.sh`; plan doc updated for shell genericity | **`asc/bootstrap/20-utilities.bootstrap-inc.sh` still sources `asc/utilities/*.sh`** (paths gone — bootstrap broken until rewired); no `ASC_SHELL` export; no shell-qualified lookup; phase 90 / docs / caches still describe old `utilities/` + flat layout |

**Completion work (explicit):**

- [ ] Rewire bootstrap phase 20 (and any other hard-coded `asc/utilities/…` refs) to settled paths: eager `asc/asc/*.inc.sh` + lazy `asc/asc/utils/*.opt-inc.sh` (and `yaml.opt-inc.sh` as appropriate).
- [ ] Introduce **`ASC_SHELL`** (default `bash`) from env / `asc.shell` YAML; document override order.
- [ ] Extend eager `inc` + lazy `opt-inc` (+ hook-seeded opt-inc) discovery for **shell-qualified filenames**; keep unqualified bash as default.
- [x] Decide final home for shell utilities — **settled:** `asc/asc/utils/shell.opt-inc.sh` (not `asc/shell/…`).
- [x] Split primordial eager vs lazy — **settled:** core/global/hook/autoload → `*.inc.sh`; array/fs/shell/string → `utils/*.opt-inc.sh`; rename `asc` → `core`.
- [ ] Smoke: `. asc/bootstrap.sh` works again on bash; dry-run / notes for posix (and later powershell/cmder) lookup without requiring full ports yet.
- [ ] Update living docs (`docs/asc/organization.md`, bootstrap archive) for multi-shell include suffixes + primordial layout.

---

## Concrete examples (any `$subject` dir)

Paths are illustrative; exact lookup roots stay `asc/`, extensions, contrib, extend (and overrides).

### 1. Simple wrapped source hook (custom shell)

```text
$subject/$action/source(code).available.hook.sh
```

- `source(code)` → **wrap** (`source` wraps `code`).
- Trailing `.available.hook.sh` → hook event / variant surface (existing hook naming).
- `.sh` → custom wrapper implementation (sourceable shell).

### 2. Logged-thread style stack with nests + args (custom shell)

```text
$subject/$action/lt(agent[role-prompt-analyst].start[loop.heartbeat](data[inbox].unread).start.hook.sh
```

Interpretation (intent; balance/paren nesting to be formalized in Phase 1 grammar tests):

| Fragment | Action |
|----------|--------|
| `lt(…)` | **wrap** — logged-thread (or synonym) wraps the inner chain |
| `agent[role-prompt-analyst]` | **arg** — positional freeform `role-prompt-analyst` on `agent` |
| `agent[…].start` | **nest** — `start` nested under `agent[…]` |
| `start[loop.heartbeat]` | **arg** + inner **nest** `loop.heartbeat` as freeform / nested token inside brackets |
| `…(data[inbox].unread)` | **wrap** of nested `data[inbox].unread` |
| `data[inbox]` | **arg** positional `inbox` on `data` |
| `.start.hook.sh` | hook suffix / phase |

If the script is a **custom wrapper**, keep **`.hook.sh`**.

### 3. Same shape with smart YAML defaults

```text
$subject/$action/lt(agent[role-prompt-analyst].start[loop.heartbeat](data[inbox].unread).start.hook.yml
```

- Same DSL filename meaning as (2).
- **`.yml`** → use **smart defaults** instead of a hand-written shell body.
- **TODO (open):** `asc.extendable` + `asc.overridable` (names TBD) so YAML hooks can declare whether project extend/override layers may refine defaults — complements today’s `scripts/asc/extend` / `scripts/asc/override` and `-c yml` hook lookup.

---

## Alignment with existing conventions

| Existing | How this plan fits |
|----------|-------------------|
| Subjects = folders, actions = files | DSL lives *in* action/hook filenames; does not replace folder subjects. |
| `*.hook.sh` / `hook -c yml` | Suffix `.hook.sh` vs `.hook.yml` chooses impl style; DSL is the *stem*. |
| `*.wrap.sh`, logged wrappers `lt`/`ll`/… | `foo(bar)` **wrap** should resolve toward wrap scripts / make wrap stacks. |
| Nested subjects / `.asc_subjects_ignore` | `foo.bar` **nest** should map toward nest/nested-extension semantics (`docs/asc/wrappers.md` § nested). |
| `p_` / `o_` naming plan | Bracket positionals → `p_*`; `o-*` tokens → `o_*`. |
| `data/asc/` generated state | May generate files; still must materialize explicit `$action` artifacts. |
| Variant dotted hooks today (`init.local.dev.hook.sh`) | Remain valid; DSL adds `()`, `[]`, and richer stems — precedence vs pure variant dots is an open task. |
| Eager `*.inc.sh` / lazy `*.opt-inc.sh` | Multi-shell: same kinds; optional `.{shell_id}` before ext; `ASC_SHELL` drives lookup. Primordial: eager core at `asc/asc/*.inc.sh`, lazy utils at `asc/asc/utils/*.opt-inc.sh`. |
| Bootstrap phases 10–90 | Phase 20 + 90 (and hook opt-inc seeding) must complete WIP path move + shell-aware discovery. |
| `asc.shell` in specimen YAML | Groundwork for `ASC_SHELL`; wire through instance init / globals. |
| Core under `asc/asc/` (+ `utils/`) | **Settled layout** (`f971316`); finish bootstrap rewire to these paths. |

---

## Implementation phases (for later coding)

### Phase 0 — Accept / freeze grammar (+ shell SoT)

- [ ] Accept or amend this plan (review → iterate → accepted).
- [ ] Freeze punctuation SoT (`()` = wrap, `.` = nest, `[]` = args) vs superseded `dsl.md` idea.
- [ ] Decide interaction with today’s dotted **variant** filenames (same `.` character).
- [ ] Name and sketch `asc.extendable` / `asc.overridable` (or reject names).
- [ ] Freeze **shell suffix** convention (`*.opt-inc.sh` vs `*.opt-inc.{shell}.sh`) and fallback policy.
- [x] Freeze **`ASC_SHELL`** default (`bash`) and YAML key sketch (`asc.shell`) — export wiring still TODO.
- [x] Freeze **primordial layout** (`f971316`): `asc/asc/*.inc.sh` eager core + `asc/asc/utils/*.opt-inc.sh`; `core` not `asc` for the core include file.

### Phase 0b — Complete multi-shell groundwork (already pushed)

- [ ] Finish WIP from `648a4d7` / `8f3faa8` / `f971316`: bootstrap rewire to settled paths, `ASC_SHELL` export, shell-qualified `inc`/`opt-inc` lookup, docs — see [Multi-shell groundwork](#multi-shell-groundwork-already-pushed).
- [ ] Restore working bash bootstrap against `asc/asc/*.inc.sh` + `asc/asc/utils/*.opt-inc.sh`.
- [ ] Do **not** treat multi-shell as closed until phase-20/90 + discovery smoke pass.

### Phase 1 — Spec + tests (no production DSL wiring)

- [ ] Formal grammar + lexer rules (escaping, allowed chars, max depth; shell_id in suffix).
- [ ] Golden filename → AST fixtures (include the three examples above + one shell-qualified include).
- [ ] Document AST → matching actions (`wrap` / `nest` / `arg` / option).

### Phase 2 — Runtime matching actions

- [ ] Implement or map to existing `wrap` / nest helpers.
- [ ] Bind bracket members to `p_*` / `o_*` in calling scope.
- [ ] Ensure make/task shortening understands `arg` / `o` / `f` synonyms.

### Phase 3 — Hook loaders + YAML smart defaults

- [ ] Teach hook discovery to parse DSL stems (or pre-normalize to cache keys).
- [ ] Respect `ASC_SHELL` when resolving `.hook*` / seeded opt-inc bodies.
- [ ] `.hook.yml` smart-default loader; stub extendable/overridable policy.
- [ ] Cache layout: prefer readable paths under `data/asc/…` if regenerating caches (see organization.md ideal cache shape).

### Phase 4 — Explicit action materialization

- [ ] Generator / builder: always emit concrete `$action` files when DSL expands entry points.
- [ ] Refuse “function-only” make targets with no file artifact.
- [ ] Docs: organization + wrappers + hooks + bootstrap multi-shell; mark old `dsl.md` punctuation superseded.

### Phase 5 — Verification

- [ ] Unit tests on parser; hook dry-run (`-t`) lists DSL paths.
- [ ] Smoke: custom `.hook.sh` vs `.hook.yml` defaults; bash bootstrap after groundwork completion.
- [ ] Smoke: shell-qualified include lookup for at least one non-default `ASC_SHELL` (file present / missing fallback).
- [ ] `make reinit` / `make cc` after registry changes.
- [ ] Grep/docs gates for SoT punctuation, prefix rules, and `ASC_SHELL` / suffix convention.

---

## Risks / safety notes

| Risk | Notes |
|------|--------|
| `.` overload | Nest DSL vs existing variant dots vs optional `shell_id` — ambiguous without precedence rules. |
| Shell-hostile filenames | `()`, `[]` in paths can break naive scripts; need quoting conventions and maybe encoded cache names. |
| Superseding `dsl.md` | Agents may follow old idea; changelog + idea banner required when accepted. |
| Confusing `f` abbrev with `f_*` utilities | Document both namespaces in living docs when implementing. |
| Generated-only actions | Violates explicit-file rule; treat as bug. |
| Broken bootstrap (WIP) | Utils moved + renamed; phase 20 still points at `asc/utilities/` — must complete groundwork before other runtime work. |
| Bash-only assumptions | `BASH_SOURCE`, `shopt`, shebangs — multi-shell is lookup-first; full ports are later. |
| Plan-only (DSL) | Do not land parser/loader changes until accepted + requested. |

**Safety:** do not hand-edit gitignored generated caches as SoT; regenerate. Do not implement in nested/foreign repos from this work tree.

---

## Open questions

1. **Variant dots vs nest dots:** same character — require a delimiter, reserved suffix zone (`.hook` / `.wrap` / `.opt-inc` / `.inc`), or parse right-to-left from known suffixes?
2. **Nested DSL inside `[]` / `()`:** allow full fragments recursively in v1, or only flat tokens first?
3. **`asc.extendable` / `asc.overridable`:** file-level YAML keys, entity `.able.yml`, or hook metadata?
4. **MAKE_TASKS_SHORTER wiring:** new global map vs extend `ASC_SYNONYMS`?
5. **Example (2) paren balance:** confirm canonical spelling of the long `lt(agent…` example before locking fixtures.
6. **Relation to make `e:` / `a:` notation:** keep both, or eventually express CLI args with the same `[]` / `o-` grammar?
7. **Should `wrap` / `nest` become first-class subjects/actions** (`asc/wrap/`, `asc/nest/`) or stay internal matcher verbs?
8. **Shell suffix vs extension:** `*.opt-inc.posix.sh` vs `*.opt-inc.sh` + parallel tree vs `*.opt-inc.ps1` — single convention for all shells?
9. **Fallback:** if `ASC_SHELL=posix` and only unqualified `.opt-inc.sh` / `.inc.sh` exists, load it or fail closed?
10. **`yaml.opt-inc.sh` placement:** leave at `asc/asc/yaml.opt-inc.sh`, move under `utils/`, or promote to eager `*.inc.sh`?
11. **Windows shells:** map `powershell` / `cmder` to which ext and bootstrap entry (separate `bootstrap.ps1` later)?

---

## Open tasks (summary)

- [ ] Review this plan; move to `data/plans/iterate/` or `accepted/` / `rejected/`
- [ ] Update or banner `data/ideas/2026/07/23/dsl.md` as superseded on accept
- [ ] Phase 0 decisions (especially `.` ambiguity, YAML extend/override names, shell suffix / fallback SoT)
- [ ] **Complete multi-shell groundwork** already pushed (`648a4d7`, `8f3faa8`, `f971316`) — Phase 0b
- [ ] Implement DSL only after explicit go-ahead (Phases 1–5)

---

## Appendix — Quick reference card

```text
foo(bar)                         → wrap
foo.bar                          → nest
foo[bar]                         → arg(*) freeform / positional  → p_
foo[bar,o-option-bar]            → option(o-*) | arg(*)          → o_ / p_
foo[a,o-x,b,o-y]                 → arg(o("o-*") | *)             → ordered mix

MAKE_TASKS_SHORTER:
  arg → argument (p_)
  o   → option   (o_)
  f   → function / entry point / action  (no var prefix; explicit $action file)

ASC_SHELL (default bash):
  asc/asc/utils/shell.opt-inc.sh           → default (bash)
  asc/asc/utils/shell.opt-inc.posix.sh     → explicit posix target
  # powershell / cmder / … via same shell_id slot

Primordial layout (settled):
  asc/asc/{core,global,hook,autoload}.inc.sh     → eager
  asc/asc/utils/{array,fs,shell,string}.opt-inc.sh → lazy
```
