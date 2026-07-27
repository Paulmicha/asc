# Enforce `f_*` / `e_*` / `o_*` naming in ASC-bootstrapped scripts

| Field | Value |
|-------|--------|
| **Date** | 2026-07-23 |
| **Status** | plan (not implemented) |
| **Scope** | ASC repo `/home/paul/Documents/asc` — shell sources under bootstrap surface |
| **Related** | Idea `data/ideas/2026/07/18/organization-(globals,subjects,actions,hooks,variants,bootstrap).md`; `docs/asc/organization.md` § globals (planned naming, not enforced); root README § Current status (**positional SoT `a` / `a_*`**); branch names `naming-convention-changelog` / `naming-conventions-changes` (no rename commits yet) |

---

## Context

ASC is a shell scaffolding toolkit. Almost every action starts with:

```bash
. asc/bootstrap.sh
```

Bootstrap (`asc/bootstrap.sh` + `asc/bootstrap/*.bootstrap-inc.sh`) loads utilities, globals, primitives, eager `*.inc.sh`, hooks, then caller `*.opt-inc.sh`. Code that runs after that bootstrap is **ASC-bootstrapped script surface**.

Today:

- Utilities are prefixed `u_*` (historical CWT-era “utility”).
- Exported runtime / wrap vars are mostly unprefixed `ASC_*` (plus a few others) via bare `export NAME=…`.
- CLI option storage often reuses the **`p_*`** tip prefix (legacy name shared with tip positionals), which blurs the planned distinction `a` / `a_*` = positional vs `o_` = options (tip still uses legacy `p_*` for both).

Ideas and living docs already sketch a stricter prefix scheme; this changelog turns **functions**, **exported variables**, and **CLI option variables** into an actionable migration plan — including **file-header / code comments and living docs** that still describe the old conventions (e.g. “prefixed by `u` for utility”).

**This document is plan-only.** Do not apply renames or comment rewrites until the open questions below are decided and implementation is explicitly requested.

---

## Naming convention to enforce

### Functions

| Rule | Detail |
|------|--------|
| Shape | `{{ prefix }}_{{ name }}` |
| Utility / library functions | prefix `f` |
| Convert from | `u_([A-Za-z0-9\-_]+)` → `f_$1` |
| Meaning | Every `u_*` definition and call site becomes `f_*`, **except** the hardcoded special case below |

Examples: `u_fs_relative_path` → `f_fs_relative_path`.

#### Hardcoded exception (do not apply `f_*`)

| Old symbol | New symbol | Notes |
|------------|------------|--------|
| `u_hook_most_specific` | **`hookms`** | **Not** `f_hook_most_specific` |

- **Definition:** `asc/utilities/hook.sh` (`u_hook_most_specific()` ~line 834).
- **Call sites / refs:** ~**105** hits across `*.sh` / `*.md` (core instance/host/log/loop, many extensions + contrib db/agent hooks, README, `docs/asc/**`, ideas). Rename **everywhere**: def, calls, `@see`, dry-run strings, docs.
- **Implementer rule:** rename this symbol **first** (or exclude it from the mechanical `u_*`→`f_*` table), then run the general convert. Post-check must show **zero** leftover `u_hook_most_specific` and **zero** accidental `f_hook_most_specific`.

### Variables (exported)

| Rule | Detail |
|------|--------|
| Shape | `{{ prefix }}_{{ name }}` |
| Exported variables | prefix `e` |
| Convert from | `export ([A-Za-z0-9\-_]+)=` → `export e_$1=` |
| Meaning | Bare `export FOO=` becomes `export e_FOO=` (and all readers/writers of `FOO` in bootstrapped code must follow) |

**Note on prior idea text:** the 2026-07-18 idea stub used `c_foobar` for “mutable constant exports,” and `docs/asc/organization.md` still mentions `c_foobar`. **This plan follows the user’s `e_*` rule** for exports. Align docs/`c_*` wording when implementing (open question: retire `c_*` idea or keep for a different class).

### Variables (CLI options / flags)

| Rule | Detail |
|------|--------|
| Shape | `{{ prefix }}_{{ name }}` |
| Option / flag variables | prefix `o` |
| Convert from | Variables assigned in **option** `case` arms of a `while` arg-parser → `o_*` |
| Typical source shape | `p_ascii_dry_run` → `o_ascii_dry_run` (when that var is set from `-r)`, `-y)`, `-o)`, etc.) |

**Scope of conversion (strict):**

**ONLY** rename variables that are assigned inside `while …; do` / `case "$1" in` branches that match **option flags**, e.g.:

- `-o)`, `-s)`, `-y)`, `-r)`, `-a)`, `-h)`, `-t)`, `-p)`, `-d)`, …
- Long forms: `-i|--input-dir)`, `-l|--output-lang)`, …
- Catch-all unknown-option arm: `-* )` (error path — usually no storage rename)

**DO NOT** convert:

- Positional-argument handling in those loops: the `*)` unnamed/positional branch
- Variables that are **purely positional** (including ones populated only from `*)`)
- The vast majority of `p_*` used as **function parameters** (`local p_foo="$1"`) with no CLI option parser

**Canonical example** (`u_instance_init` in `asc/instance/instance.inc.sh`):

```bash
while [[ $# -gt 0 ]]; do
  case "$1" in
    -o) p_ascii_project_docroot="$2"; shift 2;;
    -s) p_ascii_stack_version="$2"; shift 2;;
    -a) p_ascii_apps="$2"; shift 2;;
    -h) p_ascii_host_type="$2"; shift 2;;
    -t) p_ascii_instance_type="$2"; shift 2;;
    -p) p_ascii_provision_using="$2"; shift 2;;
    -y) p_ascii_yes=1; shift 1;;
    -r) p_ascii_dry_run=1; shift 1;;
    -*) echo "Error ... unknown option: $1" >&2; return;;
    *) echo "Notice ... unsupported unnamed argument: $1" >&2; shift 1;;
  esac
done
```

In that example, every `p_ascii_*` assigned in `-o)` … `-r)` arms becomes `o_ascii_*`. The `*)` branch must **not** drive renaming of unrelated positional tip `p_*` vars (target `a_*`).

