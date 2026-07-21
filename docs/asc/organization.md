# ASC core concept : Organization

Table of contents :

1. globals
1. hosts
1. instances
1. humans vs agents (ownership ?)
1. subjects
1. actions
1. hooks
1. variants
1. bootstrap : inc, opt-inc
1. make shortcuts
1. (re)init : cache, state

Organization is how ASC finds code, loads environment, and turns folders into callable entry points. Prefer the lowest implementation layer that can own a behavior (data → globals → abstract entry points → extensions → project extend).

---

## globals

**Layer 2:** env-facing values that are either **readonly globals** or **calling-scope mutables**.

| Concern | Detail |
|---------|--------|
| Declare | `global NAME "…"` in `global.vars.sh`, or YAML in `env.yml` / `.env-local.yml` |
| Aggregate | `u_global_aggregate` — core → enabled extensions → project YAML → extend |
| Write | `.env` (Make/tools) + `data/asc/global.vars.sh` (sourced every bootstrap phase 30) |
| List paths | `make globals-lp` |
| Skip load | `ASC_BS_SKIP_GLOBALS=1` |

Selected core defaults (see `asc/env/global.vars.sh`): `PROJECT_DOCROOT`, `STACK_VERSION`, `INSTANCE_TYPE`, `PROVISION_USING`, `HOST_TYPE`, `HOST_OS`, `ASC_APPS`, `ASC_MAKE_INC`, `ASC_SYNONYMS`, …

Mutables (`DB_*`, `REMOTE_INSTANCE_*`, …) are **not** written by `u_global_write`; hooks/loaders set them mid-run. Token expansion uses `u_str_convert_tokens` (bounded recursion).

Secrets stance: prefer gitignored `.env-local.yml` and registry paths; see also `docs/asc/archive/secrets.md` until a dedicated secrets section is split out.

**Planned naming convention (ideas, not enforced):** `FOOBAR` readonly; `foobar` local; `p_foobar` args; `o_foobar` options; `c_foobar` mutable exports; maybe `f_*` instead of `u_*` for functions.

---

## hosts

Host-level subject and helpers under `asc/host/`.

| Action family | Make (typical) | Notes |
|---------------|----------------|-------|
| Provision | `make host-provision` | Package / software hooks when `software` enabled |
| Registry | `make host-reg-*` | Host-level file registry (`FILE_REGISTRY_HOST_LEVEL_PATH`) |
| Vitals | `make host-vitals` | Health-ish hooks |
| Crontab primitives | (internal) | `u_host_crontab_*` reused by `crontab` extension |

Optional extensions: `hosts_file` (`/etc/hosts`), `software` (manifest-driven provision), `crontab` (calendar — see [wrappers.md](wrappers.md) § cronjob).

Host-wide thread index (when monitoring allows): `$HOME/.local/share/asc/threads/`.

---

## instances

Everything runs from **`$PROJECT_DOCROOT`**.

### Lifecycle

```sh
cp SPECIMEN.env.yml env.yml   # edit
make setup                    # init → start → stage2/post hooks
```

| Param | Global | Default (setup.sh) |
|-------|--------|--------------------|
| 1 | `INSTANCE_TYPE` | `dev` |
| 2 | `HOST_TYPE` | `local` |
| 3 | `STACK_VERSION` | empty → falls back to global default |
| 4 | `PROVISION_USING` | `compose` (core global default when undeclared is often `asc`) |

Idempotent. If globals are already `readonly` in the current shell, use a new terminal or **`make reinit`** instead of `setup` for the init step.

### Config & generated state

| Path | Role |
|------|------|
| `env.yml` | Committed instance declaration |
| `.env-local.yml` | Machine-private overrides (gitignored) |
| `.env` | Generated exports |
| `data/asc/global.vars.sh` | Generated readonly globals |
| `data/asc/generated.mk` | Generated make targets |
| `data/asc/cache/` | Hook + opt-inc + primitives caches |
| `data/asc/registry/` | Instance registry (`make reg-*`) |

Do **not** hand-edit generated files.

---

## humans vs agents (ownership ?)

There is **no** built-in authz framework — filesystem permissions are the control plane.

| Actor | Contract |
|-------|----------|
| Humans | Primary operators; sudo through wraps preserves EUID; prefer human-owned artifacts (`SUDO_USER`) |
| Agents | Observability paths and observability docs are written so agents can launch/read the same trails; **full agent stack is out of core scope** |

Core non-goals include complex NL / chain-of-thought / ontology platforms — delegate to nested apps. Thin `gpt` / `ollama` extensions may exist as opt-in abstracts; control-plane agent products stay postponed.

Thread YAML records `owner` / uid / euid for supervised jobs. Wrappers never call `sudo` themselves.

Open: richer ownership / ACL as entity predicates (`role.able`, cascading permissions) — see [entities.md](entities.md).

---

## subjects

**Folders = subjects.** Discovery walks:

1. `./asc`
1. Enabled `./asc/extensions/$extension` (and nested via `.asc_subjects_ignore`)
1. `./scripts/asc/contrib/$extension` (same nesting rules)
1. `./scripts/asc/extend` (project-specific)

Core subjects include `instance`, `host`, `git`, `log`, `loop`, `thread`, `sidecar`, `make`, `test`, `env`, `asc`. Extensions add subjects when enabled (`cron-*`, `nested-asc-*`, `blueprint-*`, `transcribe`, …).

