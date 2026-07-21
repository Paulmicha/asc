# ASC core concept : Usage

Table of contents :

1. start
1. extend
1. customize
1. adapt
1. contribute

How to get a ASC instance running, grow it safely, and contribute back. Deep concepts: [organization.md](organization.md), [wrappers.md](wrappers.md), [entities.md](entities.md), [builder.md](builder.md), [documentation.md](documentation.md).

---

## start

### Prerequisites

- Bash **4+**
- Git
- Optional: GNU make, remote host with Bash 4+ over SSH
- Primarily tested on Debian-based Linux

### TL;DR

```sh
cp SPECIMEN.env.yml env.yml   # edit as needed
make setup                    # or: make  → instance init
```

Deep dives: [`docs/asc/`](README.md). Extension notes: [`asc/extensions/README.md`](../../asc/extensions/README.md).

### Placement

Two common layouts:

1. Monolithic repo (app + ASC in one docroot)
2. App code in a separate git repo (default assumption in this repo’s `.gitignore`)

ASC core (`asc/`) may live in the app docroot, a parent “dev stack” repo, or elsewhere. App paths are declared per `ASC_APPS` in `env.yml`. **All** ASC scripts and make targets run from `$PROJECT_DOCROOT`.

### Step by step

1. Copy or clone into the chosen docroot.
2. Review `.gitignore`.
3. Copy `asc/extensions/.asc_extensions_ignore` → `scripts/asc/override/.asc_extensions_ignore` and delete lines to **enable** extensions.
4. Copy `SPECIMEN.env.yml` → `env.yml`; use gitignored `.env-local.yml` for secrets / machine overrides.
5. Optionally add `scripts/asc/extend/` and `scripts/asc/override/`.
6. Run `make setup` (init → start → stage2/post hooks).

Idempotent. If globals are already readonly in the shell, use `make reinit` for the init step.

Smoke: `. asc/bootstrap.sh`, `make test-asc`, plus any host-provision paths you rely on.

---

## extend

Add behavior without forking core.

| Location | Use for |
|----------|---------|
| `scripts/asc/extend/$subject/$action.sh` | Project-specific actions / hooks / globals |
| `scripts/asc/contrib/$extension/` | Shareable third-party-ish extensions |
| `asc/extensions/$extension/` | Bundled optional features (upstream) |

Same subject/action layout and most-specific rules as core — see [organization.md](organization.md) § subjects / actions / hooks.

Nested instances: enable `nested_asc`, then `make nested-asc-list` / `nested-asc-exec` ([wrappers.md](wrappers.md) § nested).

After adding files: `make cc` (optional) + **`make reinit`** so `generated.mk` and caches refresh.

---

## customize

Instance-local tuning.

| Lever | How |
|-------|-----|
| Extensions on/off | `scripts/asc/override/.asc_extensions_ignore` (and provision/domain-specific ignore variants when used) |
| Globals | `env.yml` + `.env-local.yml` |
| Hard path replace | `scripts/asc/override/` mirroring a sourced path |
| Variants | Extra `*.hook.sh` filename parts (HOST_OS, INSTANCE_TYPE, …) |
| Synonyms | Adjust `ASC_SYNONYMS` / shortening map → `make reinit` |
| Software manifest | `scripts/asc/extend/software/apps.manifest.yml` when `software` is enabled |

`PROVISION_USING=compose` still dual-resolves `docker-compose` in hook lookups for classic stacks.

---

## adapt

Bring an existing project or classic stack onto ASC.

### Layout & apps

Declare application docroots with `ASC_APPS` / per-app path globals in `env.yml`. Prefer running make from the stack root that owns `asc/`.

### Setup parameters

```sh
make setup
make setup prod
make setup prod remote myproject-2024 lamp
```

Maps to `INSTANCE_TYPE`, `HOST_TYPE`, `STACK_VERSION`, `PROVISION_USING`.

### Classic → ASC cutover (planned matrix)

| From | To |
|------|-----|
| `asc/` | `asc/` |
| `ASC_*` | `ASC_*` |
| `scripts/asc/` | `scripts/asc/` |
| Make `*-asc` / `upgrade-asc` | `*-asc` / `asc-upgrade` |
| Upstream | `Paulmicha/asc` branch **`main`** |

Hard prerequisites for older stacks:

- Extension `docker-compose` → `compose`
- Config `asc.yml` → `env.yml` (schema jump, not rename-only)
- Reinit after cut so `.env`, `generated.mk`, `global.vars.sh` regenerate

Suggested sequencing for multiple consumers: convert the day-to-day tip first, then other stacks; do **not** blind-promote a living tip into upstream in the same pass as rename. Keep nested discovery dual-tolerant (`asc/bootstrap.sh` / legacy paths) until cutovers finish.

Confirm `ASC_BRANCH` defaults to **`main`** in `asc/asc/upgrade.sh` before relying on `make asc-upgrade`.

---

## contribute

| Kind | Where |
|------|-------|
| Core primitives / wraps | `asc/` |
| Bundled opt-in features | `asc/extensions/$name/` |
| Design-before-implement | `scripts/asc/ideas/` — see [documentation.md](documentation.md) § ideas |
| Living docs | `docs/asc/` — this suite |
| Dated decisions | `changelog/YYYY/MM/DD-*.md` |

### Tests

```sh
make test-asc
```

Core cases under `asc/test/asc/*.test.sh`; extensions/extend append via `test/asc.hook.sh`. New cases need `make reinit` so per-case targets appear in `generated.mk`.

### Conventions

- Prefer self-explanatory filenames and paths.
- Keep complex agent / ontology work out of core.
- Do not commit generated `.env`, `data/asc/global.vars.sh`, or personal absolute paths.
- Mark stubs honestly (`# TODO`); do not invent behavior in docs.

### Roadmap (upstream)

- Keep `make test-asc` current
- Finish shared `sidecar.wrap.sh` body and migrate writers
- Improve macOS / POSIX where practical
- Offload heavy domains to nested apps when sensible

License: MIT (see [LICENSE](../../LICENSE)).