**Also rename** declarations, YAML-seed assignments, later reads, and docs for those same option symbols (once identified as option-driven) — not only the `case` arm lines.

### Explicitly *not* part of blind / global renames

| Prefix / class | Current use | This plan |
|----------------|-------------|-----------|
| `a` / `a_*` (positional / function args) | Tip still ~215 legacy `p_*` names (`local p_foo="$1"`); target prefix **`a` / `a_*`** | **Leave alone** during option→`o_*` pass unless proven option-driven (then `o_*`); later rename remaining positionals `p_*`→`a_*` |
| `o_*` | Planned options; **0** uses today | Target prefix for option storage |
| `FOOBAR` / `global NAME` | Readonly instance globals via `global()` | Separate track — not the same as bare `export` |
| `foobar` locals | Unprefixed locals | Leave alone |
| Make tokens `e:<entry>` | Runner CLI notation | Unrelated; do not confuse with `e_*` shell vars |

---

## What “ASC-bootstrapped scripts” means (in-scope definition)

**In scope:** any tracked shell (and docs that document those symbols) that:

1. Sources `. asc/bootstrap.sh`, **or**
2. Is loaded by bootstrap (utilities, bootstrap phase includes, eager/lazy includes, hooks, wrap scripts), **or**
3. Defines/calls `u_*`, `export NAME=`, or CLI option-storage vars used by that surface, **or**
4. Contains comments/docs that state the old naming conventions (file-header `Convention : …` lines, living docs, builder templates).

Practical path roots:

| Path | Role |
|------|------|
| `asc/bootstrap.sh`, `asc/bootstrap/` | Orchestrator + phases |
| `asc/utilities/` | Core `u_*` libraries (phase 20) |
| `asc/{env,instance,host,git,log,loop,thread,make,test,sidecar,asc}/` | Core subjects / actions |
| `asc/extensions/**` | Opt-in extensions (largest bootstrap caller set) |
| `scripts/asc/contrib/**` | Contrib implementations |
| `scripts/asc/extend/**`, `scripts/asc/override/**` | Project customize (mostly empty / local-gitignored patterns) |
| `docs/asc/**`, `README.md`, selected `data/ideas/**` | Documentation call sites |
| `Makefile`, `asc/make/**`, generated.mk *regeneration* | Make targets that mention function names in comments/docs |

**Bootstrap caller inventory (approx.):** 285 files contain `. asc/bootstrap.sh` (211 under `asc/extensions`, 21 `asc/instance`, 16 `scripts/asc`, rest core subjects).

---

## In-scope vs out-of-scope

### In scope

- All tracked `*.sh` under `asc/` and `scripts/asc/` that define or call `u_*`.
- All tracked docs/markdown that name `u_*` functions (~**71** md hit lines across ~**15** files, excl. this plan).
- Literal `export NAME=` / indented `export NAME=` of ASC-owned names, plus every read/write of those names in bootstrapped scripts.
- **CLI option-storage vars** identified from option `case` arms (see inventory), plus their decls/reads/docs in the same functions/scripts.
- Comments, `@see`, and test assertions that stringify function or option names (only where they must stay accurate).
- **Convention / naming traces** in shell headers, templates, **READMEs**, and living docs — update **only** renaming-related identifiers and convention statements (see Phase 4; **no prose rephrase**).
- After code change: clear ASC caches / reinit so generated primitives/hooks do not keep stale strings (see verification).

### Out of scope (do not mechanically rewrite)

| Path / class | Why |
|--------------|-----|
| `data/asc/*` (gitignored generated: `global.vars.sh`, caches, `generated.mk`) | Regenerate via `make reinit` / `make cc`; do not hand-edit |
| `.env`, `.env-local*`, compose yml | Generated / local; regenerate or leave |
| `data/{tmp,logs,threads,loops,cronjobs,test-results}/**` | Runtime artifacts |
| Upstream CWT / other nested repos | None nested under this work tree; home CWT is a different repo — **not** this migration |
| Third-party env names used for interoperability | e.g. `GIT_TERMINAL_PROMPT` — see open questions |
| Dynamic `export "${p_namespace}_SUBJECTS"` style | Regex `export NAME=` does not match; needs a dedicated pass |
| Non-shell languages, vendor blobs | N/A in this repo |
| `data/plans/**` placeholders | Empty READMEs; not code |
| **All `p_*` not proven option-driven** | ~215 unique `p_*`; renaming blindly would break almost every function signature |
| Unrelated “convention” comments | e.g. hook `pre`/`post` prefixes, `*_C` container paths, `$DB_ID` var prefixes, docker network naming — **do not** rewrite those as `f_`/`e_`/`o_` |
| Vendored docs (`asc/vendor/**`) | Out of scope |

---

## Inventory (exploration snapshot, 2026-07-23)

Counts from workspace scan (grep over tracked `*.sh` / `*.md`). Treat as estimates; re-count at implementation start.

### Functions `u_*` → `f_*`

| Metric | Count |
|--------|------:|
| Unique `u_*` **definitions** (`^u_NAME(`) | **279** |
| Files containing at least one `u_*` def | **39** |
| Unique `u_*` **names referenced** in sh/md/mk/yml | **~295** |
| Reference hit lines in `*.sh` | **~1937** |
| Reference hit lines in `*.md` | **~45** |
| `*.sh` files with any `u_*` token | **~272** |
| Already-defined `f_*` functions | **0** |
| Total `*.sh` in repo | **~558** |

Definition concentration (top dirs by files with defs):

- `asc/utilities/` — 9 files (primary library)
- `asc/thread/`, `asc/test/`, `asc/loop/`, core `*.inc.sh`
- Extensions: `db`, `crontab`, `remote*`, `compose`, `software`, `file_registry`, `agent`, …
- Contrib: `drupalwt`, `moodle_d4php`, `apache`, `remote_traefik`, …

No `u_*` names with hyphens found in practice (regex still allows `\-` for safety).

**Exception inventory:** `u_hook_most_specific` alone accounts for ~105 of the shell/md refs; it maps to `hookms`, not `f_hook_most_specific`.

### Exports → `e_*`