---

## actions

**Files = actions** (`$subject/$action.sh`), with exceptions for `*.inc.sh`, ignore files, hooks, etc.

- Aggregated into `data/asc/generated.mk` on `make init` / `make reinit`.
- List: `make list-actions` (and related make list helpers).
- Hardcoded shortcuts in `asc/make/default.mk`: `init` (default goal), `init-debug`, `setup`, `hook`, `hook-debug`, `globals-lp`, `debug`.

Generic → specific scale for `u_hook_most_specific()` (bottom wins):

1. `asc/$subject/$action`
1. `asc/extensions/$extension/$subject/$action`
1. nested extension points …
1. `scripts/asc/contrib/…`
1. `scripts/asc/extend/$subject/$action` (and nested)

After adding extend scripts: clear caches and `make reinit` (see [(re)init](#reinit--cache-state)).

---

## hooks

File-based events: `hook()` / **`u_hook_most_specific()`** on `*.hook.sh` (also `-c yml`, templates, …).

| Flag | Meaning |
|------|---------|
| `-s` | subject(s) |
| `-a` | action |
| `-p` | pre/post (e.g. stage2) |
| `-v` | variant globals |
| `-e` | extension filter |
| `-t` | dry-run |
| `-r` | project root |

Default variant set often includes `INSTANCE_TYPE`. `PROVISION_USING` dual-expands **`compose`** and **`docker-compose`** for lookup compatibility.

Debug:

```sh
make hook-debug a:start
make hook-debug s:instance a:start v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
```

Hook lookup caches under `data/asc/cache/hook.*.sh`. Overrides: `scripts/asc/override/` via autoload override. Colocated `*.opt-inc.sh` can be seeded into the hook cache before hook bodies (foreign-subject implementers).

---

## variants

Variant globals become **dotted filename parts** in most-specific lookup (via `u_str_subsequences`).

Example: `-v 'HOST_TYPE INSTANCE_TYPE'` expands combinations such as `init.hook.sh`, `init.local.hook.sh`, `init.local.dev.hook.sh`, …

Operator “combos” (chain / batch / pipe) are **wrappers**, not hook variants — see [wrappers.md](wrappers.md).

---

## bootstrap : inc, opt-inc

Every action starts with:

```bash
. asc/bootstrap.sh
```

Must run from `$PROJECT_DOCROOT`.

| Scope | Behavior |
|-------|----------|
| Phases **10–70** | Once per shell (`ASC_BS_FLAG=1`) |
| Phase **90** | Every bootstrap (caller opt-inc) |

Phase map (summary):

```text
10-shell → 20-utilities → 30-globals → 40-primitives
→ 50-pre-hooks → 60-includes (ASC_INC) → 70-bootstrap-hook
→ 90-caller-opt-inc
```

| Pattern | When |
|---------|------|
| `$subject/$subject.inc.sh` or `$ext/$ext.inc.sh` | Eager → `ASC_INC` (phase 60) |
| `$subject/$subject.opt-inc.sh` | Lazy when any action in that subject is the caller |
| `$subject/$action.opt-inc.sh` | Lazy for that action (also seedable into hook cache) |

Primitives cache: `data/asc/cache/asc.sh` (miss → `u_asc_extend`). Nested exec starts a **new** bootstrap in the child.

---

## make shortcuts

Short names come from synonym / shortening maps applied in make task naming (e.g. `ASC_SYNONYMS`).

| Alias | Meaning |
|-------|---------|
| `lt` | logged-thread |
| `lc` | logged-chain |
| `ls` | logged-sequence |
| `lb` | logged-batch |
| `lp` | logged-pipe |
| `ll` | logged-loop |
| `reg` | registry |
| `pl` | lookup-path (**not** pipe) |
| `cc` | cache-clear |

Typical core targets after init: `setup`, `start`/`stop`, `build`/`destroy`, `reinit`, `asc-upgrade`, `test-asc`, host/git helpers, … — see generated.mk + `asc/make/default.mk`.

Escape awkward make args with root helper `asc/escape.sh` (intentionally outside bootstrap includes).

Regenerate after synonym or action changes: **`make reinit`**.

---

## (re)init : cache, state

| Command | Role |
|---------|------|
| `make init` / `make` | Instance init (default goal) |
| `make reinit` | Safe regen when globals already loaded |
| `make cc` / `asc-cache-clear` | Drop `data/asc/cache/` |
| `make uninit` | Tear down generated instance artifacts |

### Cache — current vs ideal

Today hook caches use opaque encoded filenames, e.g. `data/asc/cache/hook._w_s_instance_p_….sh`.

Ideal (ideas, not implemented):

```text
data/asc/cache/$subject/$action/$file_name
data/asc/cache/$subject/$action/$args/$file_name
```

Cached sourced scripts should still expose `$subject`/`$action` and which extension point wrote them (`./asc`, extensions, contrib, extend).

### State layers (short)

1. **Data** — `data/*`, host files  
2. **Globals** — readonly vs mutable  
3. **Abstract entry points** — wraps / placeholders  
4. **Core extensions** — opt-in concrete  
5. **Contrib / project extend** — shareable or scope-specific  

See also [wrappers.md](wrappers.md) for launch-stack layering (raw → thread → log wrap).
