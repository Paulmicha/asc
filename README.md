# Agnostic Shell Controller (ASC) 🔤🔠🔡🔢🔣🆒🆓

**Origin:** Forked from [Paulmicha/common-web-tools](https://github.com/Paulmicha/common-web-tools) branch `v2.0.0`, which is this repo’s **`main`**. That line diverged enough to warrant a dedicated project. Git history was rewritten to **ASC** identity (toolkit `asc/`, symbols `ASC_*` / `asc_*`), and the project is licensed under Apache-2.0; sensitive traces were removed.

This project attempts to tackle the hard problem of naming things. Its ambition is to set a common, shared vocabulary for anything interacting with the shell somehow, including linux kernel (or OS-level) interactions and beyond.

***Let's make words matter*** 📚

## Overarching goal

a slot-based abstraction layer to easily combine and pivot between any "shellable" entity (via entry points and conditional loading via hooks, with opt-in default minimal implementations via ASC "core" - this repo).

## Current status

Massive rewrite to shrink it to bare essentials, rethink things through.

See changelogs.

## End goal

Less reliant on bash (support any posix shell ?), make the shell scripts themselves "variant.able" via hooks...

## TL;DR

Clone or copy this repo into your project docroot, then:

```sh
cp SPECIMEN.env.yml env.yml   # edit as needed
make setup                    # or: make   → instance init
```

Deep dives live under [`docs/asc/`](docs/asc/). Extension notes: [`asc/extensions/README.md`](asc/extensions/README.md).

## WHAT

ASC is a scaffolding bash shell CLI for usual (web or general) project tasks — a generic, customizable, extensible toolbox for **local (internal) development**.

ASC is not a program; it is the “glue” between programs. Third-party integration is provided by **extensions** (bundled under `asc/extensions/`, often disabled by default). Core contains utilities for global environment variables, minimal host operations, optional git hooks, log/thread/loop wrappers, and low-level automated tests (`make test-asc`).

ASC is **not** meant for production. It helps individual developers or teams keep a common CLI across older and newer projects.

### Scope

- Thin layer to organize generic (pivot) shell entry points, enforcing a common implementation blueprint for (self-)building by humans and agents alike
- Simple, minimal, self-explanatory
- Delegate as much as possible, but still provide usual, optional (opt-in), generic needs as (overridable) "exemplar" implementation blueprints
- Define things and (implementation) contracts

### Non-goals ("out of scope"s)

- self-organizing abominable all-orchestrating plaform
- complex nl-related or agent-related stuff should be delegated to nested apps, e.g. :
  - ontology stuff (prompt engineering)
  - second-brain stuff (chain of thought, etc)
- in fact, anything complex is off limits

## PURPOSE

ASC organizes (mostly bash) scripts around conventions so you can swap implementations without rewriting every project’s workflow:

- host-level dependencies / provisioning
- credentials and registries
- building / running / stopping / destroying instances (variants per env type)
- generating local app settings
- linting / watching / compiling
- cron / long-running loops
- automated tests
- remote two-way sync
- etc.

## HOW (concepts in brief)

ASC relies on **file structure**, **naming conventions**, and a few primitives:

| Concept | Summary | Deep dive |
|---------|---------|-----------|
| **Globals** | Instance env vars from `env.yml` / `global.vars.sh`, written to `.env` + `data/asc/global.vars.sh` | [docs/asc/globals.md](docs/asc/globals.md) |
| **Bootstrap** | `. asc/bootstrap.sh` → numbered phases; eager `*.inc.sh` vs lazy `*.opt-inc.sh` | [docs/asc/bootstrap.md](docs/asc/bootstrap.md) |
| **Instance init** | Aggregates globals, optional git hooks, generates make shortcuts | `u_instance_init()` in `asc/instance/instance.inc.sh` |
| **Actions** | Folders = subjects, files = actions → `data/asc/generated.mk` | [docs/asc/actions-and-make.md](docs/asc/actions-and-make.md) |
| **Hooks** | File-based events (`*.hook.sh`) with variant combinations | [docs/asc/hooks.md](docs/asc/hooks.md) |

Prefer the lowest of five **implementation layers** (data → globals → abstract entry points → core extensions → project extend). See [docs/asc/layers.md](docs/asc/layers.md).

### ASC data types

- globals (`readonly` or mutable, may be secret + TODO encrypted ?)
- cache or sidecars (ex: logs) or media or test artifacts in `data/*` dirs
- other `*.yml` (ex: remote instances or any entity)
- encrypted (git) versionned files (cf. `data/crypted`)

### ASC extension points = the containing folders of `$subject`/`$action`.sh scripts

- `./asc`
- `./asc/extensions/$extension`
- `./asc/extensions/$extension/**/$nested_extension` (via .asc_subjects_ignore)
- `./scripts/asc/contrib/$extension`
- `./scripts/asc/contrib/$extension/**/$nested_extension` (via .asc_subjects_ignore)
- `./scripts/asc/extend`
- `./scripts/asc/extend/**/$nested_extension` (via .asc_subjects_ignore)

### ASC Generic -> Specific scale of actions = entry points = `$subject`/`$action`.sh scripts

Goal :
The bottom of this list wins when implementing the same `u_hook_most_specific()` :

1. `asc/$subject/$action`
1. `asc/extensions/$extension/$subject/$action`
1. `asc/extensions/$extension/**/$nested_extension` (via .asc_subjects_ignore)
1. `scripts/asc/contrib/$extension/$subject/$action`
1. `scripts/asc/contrib/$extension/**/$nested_extension` (via .asc_subjects_ignore)
1. `scripts/asc/extend/$subject/$action`
1. `scripts/asc/extend/**/$nested_extension` (via .asc_subjects_ignore)

### Prerequisites

- Bash **4+** (macOS: install a modern bash via Homebrew and set it as your shell if needed)
- Git
- An existing or new project directory
- [optional] Remote host with Bash 4+ over SSH
- [optional] GNU make

Disclaimer: ASC is primarily tested on Debian-based Linux.

## Usage / Getting started

### Placement

Two common layouts:

1. Single “monolithic” repo for the whole project
2. Application code in a separate Git repo (default assumption in this repo’s `.gitignore`)

ASC core (`asc/`) may sit inside the app (same docroot), in a parent “dev stack” repo (usual), or elsewhere on the host. App paths are typically declared per `ASC_APPS` entry (e.g. `SITE_DOCROOT`) via `env.yml`. **All** ASC scripts and `make` targets must be run from `$PROJECT_DOCROOT`.

### Step by step

1. Copy this repo’s files into the chosen docroot (or clone and use as the stack root).
2. Review [`.gitignore`](.gitignore) and adapt it.
3. Override extension defaults: copy `asc/extensions/.asc_extensions_ignore` → `scripts/asc/override/.asc_extensions_ignore` and edit (delete a line to **enable** that extension).
4. Copy [`SPECIMEN.env.yml`](SPECIMEN.env.yml) → `env.yml` and edit. Settings that **do not vary** much between instance types belong here (stack version, apps, paths). Use gitignored `.env-local.yml` for machine-private overrides.
5. Optionally implement project code under `scripts/asc/extend/` and overrides under `scripts/asc/override/`.
6. Run **instance setup**:

```sh
make setup
# Or:
asc/instance/setup.sh
```

Setup runs, in order:

1. **instance init** — write globals (`.env`, `data/asc/global.vars.sh`), generate `data/asc/generated.mk`, optional git hooks, caches
2. **instance start** — start services if hooks implement them
3. **stage2 / post setup hooks** — e.g. create DBs, import dumps, vendor install (extension-defined)

Idempotent: safe to re-run. If globals are already `readonly` in the current shell, use a new terminal or `make reinit` instead of `setup` for the init step.

### Setup parameters

From [`asc/instance/setup.sh`](asc/instance/setup.sh):

| Param | Global | Default |
|-------|--------|---------|
| 1 | `INSTANCE_TYPE` | `dev` |
| 2 | `HOST_TYPE` | `local` |
| 3 | `STACK_VERSION` | empty (falls back to global default `v1` on init) |
| 4 | `PROVISION_USING` | `compose` (note: core global default when undeclared is `asc`) |

Examples:

```sh
make setup
make setup prod
make setup prod remote myproject-2024 lamp
```

## File structure

```txt
/path/to/my-project/          ← $PROJECT_DOCROOT
  ├── app,site,api/ …         ← [optional, nested git repos] application trees (per ASC_APPS / env.yml)
  ├── changelog/              ← [optional] documentation of past or planned modifications
  │   └── ...
  ├── asc/                    ← [$subject/$action ext.point] ASC core (update = replace folder)
  │   ├── env/                ← core global.vars.sh + helpers
  │   ├── extensions/         ← bundled extensions (opt-in via ignore file)
  │   │   ├── $ext/           ← [$subject/$action ext.point] core asc extension
  │   │   │   ├── .asc_subjects_ignore  ← [nested $ext] submodule(s) (recursive)
  │   │   │   └── ...
  │   │   ├── .asc_extensions_ignore  ← default blacklisted core asc extensions
  │   │   └── ...
  │   ├── git/                ← git hooks integration + utilities
  │   ├── host/               ← host provision, registry, vitals
  │   ├── instance/           ← lifecycle + logged runners + chain/pipe
  │   ├── log/,sidecar/,loop/,thread/ ← core ASC wrappers
  │   ├── make/               ← default.mk + call_wrap
  │   ├── test/               ← shunit2 low-level suite
  │   ├── utilities/          ← internal libraries
  │   ├── vendor/             ← shunit2, bash-yaml
  │   ├── .asc_subjects_ignore  ← [$subject/$action ext.point] blacklisted subfolder(s)
  │   └── bootstrap.sh        ← included in all entry points, loads bash functions and globals
  ├── data/                   ← runtime / generated (mostly gitignored)
  │   ├── cronjobs/           ← [optional, git-ignored] default place for cron jobs outputs
  │   │   └── $subject/       ← $action per $subject filesystem structure
  │   │       └── $action/
  │   │           └── ...
  │   ├── asc/                ← [git-ignored] Generated files specific to this local instance
  │   │   ├── cache/          ← current local instance generated hooks and *.opt-inc.sh auto-include cache
  │   │   │   └── $subject/   ← $action per $subject filesystem structure
  │   │   │       └── $action/
  │   │   │           └── ...
  │   │   ├── registry/       ← [optional] contains keyed "file-based store" values
  │   │   ├── generated.mk    ← current local instance generated make entry points
  │   │   └── global.vars.sh  ← current local instance generated (readonly) ENV vars
  │   ├── logs/               ← [optional, git-ignored] default place for logs (see also log-rotate)
  │   ├── loops/              ← [optional, git-ignored] default place for loops (see also log-rotate)
  │   ├── media/              ← [optional, git-ignored] default place for media
  │   ├── private/            ← [optional, git-ignored] default place for private files
  │   ├── test-results/       ← [optional] frozen (versionned) test results
  │   ├── threads/            ← [optional, git-ignored] default place for storing threads info
  │   ├── process/            ← [optional, git-ignored] default place for storing process info
  │   ├── tmp/                ← [optional, git-ignored] default place for temporary files
  │   └── ...
  ├── docs/
  │   ├── asc/                ← ASC-related deep-dive guides and living documentation
  │   └── ...
  ├── scripts/
  │   └── asc/
  │       ├── contrib/             ← contrib asc implementations
  │       │   ├── $ext/            ← [$subject/$action ext.point] contrib asc extension
  │       │   │   ├── .asc_subjects_ignore  ← [nested $ext] submodule(s) (recursive)
  │       │   │   └── ...
  │       │   └── .asc_extensions_ignore  ← blacklisted contrib asc extensions
  │       ├── extend/             ← [$subject/$action ext.point] project-specific asc implementations
  │       │       ├── .asc_subjects_ignore  ← [nested $ext] submodule(s) (recursive)
  │       │       └── ...
  │       └── override/           ← replace any sourced (core or contrib) ASC path
  │           ├── .asc_extensions_ignore  ← this instance's blacklisted (core or contrib) asc extensions
  │           └── ...
  ├── .gitignore
  ├── Makefile
  ├── .env                    ← [git-ignored] generated current local instance ENV vars
  ├── .env-local.yml          ← [optional, git-ignored] secret ENV vars (hardcoded)
  ├── .env-local.foobar.yml   ← [optional, git-ignored] conditional (hook-based) secret ENV vars (hardcoded)
  ├── env.yml                 ← this project instance global env vars declaration
  ├── SPECIMEN.env.yml        ← copy to env.yml
  ├── SPECIMEN.remote_instances.yml  ← [optional] copy to remote_instances.yml
  └── ...
```

The canonical path for writing files related to time-recurrent or long processes is :

```txt
data/<data_name>/YYYY/MM/DD/HH.MM.SS.MS.<file_name>.md
```

Ex : `data/event/2026/07/17/11.06.55.1234.drush_cron.md`

The `changelog/` dir tipically contains files like :

```txt
changelog/YYYY/MM/DD-<file_name>.md
```

Ex : `changelog/2026/07/17-implement-new-ollama-subject.md`

Generated (do not hand-edit): `.env`, `data/asc/global.vars.sh`, `data/asc/generated.mk`, `data/asc/cache/*`.

## Five implementation layers

| # | Layer | Owns | Examples |
|---|-------|------|----------|
| 1 | Data | `data/…`, host files — state only | Examples |
| 2 | Global ENV vars | readonly globals vs calling-scope mutables | Examples |
| 3 | Abstract core entry points | wraps / placeholders | Examples |
| 4 | Core extensions | abstract + minimal concrete | Examples |
| 5 | Contrib extensions | Shareable / optionally integrable ASC implementations (see LICENSEs) | Examples |
| 6 | Project (scope-specific) extend | Any ASC implementation specific to the current project / scope | Examples |

Full table, mermaid, and **launch** layer stack (raw → thread → log wrap): [docs/asc/layers.md](docs/asc/layers.md).

## Adapt / Alter / Extend

- Project scripts under `scripts/`
- Generic reusable extensions as folders in `asc/extensions/`
- Project-only hooks/globals/actions in `scripts/asc/extend/`
- Hard replacements via `scripts/asc/override/`

Details: [docs/asc/extensions.md](docs/asc/extensions.md).

### Globals (summary)

On init, globals are written to:

- `.env` — Makefile and other tools
- `data/asc/global.vars.sh` — sourced every bootstrap (phase 30)

Declare via `global NAME "…"` in `global.vars.sh` files, or YAML in `env.yml` / `.env-local.yml`. List aggregation paths:

```sh
make globals-lp
```

Selected core defaults (`asc/env/global.vars.sh`):

```sh
global PROJECT_DOCROOT "[default]='$PWD' …"
global STACK_VERSION "[default]=v1 …"
global INSTANCE_TYPE "[default]=dev …"
global PROVISION_USING "[default]=asc …"
global HOST_TYPE "[default]=local …"
global HOST_OS "$(u_host_os)"
global ASC_APPS "[default]='site' …"
global ASC_MAKE_INC "[append]='$(u_asc_extensions_get_makefiles)'"
global ASC_SYNONYMS "[append]='registry/reg lookup-path/pl logged-thread/lt logged-batch/lb logged-chain/lc logged-sequence/ls logged-loop/ll logged-pipe/lp transcribe-transcribe/transcribe'"
```

More: [docs/asc/globals.md](docs/asc/globals.md). Secrets stance: [docs/asc/secrets.md](docs/asc/secrets.md).

### Actions (summary)

```sh
make list-actions
```

Hardcoded shortcuts ([`asc/make/default.mk`](asc/make/default.mk)): `init` (also default `make`), `init-debug`, `setup`, `hook`, `hook-debug`, `globals-lp`, `debug`.

After init, `data/asc/generated.mk` adds subject/action targets. Typical core shortcuts (instance subject often omitted):

| Name | Script | Shortcut |
|------|--------|----------|
| *git write-hooks* | `asc/git/write_hooks.sh` | `make git-write-hooks` |
| *host provision* | `asc/host/provision.sh` | `make host-provision` |
| *host registry-\** | `asc/host/registry_*.sh` | `make host-reg-*` |
| *host vitals* | `asc/host/vitals.sh` | `make host-vitals` |
| *instance build* | `asc/instance/build.sh` | `make build` |
| *instance destroy* | `asc/instance/destroy.sh` | `make destroy` |
| *instance fix-ownership* | `asc/instance/fix_ownership.sh` | `make fix-ownership` |
| *instance fix-perms* | `asc/instance/fix_perms.sh` | `make fix-perms` |
| *instance init* | `asc/instance/init.sh` | `make init` / `make` |
| *instance rebuild* | `asc/instance/rebuild.sh` | `make rebuild` |
| *instance registry-\** | `asc/instance/registry_*.sh` | `make reg-*` |
| *instance reinit* | `asc/instance/reinit.sh` | `make reinit` |
| *instance restart* | `asc/instance/restart.sh` | `make restart` |
| *instance setup* | `asc/instance/setup.sh` | `make setup` |
| *instance start / stop* | `asc/instance/start.sh` / `stop.sh` | `make start` / `stop` |
| *instance chain* | `asc/instance/chain.sh` | `make chain` |
| *instance parallel / pipe* | `asc/instance/parallel.sh` / `pipe.sh` | `make parallel` / `pipe` |
| *instance logged-\** | `asc/instance/logged_*.sh` | `make lt` / `lc` / `ls` / `lb` / `lp` / `ll` |
| *instance switch-stack-version* | `asc/instance/switch_stack_version.sh` | `make switch-stack-version` |
| *instance uninit* | `asc/instance/uninit.sh` | `make uninit` |
| *asc upgrade* | `asc/asc/upgrade.sh` | `make asc-upgrade` |
| *asc cache-clear* | `asc/asc/cache_clear.sh` | `make cc` |
| *test asc* | `asc/test/asc.sh` | `make test-asc` |

Logged runners and operators: [docs/asc/observability.md](docs/asc/observability.md), [docs/asc/layers.md](docs/asc/layers.md).

```sh
make lt e:some-entry
make lc e:1:step-a e:2:step-b a:arg
make lb e:job-a e:job-b
make lp e:stage-a e:stage-b
make ll e:long-running
```

After changing `ASC_SYNONYMS`: `make reinit`.

### Automatic includes (summary)

| Pattern | When |
|---------|------|
| `$subject/$subject.inc.sh` / `$ext/$ext.inc.sh` | Eager → `ASC_INC` (phase 60) |
| `$subject/$subject.opt-inc.sh` | Lazy when any action in that subject is the caller |
| `$subject/$action.opt-inc.sh` | Lazy for that action (also seedable into hook cache) |

More: [docs/asc/bootstrap.md](docs/asc/bootstrap.md).

### Hooks (summary)

```sh
make hook-debug a:start
make hook-debug s:instance a:start v:STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE
```

`PROVISION_USING=compose` and `docker-compose` both expand in lookups (dual-compat). Specificity and filters: [docs/asc/hooks.md](docs/asc/hooks.md).

Example:

```sh
hook -s 'app instance' \
  -a 'fs_perms_set' \
  -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
```

Default `fs_perms_set` only touches ASC-managed paths (`./data`, `./asc`, `./scripts/asc`, `./.git`, plus a small whitelist of root files such as `env.yml` / `Makefile`).

### Extensions (summary)

Enable/disable via ignore files (see above). Catalog of bundled folders:

| Name | Default on? | Description |
|------|:-----------:|-------------|
| `apache` | | Apache VHost helpers (classic LAMP, non-compose) |
| `arangodb` | | Alias / image tag defaults |
| `builder` | | Templates / blueprints / prototypes stubs ([docs/asc/builder.md](docs/asc/builder.md)) |
| `cognition` | | `observe-*` / `recognize-*` stubs |
| `compose` | | Docker Compose start/stop/build/destroy (`DC_MODE`, stack helpers) |
| `crontab` | | Host crontab sync helpers |
| `db` | | Abstract DB hooks |
| `drupalwt` | | Drupal tasks ([extension README](asc/extensions/drupalwt/README.md)) |
| `drupalwt_d4d` | | Drupal + compose / docker4drupal-oriented stack |
| `drush` | | Drush aliases / hooks |
| `file_registry` | ✔ | Default file-based registry (instance / host) |
| `git_crypt` | | Opt-in encryption hooks (stub) |
| `gpt` | | LLM abstracts (`gpt-start`, …) |
| `hosts_file` | | `/etc/hosts` helpers |
| `interaction` | | Interactive prompt helpers |
| `memory` | | Storage / store stubs |
| `moodle_d4php` | | Moodle + docker4php-oriented stack |
| `mysql` | | MySQL implementations of `db` |
| `nested_asc` | | Nested instance list/exec ([docs/asc/nested-asc.md](docs/asc/nested-asc.md)) |
| `node` | | Aliases / default port |
| `ollama` | | Default hooks for `gpt-*` via Ollama |
| `pgsql` | | Postgres implementations of `db` |
| `remote` | | SSH sync utilities |
| `remote_asc` | | Remote ASC helpers |
| `remote_db` | | DB dump sync via `db` + `remote` |
| `remote_traefik` | | Traefik / Let’s Encrypt defaults |
| `rules` | | Rule stubs |
| `software` | | Host package / provision hooks |
| `transcription` | | `transcribe` / `transcribe-all` |
| `views` | | View stubs |

Default-on assumes the stock core ignore list (everything listed there is off; `file_registry` is usually the exception). Project overrides win. More: [docs/asc/extensions.md](docs/asc/extensions.md), [`asc/extensions/README.md`](asc/extensions/README.md).

## Automated tests

```sh
make test-asc
```

Single orchestration hook: `test` / `asc`. Core cases under `asc/test/asc/*.test.sh`; extensions and `scripts/asc/extend` can append via `test/asc.hook.sh`. Per-case make targets are generated into `data/asc/generated.mk` on `reinit` (registry: `data/asc/cache/test-cases.sh`).

Full guide: [docs/asc/testing.md](docs/asc/testing.md).

## Docs index

1. [documentation (3 types only, as far as ASC is concerned)](docs/asc/documentation.md)
    1. [ideas](docs/asc/documentation.md#ideas)
    1. [changelogs](docs/asc/documentation.md#changelogs)
    1. [living docs](docs/asc/documentation.md#living)
1. [organization](docs/asc/organization.md)
    1. [globals](docs/asc/organization.md#globals)
    1. [hosts](docs/asc/organization.md#hosts)
    1. [instances](docs/asc/organization.md#instances)
    1. [humans vs agents (ownership ?)](docs/asc/organization.md#humans-vs-agents-ownership)
    1. [subjects](docs/asc/organization.md#subjects)
    1. [actions](docs/asc/organization.md#actions)
    1. [hooks](docs/asc/organization.md#hooks)
    1. [variants](docs/asc/organization.md#variants)
    1. [bootstrap : inc, opt-inc](docs/asc/organization.md#bootstrap-inc-opt-inc)
    1. [make shortcuts](docs/asc/organization.md#make-shortcuts)
    1. [(re)init : cache, state](docs/asc/organization.md#re-init-cache-state)
1. [wrappers](docs/asc/wrappers.md)
    1. [batch (synonym : parallel)](docs/asc/wrappers.md#batch-synonym-parallel)
    1. [chain (synonym : sequence)](docs/asc/wrappers.md#chain-synonym-sequence)
    1. [cronjob (TODO or just use "raw" thread wrapper instead ?)](docs/asc/wrappers.md#cronjob-todo-or-just-use-raw-thread-wrapper-instead)
    1. [loop (TODO synonyms : deamon ? background task ? background job ? always-on ?)](docs/asc/wrappers.md#loop-todo-synonyms-deamon-background-task-background-job-always-on)
    1. [nested](docs/asc/wrappers.md#nested)
    1. [pipe](docs/asc/wrappers.md#pipe)
    1. [remote](docs/asc/wrappers.md#remote)
    1. [rule (conditional and/or nested combinations)](docs/asc/wrappers.md#rule-conditional-and-or-nested-combinations)
    1. [sequence](docs/asc/wrappers.md#sequence)
    1. [stream ?](docs/asc/wrappers.md#stream)
    1. [thread](docs/asc/wrappers.md#thread)
    1. [tunnel](docs/asc/wrappers.md#tunnel)
    1. [vpn](docs/asc/wrappers.md#vpn)
    1. [curl](docs/asc/wrappers.md#curl)
    1. [$protocol ? (http, etc)](docs/asc/wrappers.md#protocol)
1. [entities](docs/asc/entities.md)
    1. [represents ? (why it exists)](docs/asc/entities.md#represents-why-it-exists)
    1. [definition (scope ?)](docs/asc/entities.md#definition-scope)
    1. [capabilities](docs/asc/entities.md#capabilities)
    1. [relationships](docs/asc/entities.md#relationships)
    1. [compatibility, applicability ? (protocols, etc)](docs/asc/entities.md#compatibility-applicability-protocols-etc)
    1. [yml includes (synonym : inheritance)](docs/asc/entities.md#yml-includes)
1. [builder](docs/asc/builder.md)
    1. [documenting (~ minimal OKF ? dedicated core extension ?)](docs/asc/builder.md#documenting-minimal-okf-dedicated-core-extension)
    1. [blueprints](docs/asc/builder.md#blueprints)
    1. [slots](docs/asc/builder.md#slots)
    1. [templates](docs/asc/builder.md#templates)
    1. [self-building (chain.able, nest.able, rule.able codegen for humans and agents)](docs/asc/builder.md#self-building-chain-able-nest-able-rule-able-codegen-for-humans-and-agents)
1. [testing](docs/asc/testing.md)
    1. [1. Conventions (layers)](docs/asc/usage.md)
    1. [1. asc/vendor/shunit2 dependency](docs/asc/usage.md)
    1. [1. TODO new browser asc core extension, with playwright as default implementation in core as well ?](docs/asc/usage.md)
1. [usage](docs/asc/usage.md)
    1. [start](docs/asc/usage.md#start)
    1. [extend](docs/asc/usage.md#extend)
    1. [customize](docs/asc/usage.md#customize)
    1. [adapt](docs/asc/usage.md#adapt)
    1. [contribute](docs/asc/usage.md#contribute)

## Roadmap

- Keep `make test-asc` (and per-case targets) current
- Finish shared sidecar wrap body and migrate writers ([docs/asc/sidecar-wrap.md](docs/asc/sidecar-wrap.md))
- Fix macOS-specific errors
- Offload more tasks to third-party projects where sensible
- Reduce bashisms / improve POSIX compatibility where practical

## Contributors

Project name, ideas & "rock n rôle" : [arhkaos](https://github.com/arhkaos)

## License

Apache License 2.0 (see [LICENSE](LICENSE)).