| Metric | Count |
|--------|------:|
| Lines matching `^export NAME=` | **~72** |
| Indented `export NAME=` also present | **~36** additional style variants (same files / related) |
| Files with literal `export NAME=` | **6** primary: `asc/thread/thread.wrap.sh`, `asc/loop/loop.wrap.sh`, `asc/extensions/agent/agent/wrap.sh`, `asc/extensions/crontab/crontab.inc.sh`, `asc/instance/logged_thread.sh`, `asc/log/storage.hook.sh` (+ test helpers) |
| Unique exported names (literal) | **~48** (mostly `ASC_THREAD_*`, `ASC_WRAP_*`, `ASC_CRON_*`, `ASC_LOOP_*`, plus `LOGGED_THREAD_ENTRY`, `GIT_TERMINAL_PROMPT`, …) |
| Already `export e_*` | **0** |
| Consumer refs (sample families) | e.g. `ASC_EXTENSIONS` ~41 hits; wrap/thread/cron symbols thinner but cross-file |

**Important:** many ASC “exports” are **not** written as `export FOO=` in sources:

- Instance globals use `global NAME …` in `asc/env/global.vars.sh` and extension `global.vars.sh`, then `u_global_*` writes `data/asc/global.vars.sh`.
- Primitives use dynamic exports in `asc/utilities/asc.sh` (`export "${p_namespace}_SUBJECTS"`, `export ASC_EXTENSIONS` without `=`).

Those need an explicit decision (see open questions) and are **not** covered by the user’s simple `export NAME=` regex alone.

### CLI options → `o_*`

| Metric | Count |
|--------|------:|
| Unique `p_*` names repo-wide | **~215** |
| Already `o_*` | **0** |
| `while [[ $# -gt 0 ]]` / `while [ "$#" -gt 0 ]` parsers | **~6** files (only **~4** are true CLI option parsers) |
| Unique `p_*` assigned in **`-flag)` / `--long)` arms** | **~21** |
| Approx. ref lines for those 21 symbols (sh+md) | **~150** (small vs `p_*` universe) |

**True option parsers (in scope for `o_`):**

| File | Function / script | Option-driven `p_*` → `o_*` |
|------|-------------------|------------------------------|
| `asc/instance/instance.inc.sh` | `u_instance_init` | `p_ascii_{project_docroot,stack_version,apps,host_type,instance_type,provision_using,yes,dry_run}` (8) |
| `asc/utilities/hook.sh` | `u_hook_most_specific` → **`hookms`** | `p_{actions,subjects,prefixes,variants,extensions,custom}_filter`, `p_debug`, `p_dry_run`, `p_root_lookup`, `p_cache_warmup` (10) |
| `asc/extensions/transcription/instance/transcribe.sh` | entry | `p_input_dir`, `p_output_lang`, `p_skip_vscodium` (3) |
| `asc/extensions/transcription/transcribe/all.sh` | batch | same 3 |

**Positional / non-option in the same loops (do NOT → `o_`):**

| Symbol | Why stay positional-class (target `a_*`; tip name may still be `p_*`) |
|--------|--------------------------------------------------|
| `p_targets` (transcription) | Filled in the `*)` branch as unnamed args: `p_targets+="${p_targets:+ }$1"` |
| `*)` arms that only `shift` / error (instance init, hook) | No option storage |

**Lookalike loops that are NOT CLI option→`o_` migrations:**

| File | Why skip for `o_` |
|------|-------------------|
| `asc/instance/hook.make.sh` | `-d)` sets `debug_mode` (unprefixed), not `p_*` |
| `asc/make/make.inc.sh` | `while` matches make entry-point names, not `-o)`-style flags |

**No `getopts` usage** found in this repo; parsers are hand-rolled `while`/`case`.

**Intersection with `e_*`:** transcription does `export p_input_dir p_output_lang p_skip_vscodium p_targets …`. After `o_` rename, option symbols become `o_*` and may later also need `e_` if the export rule applies to them — see open questions (`export e_o_input_dir` vs export `o_*` without double prefix).

### Convention comments / docs (must update traces)

File-header convention lines and **README / living-doc** mentions of old symbols must be updated when symbols migrate — identifier rename in code alone leaves stale doc traces.

| Pattern | Approx. count | Notes |
|---------|--------------:|-------|
| `# Convention : functions names are all prefixed by "u" (for "utility").` (and close variants) | **26 files** | Near-identical boilerplate on `*.inc.sh` / utilities / contrib / **builder template** |
| Markdown with `\bu_*\b` (excl. this changelog) | **~15 files**, **~71** hit lines | READMEs + `docs/asc/**` (+ sparse ideas) — see list below |
| Idea stubs mentioning `u_*`→`f_*`, `a_`/`p_`/`o_`/`c_`/`e_` | **2+** | Same mechanical rule; no editorial rewrite |
| Explicit `p_*` / export convention comments in shell | **Sparse** | Transcription “same `p_*` contract” — replace option symbols with `o_*` only where those symbols rename |

#### READMEs + living docs with `u_*` traces (inventory)

| Path | ~`u_*` hits | Notable symbols |
|------|------------:|-----------------|
| `docs/asc/organization.md` | 7 | `u_global_*`, `u_hook_most_specific`, planned `u_*`/`c_foobar` naming bullet |
| `docs/asc/archive/hooks.md` | 6 | `u_hook_most_specific`, `u_str_subsequences`, … |
| `docs/asc/archive/globals.md` | 6 | `u_global_*`, `u_db_set`, … |
| `README.md` | 4 | `u_instance_init`, `u_hook_most_specific`, `u_host_os`, … |
| `docs/asc/testing.md` | 4 | `u_test_batch_exec`, … |
| `docs/asc/archive/bootstrap.md` | 3 | `u_asc_extend`, `u_autoload_override`, … |
| `docs/asc/archive/actions-and-make.md` | 3 | make/`u_*` examples |
| `docs/asc/archive/secrets.md` | 2 | registry helpers |
| `docs/asc/archive/nested-asc.md` | 2 | nested helpers |
| `asc/extensions/README.md` | 2 | `u_hook_opt_inc_append_candidates`, `u_hook_most_specific` |
| `data/asc/README.md` | 1 | `u_instance_init` |
| `docs/asc/builder.md`, `docs/asc/archive/{builder,layers}.md` | 1 each | sparse |
| `data/ideas/2026/07/18/extensions.md` | 2 | idea notes |

Also in living-doc scope for **convention-statement** traces (even if few/no `u_*` tokens): any README/`docs/asc/**` line that still *prescribes* old prefixes (`u` utility, `c_foobar` exports, option `p_ascii_*` if documented). No `p_ascii_*` hits found in md today; still apply the rule if added later.

**Out of doc-edit scope:** `asc/vendor/**`; empty `data/plans/**` READMEs; this changelog may keep historical quotes of old names.

**Canonical shell-header rewrite (user example)** — applies to the 26 `# Convention :` lines (code comments), not a license to rewrite README paragraphs:

Old:

```text
# Convention : functions names are all prefixed by "u" (for "utility").
```

New:

```text
# Convention : functions names must all be prefixed by "f_" and use snake_case.
```

**Recommended expanded file-header block** (once `e_` / `o_` are also enforced — can land in the same Phase 4 pass or immediately after symbol renames):

```text
# Convention :
# - functions : prefix "f_", snake_case (e.g. f_fs_relative_path); exception: hookms (was u_hook_most_specific)
# - exported vars : prefix "e_" (e.g. e_ASC_THREAD_ENTRY)  # if Phase 3 done
# - CLI option / flag vars : prefix "o_" (from -flag) case arms)
# - positional / function args : prefix "a" / "a_" (tip may still show legacy p_*)
```

Tune the export line to match Phase 0 decisions (stem shape / stacking).

**Files with the current `u`-utility Convention line (26):**

- Utilities: `asc/utilities/{array,autoload,fs,global,hook,string,yaml}.sh` (note: `shell.sh` / `asc.sh` lack this header today)
- Core: `asc/{git,host,instance,make,test,thread}/*.inc.sh` (incl. `asc/test/asc.inc.sh`)
- Extensions: `compose` (+ instance), `crontab`, `file_registry`, `remote_db`, `remote_asc/db`, `software/host/provision.opt-inc.sh`
- Template: `asc/extensions/builder/templates/asc/subject.inc.tpl.sh` (**critical** — new subjects inherit the comment)
- Contrib: `apache`, `drupalwt`, `moodle_d4php`, `remote_traefik`

**Out of scope for this comment pass** (same word “convention”, different meaning): hook `pre`/`post` prefixes; `*_C` container path suffix; `$DB_ID`-prefixed DB vars; docker-compose network naming; `asc/bootstrap.sh` “Phase convention”.

---

## Phased migration

### Phase 0 — Decisions + freeze inventory

1. Resolve **open questions** (below), especially: `e_ASC_*` vs rename stem; third-party exports; whether `global()` / `ASC_*` primitives get `e_`; **`o_*` + `e_*` double-prefix** for exported option vars; whether YAML-seeded `p_ascii_*` (same symbols as CLI options) always become `o_*`.
2. Re-run inventory scripts; freeze:
   - 279 `u_*` function names (**carve-out:** `u_hook_most_specific` → `hookms`, not `f_*`)
   - export allow/deny lists
   - **option-symbol allowlist** (~21 names above; re-verify)
3. Ensure clean git state / dedicated branch (e.g. continue `naming-conventions-changes`).

**Do not skip Phase 0** if export renaming would break wrap/cron/thread contracts.

### Phase 1 — Functions: `u_*` → `f_*` (mechanical, high volume)

**Step 0 (hardcoded exception):** rename `u_hook_most_specific` → **`hookms`** everywhere (~105 refs; def in `asc/utilities/hook.sh`) **before** or **excluded from** the blanket `u_*`→`f_*` pass. Never emit `f_hook_most_specific`.

Order matters for the rest: rename **definitions and all call sites together** per symbol (or whole-tree token replace with verification).

Suggested sub-order:

1. **`hookms` exception** (above).
2. **Core utilities** (`asc/utilities/*.sh`) — loaded first in bootstrap phase 20.
3. **Bootstrap phases** that call utilities (`asc/bootstrap/*.bootstrap-inc.sh`).
4. **Core includes / subjects** (`asc/{git,host,instance,make,test,thread,…}/**`).
5. **Extensions** (`asc/extensions/**`).
6. **Contrib** (`scripts/asc/contrib/**`).
7. **Docs** (`docs/asc/**`, `README.md`, idea stubs that document APIs) — API examples that name `u_*` functions.
8. **Do not treat Phase 1 as done** until Phase 4 has rewritten the 26 `Convention : … "u"` file headers (or fold that rewrite into the Phase 1 commit — see Phase 4).

Concrete approach:

- Prefer a **symbol table** of the 279 defs **minus** `u_hook_most_specific` (mapped to `hookms` instead), then replace `\bu_NAME\b` → `f_NAME` across `*.sh` / `*.md` / `*.mk` (and any `*.yml` that embed function names).
- Avoid naive `s/u_/f_/` (would corrupt words, URLs, unrelated tokens; and would wrongly produce `f_hook_most_specific` if the exception was not applied first).
- Preserve `u_` only inside historical changelog prose *if* quoting old names; prefer updating living docs.
- File-header convention comments are **not** fixed by symbol replace alone — they still say `"u"` after `u_foo`→`f_foo`.

### Phase 2 — CLI options: selected `p_*` → `o_*` (small, high precision)

**Recommended after Phase 1** (function renames are orthogonal but touch the same files: `hook.sh`, `instance.inc.sh`). Can run before Phase 3 exports so transcription `export` lines are rewritten once with final names.

Steps:

1. Build allowlist from option arms only (scripted extraction preferred — see safe conversion).
2. For each allowlisted symbol: rename **all** uses in that function/script (and hooks/docs that consume the exported option contract), including:
   - `local p_…` / bare init
   - YAML-seed assignments (`p_ascii_*="$YAML_…"`)
   - `case` arms
   - later conditionals / comments
3. Leave `p_targets` and every non-allowlisted `p_*` untouched.
4. Update comments that say “same `p_*` contract” (transcription) to `o_*` / tip `p_targets` (→ `a_targets`) as appropriate.

### Phase 3 — Exports: `export NAME=` → `export e_NAME=` (+ consumers)

1. Enumerate unique exported names from literal exports (and decided dynamic set).
2. For each ASC-owned name:
   - Rewrite export sites (including indented exports).
   - Rewrite `$NAME`, `${NAME}`, `${NAME:-…}`, assignments `NAME=`, `[[ -n "$NAME" ]]`, etc.
3. Special-case:
   - `export ASC_EXTENSIONS` (no `=`) → `export e_ASC_EXTENSIONS` or chosen name.
   - `export "${p_namespace}_SUBJECTS"` → either keep pattern with `e_` baked into namespace policy, or export `e_${p_namespace}_SUBJECTS` — **decision required**.
   - Transcription `export o_input_dir …` (after Phase 2) — apply `e_` policy decided in Phase 0.
4. Regenerate instance state: `make cc` and/or `make reinit` so caches and `.env` match.

### Phase 4 — Convention comments, READMEs, living docs, and templates

**Purpose:** clear renaming-related traces so docs/comments match `f_` / `e_` / `o_` / `a_` / `hookms` after symbol migration. **Required**, not optional polish.

#### Hard rule — no prose rephrase (READMEs + living docs)

- **Do not rephrase** existing README / living-doc narrative, structure, or tone.
- **Only** fix **renaming-related traces**:
  - identifier tokens (`u_foo` → `f_foo`, `u_hook_most_specific` → `hookms`, renamed exports → `e_*`, option `p_ascii_*` → `o_ascii_*`, etc.)
  - **convention statements** that still prescribe the old prefix scheme (e.g. “prefixed by `u`”, “maybe `f_*` instead of `u_*`”, `c_foobar` where this plan adopts `e_*`)
- Mechanical identifier / convention-statement updates only — **no** editorial rewrite of surrounding sentences, no new “Naming” essays, no “promote planned→enforced” copy edits beyond swapping the stale naming tokens/statements themselves.
- Shell `# Convention :` boilerplate (26 files) **may** use the user’s fixed replacement sentence (that *is* the convention-statement update). Do not use that as a model to rewrite README paragraphs.

#### Checklist

- [ ] Replace all **26** shell `# Convention : … prefixed by "u"` headers with the new `f_` + snake_case convention statement (user example above).
- [ ] Update **builder template** `asc/extensions/builder/templates/asc/subject.inc.tpl.sh` the same way.
- [ ] Optionally expand those **shell** headers to mention `e_` / `o_` / `a_` once those migrations are in (code comments only).
- [ ] In shell transcription comments: replace renamed option symbols (`p_input_dir` → `o_input_dir`, etc.); leave positional tip `p_targets` (target `a_targets`); do not rewrite unrelated comment prose.
- [ ] **READMEs + living docs** (paths in inventory above): mechanical `\b` symbol replace + convention-statement token fixes only — including root `README.md`, `docs/asc/**`, `asc/extensions/README.md`, `data/asc/README.md`.
- [ ] `docs/asc/organization.md` naming bullet: replace stale prefix names (`u_*`→`f_*`, `c_foobar`→`e_…` per Phase 0) **in place**; do not rewrite the rest of the section.
- [ ] Idea stubs: same mechanical rule if they name old symbols; do not expand into new essays.
- [ ] Grep gates (below): no leftover old function/export/option names in md/README (except this changelog’s historical quotes).

#### Convention-statement wording (shell headers + doc *statements* only)

| Topic | When fixing a convention statement, prefer |
|-------|--------|
| Functions | `must` + `` `f_` `` + `snake_case` (shell header user example) |
| Exports | `` `e_` `` (after Phase 3; decided stem) |
| Options | `` `o_` `` for `-flag)`-driven vars |
| Positionals | `` `a` `` / `` `a_*` `` (from legacy tip `p_*`) |
| Most-specific hook | `` `hookms` `` (never `f_hook_most_specific`) |

**False positives:** do not touch unrelated “convention” comments (DB_ID prefixes, `*_C`, hook pre/post, compose networks). Do not “improve” documentation while passing through.

**Ordering:** symbol renames in md can ride with Phases 1–3 (same `\b` pass). Shell header Convention lines + any remaining convention-statement fixes in the same PR. Prefer **not** leaving merged docs that still name `u_*` / `u_hook_most_specific`.

### Phase 5 — Verification + commit(s)

See verification and commit strategy below.

---

## Safe conversion strategy

### Functions

**Hardcoded first:** `\bu_hook_most_specific\b` → `hookms` (def + all call sites + comments/docs). Confirm no `f_hook_most_specific` is introduced.

**Preferred for all other utilities:** whole-word replace per known symbol:

```text
\bu_<NAME>\b  →  f_<NAME>
```

where `<NAME>` comes from the definition inventory (**278** remaining after carving out `u_hook_most_specific`), not from open-ended search alone.

**Caveats / false positives:**

| Risk | Mitigation |
|------|------------|
| **`u_hook_most_specific` → wrong `f_hook_most_specific`** | Exclude from `f_*` table; rename to `hookms`; grep-gate both old names |
| Partial prefix (`u_host_crontab_` incomplete docs) | Fix docs to real symbols; don’t invent |
| Strings / messages mentioning old names | Update if user-facing or assertions; leave only in dated changelogs if historical |
| `u_` inside longer identifiers | Word-boundary `\b` required |
| Cached hook/primitives files under `data/asc/cache/` | Delete/regenerate; never “fix” generated cache as source of truth |
| Tests comparing expected path lists / function names | Run `make test-core` (or scoped tests) after rename |

**Unsafe:** blanket `sed 's/u_/f_/g'` on entire files.

### CLI options (`o_*`)

**Preferred:** allowlist extracted from option arms, then whole-word rename per symbol.

Suggested extraction (illustrative — refine before use):

```bash
# Collect p_* assigned on lines that look like option case arms (not *))
grep -RhoE '^[[:space:]]+-([A-Za-z0-9]|-)+(\|[A-Za-z0-9_-]+)*\)[[:space:]]*[^;]*\bp_[A-Za-z0-9_]+\b' \
  --include='*.sh' asc scripts \
  | grep -oE 'p_[A-Za-z0-9_]+' | sort -u
```

Then for each allowlisted `p_NAME` → `\bp_NAME\b` → `o_NAME` **within the owning function/file first**, then any exported consumers (transcription hooks).

**Do not:**

| Unsafe approach | Why |
|-----------------|-----|
| `s/p_/o_/g` anywhere | Destroys ~215 positional params |
| Rename every `p_*` that appears inside a `while`/`case` file | `*)` positional vars (`p_targets`) and unrelated helpers would flip |
| Treat `hook.make.sh` `-d)` as `o_` without a `p_*`/`o_*` storage var | Uses `debug_mode` today; out of this rule unless later standardized |
| Assume `p_debug` / `p_dry_run` are global names | Today confined to `u_hook_most_specific` (→ `hookms`); still rename only allowlisted symbols |

**False-positive / edge notes:**

| Edge | Guidance |
|------|----------|
| Same symbol seeded from YAML **and** CLI (`p_ascii_*`) | Still option-class storage → **`o_ascii_*`** (both paths write the same knobs) |
| tip `p_targets` in `*)` | Keep positional-class (**not** `o_*`); target name **`a_targets`** |
| `export p_input_dir …` | Rename to `o_*` in Phase 2; decide `e_` stacking in Phase 3 |
| Docs saying “`p_*` contract” for transcribe | In shell comments: replace renamed option ids only; keep positional tip `p_targets` (→ `a_targets`) |

### Exports

**Preferred:** name-list driven replace, not single-regex over the repo.

User regex `export ([A-Za-z0-9\-_]+)=` → `export e_$1=`:

| Caveat | Detail |
|--------|--------|
| Indented exports | Also match `^[[:space:]]*export NAME=` |
| `export NAME` without `=` | Must handle separately |
| `export "${dyn}"` / `export "$var"` | Manual |
| Comments containing the word `export` | Do not use multiline-blind replace on `export` alone |
| Strings in cron templates / heredocs | `crontab.inc.sh` embeds `export ASC_CRON_*=…` inside generated fragments — rewrite both generator and any expected output |
| Third-party `GIT_TERMINAL_PROMPT` | Prefixed `e_GIT_TERMINAL_PROMPT` may **not** be honored by git; likely **exclude** |
| Collision with make `e:` tokens in docs | Different namespace; keep docs clear |
| `export o_foo` after Phase 2 | Decide: leave as `o_*` export, or `e_o_foo`, or re-export under a dedicated `e_*` name |

**After export rename:** every consumer must move in the same commit (or atomic series) or wraps break at runtime.

### Convention comments / docs

**Preferred:** mechanical replace of the known 26-line shell boilerplate; for READMEs/living docs, **same `\b` symbol table** as code (plus `hookms` exception) — **no editorial rewrite**.

```text
# Convention : functions names are all prefixed by "u" (for "utility").
→
# Convention : functions names must all be prefixed by "f_" and use snake_case.
```

Also match the shorter variant: `function names are prefixed by "u".`

| Caveat | Detail |
|--------|--------|
| Builder template | Must update or new subjects keep old wording |
| READMEs / `docs/asc/**` | Identifier + convention-statement traces only; **do not rephrase** surrounding prose |
| Unrelated “convention” | Skip DB_ID / `*_C` / hook pre-post / compose networks |
| This changelog | May quote old text historically — fine; living code/docs must not |
| Soft vs must | Prefer **must** + `` `f_` `` + snake_case **only** when replacing the shell Convention boilerplate (user example) |

### Nested repos / wrong work tree

- This ASC tree has **no** nested `.git` directories.
- Do not run renames from `$HOME` against CWT or other projects.
- Stay in `/home/paul/Documents/asc` for implementation.

---

## Verification approach

### Static (must pass before merge)

```bash
# No remaining utility defs with old prefix
grep -RhnE '^u_[A-Za-z0-9_\-]+[[:space:]]*\(' --include='*.sh' asc scripts
# expect empty

# No remaining u_* calls in shell (allowlist historical changelog if any)
grep -RhnE '\bu_[A-Za-z0-9_\-]+\b' --include='*.sh' asc scripts
# expect empty (or documented exceptions)

# hookms exception: no stale old or wrong f_ name
grep -RhnE '\bu_hook_most_specific\b|\bf_hook_most_specific\b' --include='*.sh' --include='*.md' asc scripts docs README.md
# expect empty (changelog may quote historically)
grep -RhnE '\bhookms\b' --include='*.sh' asc/utilities/hook.sh | head

# f_* defs exist
grep -RhnE '^f_[A-Za-z0-9_\-]+[[:space:]]*\(' --include='*.sh' asc/utilities | head

# Literal exports without e_ (after policy applied)
grep -RhnE '^[[:space:]]*export[[:space:]]+(?!e_)[A-Za-z_][A-Za-z0-9_\-]*=' --include='*.sh' asc
# or simpler inventory diff against allowlist (GIT_TERMINAL_PROMPT, etc.)

# Option arms should not still assign p_* (allowlist emptied)
grep -RhnE '^[[:space:]]+-[^)]*\)[[:space:]]*[^;]*\bp_[A-Za-z0-9_]+\b' --include='*.sh' asc scripts
# expect empty (or only documented exceptions)

# Positional transcription target still positional-class (tip p_targets; target a_targets — not o_)
grep -RhnE '\bp_targets\b' --include='*.sh' asc/extensions/transcription

# Blind p_ wipe must NOT have happened — many p_* remain
test "$(grep -RhoE '\bp_[A-Za-z0-9_]+\b' --include='*.sh' asc | sort -u | wc -l)" -gt 100

# Stale function-convention headers (must be empty after Phase 4)
grep -RniE 'Convention[[:space:]]*:[[:space:]]*functions? names? .*prefixed by ["'\'']u' --include='*.sh' asc scripts
# expect empty

# Stale "for utility" function-prefix wording
grep -RniE 'prefixed by ["'\'']u["'\''].*utility|for ["'\'']utility["'\'']' --include='*.sh' asc scripts
# expect empty (or only unrelated hits — review)
```

Also grep docs for stale `u_` API examples and option examples still showing `p_ascii_*` / hook filter `p_*` in `docs/asc/**` and READMEs. Confirm `docs/asc/organization.md` naming bullet no longer cites `u_*` / `c_foobar` as the live prescription (token fix only).

```bash
# Markdown / README leftover old function names (expect empty except this changelog)
grep -RhnE '\bu_[A-Za-z0-9_]+\b' --include='*.md' README.md docs asc/extensions/README.md data/asc/README.md
grep -RhnE '\bu_hook_most_specific\b|\bf_hook_most_specific\b' --include='*.md' README.md docs
# expect empty
```

### Runtime / smoke

1. `make cc` (clear caches).
2. `make reinit` or `make init-debug` in a disposable env if needed — exercise `-y` / `-r` / `-o` style args to `u_instance_init` / make init paths.
3. `make test-core` (core automated tests); especially hook dry-run / filter paths (`-t`, `-d`, `-a`, …).
4. Smoke wraps if enabled: thread wrap, loop wrap, cron sync dry paths — ensure `e_*` env visible to children.
5. Spot-check: `. asc/bootstrap.sh` then `type hookms` / `declare -F | grep -E '^(f_|hookms)'`.
6. Spot-check option locals: after bootstrap, call hook helper with `-t` / filters; confirm behavior unchanged.

### Rollback

- Prefer **git revert** of the rename commit(s) on the feature branch.
- If only half-applied, revert to pre-phase tag/branch tip; do not hand-fix 1900+ call sites.
- Generated `data/asc/*`: delete and regenerate after rollback.
- `o_*` phase is small (~21 symbols) — can revert that commit alone if needed.

---

## Risks

| Risk | Severity | Notes |
|------|----------|-------|
| Accidental `f_hook_most_specific` | High | Exception must be `hookms`; grep-gate both names |
| Missed call site → runtime “command not found” | High | Mitigate with full-tree `\b` replace + tests |
| Export rename without consumers → empty wrap metadata | High | Same-commit rename of readers/writers |
| **Blind `p_*`→`o_*`** | **Critical** | Would break ~215 positional params; allowlist-only |
| Missing rename of YAML-seed path for `p_ascii_*` | Medium | Same symbols must flip everywhere in `u_instance_init` |
| Renaming tip `p_targets` into `o_*` by mistake | Medium | Explicit deny for option pass; positional rename is `a_targets` |
| Breaking external projects that copy older ASC and call `u_*` | Medium | Semver / changelog callout; this is a breaking API change |
| Prefixed `GIT_TERMINAL_PROMPT` ignored by git | Medium | Exclude from `e_` |
| Confusing `e_*` vars with make `e:` entry tokens | Low | Document clearly |
| Idea docs still say `c_*` for exports | Low | Doc reconciliation |
| Cache serving old strings | Medium | Always `make cc` / reinit after |
| Double prefix `e_o_*` awkwardness | Low/Med | Decide in Phase 0 |
| Stale `# Convention : … "u"` headers after rename | Medium | Readers/agents follow comments; Phase 4 + grep gate |
| Rewriting unrelated “convention” comments | Low | Allowlist the 26 utility headers + known docs |

---

## Suggested commit strategy

Breaking rename — keep history bisectable:

1. `docs(changelog): plan f_/e_/o_ naming convention` — **this file** (optional if committing plan first).
2. `refactor!: rename u_* utilities to f_*` (with `u_hook_most_specific`→`hookms`) — functions + docs API references; **include the 26 header Convention rewrites** (or immediate follow-up commit in the same PR).
3. `refactor!: rename CLI option storage p_* to o_*` — allowlisted option symbols only (~4 files + consumers/docs/comments).
4. `refactor!: prefix exported runtime vars with e_` — exports + consumers (after Phase 0 decisions).
5. `docs: mechanical f_/e_/o_/hookms renames in READMEs + living docs + Convention headers` — **no prose rephrase**; fold into 2–4 if preferred.
6. Avoid mixing unrelated refactors.

Do **not** push `--force` to `main`. Feature branch + PR when implementing.

---

## Safety notes

- Plan only until explicitly approved for implementation.
- Do not edit gitignored generated files; regenerate.
- Do not “fix” upstream CWT from this repo.
- Keep third-party env contracts (`GIT_*`, etc.) on an allowlist.
- **Never** bulk-rename `p_*`; option migration is allowlist-driven from `-flag)` arms.
- **Always** clear renaming traces in headers/READMEs/living docs in the same PR as the renames they describe (Phase 4) — **without** rephrasing surrounding prose.
- Large mechanical diff (`f_*`): review with `git diff --stat` and sample symbol greps, not only CI green.

---

## Open questions / decisions needed

1. **Export stem shape:** `export ASC_THREAD_ENTRY=` → `export e_ASC_THREAD_ENTRY=` (prefix only) or also downcase/restyle (`e_thread_entry`)? User regex implies **prefix-only**.
2. **`global()` / readonly instance globals** (`PROJECT_DOCROOT`, `STACK_VERSION`, …): in or out of `e_*`? Current regex does not cover them; organization.md still wants unprefixed `FOOBAR` for readonly — **recommend out of scope** for this migration.
3. **Dynamic primitive exports** (`${p_namespace}_SUBJECTS`, `ASC_EXTENSIONS`): adopt `e_` now or defer to a follow-up?
4. **`GIT_TERMINAL_PROMPT`:** exclude from `e_` (recommended)?
5. **Reconcile `c_*` vs `e_*`:** update idea/docs to `e_*` as SoT for exports?
6. **Downstream consumers:** any external repos still on CWT/`u_*` that must stay compatible for a deprecation window (compat aliases `u_foo() { f_foo "$@"; }`)? Default recommendation: **no aliases** (cleaner break) unless user requires a transition release.
7. **Contrib extensions:** rename in same breaking commits (recommended: yes, in-tree)?
8. **`o_*` + `e_*` stacking** (transcription exports options for hooks): `export o_input_dir`, or `export e_o_input_dir`, or rename export surface to a dedicated `e_transcribe_*`? **Needs explicit choice.**
9. **YAML-seeded option knobs:** confirm `p_ascii_*` become `o_ascii_*` even when first set from YAML rather than CLI (recommended: **yes** — same storage class).
10. **Future parsers:** should new code use `o_*` only, and should `hook.make.sh` `debug_mode` eventually become `o_debug` for consistency?

---

## Open tasks (when implementing)

- [ ] Confirm Phase 0 decisions (exports + globals + third-party allowlist + `o_`/`e_` stacking)
- [ ] Freeze symbol lists (279 functions with **`u_hook_most_specific`→`hookms` exception**; export allow/deny; **~21 option symbols** + deny option-rename of `p_targets`)
- [ ] Implement Phase 1 (`u_*` → `f_*`, **`hookms` first**)
- [ ] Implement Phase 2 (`p_*` option storage → `o_*`, allowlist only)
- [ ] Implement Phase 3 (`e_*` exports + consumers)
- [ ] **Phase 4:** 26 `Convention : … "u"` headers (+ builder template); **mechanical** README/`docs/asc/**` symbol + convention-statement fixes (**no rephrase**); transcription option-symbol comments
- [ ] `make cc` / reinit + `make test-core` + wrap / init-option / hook-filter smoke
- [ ] Grep gates clean (symbols + **no stale `prefixed by "u"` headers** + **no `u_*` / `u_hook_most_specific` in README/`docs/asc`** + “many tip `p_*` remain until positional→`a_*`”); open PR with breaking-change notes

---

## Amendment (2026-07-27) — README / DSL token alignment

Root README + living docs lock **positional** shell / tip rename target as **`a` / `a_*`** (not tip `p_*`). This plan already said that; Cursor `.cursor/rules/naming.mdc` was still saying `p_` and was corrected the same day.

**Do not conflate** this plan’s shell prefixes with the **filename-DSL redesign** still under review:

| Surface | Positional | Option | Boolean |
|---------|------------|--------|---------|
| This plan (shell symbols) | `a` / `a_*` (from tip `p_*`) | `o_*` | `b_*` |
| Filename-DSL plan (locked) | freeform in `[]` → `a` / `a_*` | `o-*` → `o_` | `b-*` → `b_` |
| README proposed DSL redesign | `a` / `a-1` / `a-1s` tokens | `o-*` | `bo-*` / `bo_` |

Boolean `bo_*` is **not** part of this naming migration until/unless the README redesign is accepted in `24-filename-dsl.md`. Keep Phase 2 boolean storage as `b_*` unless that accept lands first.
---

## Appendix A — Export files to touch first

Literal `export NAME=` concentrated in:

- `asc/thread/thread.wrap.sh`
- `asc/loop/loop.wrap.sh`
- `asc/extensions/agent/agent/wrap.sh`
- `asc/extensions/crontab/crontab.inc.sh` (includes generated crontab body strings)
- `asc/instance/logged_thread.sh`
- `asc/log/storage.hook.sh`
- `asc/test/test.inc.sh` / related test helpers (`ASC_TEST_RESULTS*`)
- `asc/utilities/asc.sh` (dynamic / name-only exports — policy-dependent)
- `asc/extensions/transcription/**` (exports option + positional tip `p_*` / later `o_*` + `a_*` — Phase 2/3)

## Appendix B — Option-parser files (for `o_*`)

| File | Notes |
|------|--------|
| `asc/instance/instance.inc.sh` | `u_instance_init` — primary user example |
| `asc/utilities/hook.sh` | `u_hook_most_specific` → **`hookms`** — largest option set; uses `while [ "$#" -gt 0 ]` |
| `asc/extensions/transcription/instance/transcribe.sh` | options + positional tip `p_targets` (→ `a_targets`) |
| `asc/extensions/transcription/transcribe/all.sh` | same contract |

## Appendix C — Prior art in-repo

- Idea: `data/ideas/2026/07/18/organization-(globals,subjects,actions,hooks,variants,bootstrap).md` — proposes FOOBAR / positional / o_ / c_ and questions `u_*`→`f_*` (positional prefix SoT is now **`a` / `a_*`**).
- Living doc: `docs/asc/organization.md` — “Planned naming convention (ideas, not enforced)” including maybe `f_*` and `o_foobar` options.
- DSL idea (2026-07-23): mentions `e_foobar` / `f_foobar` alongside positional/option prefixes — align idea `p_` wording to **`a` / `a_*`** when touched; consistent with this plan’s `e_`/`f_`/`o_`/`a_` choice.
- Repeated shell boilerplate: 26× `# Convention : functions names are all prefixed by "u" (for "utility").` — Phase 4 target.
- `data/plans/{accepted,iterate,review,rejected}/` — empty placeholders; **changelogs** are the dated decision record (this file).

## Appendix D — Inventory commands (re-run at implement time)

```bash
cd /home/paul/Documents/asc

echo "u_ defs: $(grep -RhnE '^u_[A-Za-z0-9_\-]+[[:space:]]*\(' --include='*.sh' | wc -l)"
echo "u_ sh refs: $(grep -RhnE '\bu_[A-Za-z0-9_\-]+\b' --include='*.sh' | wc -l)"
echo "export NAME=: $(grep -RhnE '^[[:space:]]*export[[:space:]]+[A-Za-z_][A-Za-z0-9_\-]*=' --include='*.sh' | wc -l)"
echo "bootstrap callers: $(grep -Rl '\. asc/bootstrap\.sh' --include='*.sh' | wc -l)"
echo "p_ unique: $(grep -RhoE '\bp_[A-Za-z0-9_]+\b' --include='*.sh' | sort -u | wc -l)"
echo "o_ unique: $(grep -RhoE '\bo_[A-Za-z0-9_]+\b' --include='*.sh' | sort -u | wc -l)"
echo "option-arm p_ assigns:"
grep -RhnE '^[[:space:]]+-[^)]*\)[[:space:]]*[^;]*\bp_[A-Za-z0-9_]+\b' --include='*.sh' asc scripts
echo "stale u-utility Convention headers:"
grep -RniE 'Convention[[:space:]]*:[[:space:]]*functions? names? .*prefixed by ["'\'']u' --include='*.sh' asc scripts
echo "md u_ leftover (excl. this plan file):"
grep -RhnE '\bu_[A-Za-z0-9_]+\b' --include='*.md' README.md docs asc/extensions/README.md data/asc/README.md 2>/dev/null | wc -l
```
