# Agnostic Shell Controller (ASC) 🔤🔠🔡🔢🔣🆒🆓

ASC is not a program; it is the “glue” between programs. It is a generic, customizable, extensible toolbox for a wide range of **local development** tasks, with the ambition to serve humans and agentic systems alike.

It allows to set a common, shared vocabulary for anything interacting with the shell. It provides mechanisms allowing to establish "pivots" that represent actions with varying implementations.

The only job of ASC is to serve as a thin layer that :

- **wraps** calls to other CLIs and/or OS-level operations ;
- **sets** a naming convention that persists despite implementation changes, i.e. the *action* `make transcribe-file -- path/to/file.mp4` will remain identical, even when the program(s) used to do the actual transcribing in a project using ASC do ;
- allows to provide **adaptations** to a variety of contextual *variants* such as host types (local, remote), OS (debian, alpine, windows, ios, etc).

## Overarching goal

Like the Go game, but with (make) entry points, (global) env vars, hooks (variants), wrappers (scripts), metadata (yml), and some generic implementations (opt-in).

***Let's make words matter*** 📚

English is the **pivot NL** for labels (canonical spelling — not a make `$subject-$action` pivot). French and Brazilian Portuguese map onto that same English label, then the token. A later Projet Complexe instance may declare its counterpart.

The main README (this file) is authoritative on the meaning associated with ASC concepts and on their "raison d'être" (if, when and where it is deemed necessary to add clarifications).

### Scope

- Thin layer to organize generic (pivot) shell entry points, enforcing a common implementation blueprint for (self-)building by humans and agents alike
- Simple, minimal, self-explanatory
- Delegate as much as possible, but still provide usual, optional (opt-in), generic needs as (overridable) "exemplar" implementation blueprints
- Define things and (implementation) contracts
- Generate simple ASC code from folder or string templates (i.e. `asc/extensions/builder`) to record, standardize and encourage recommended, "exemplar" design patterns
- Provide a complementary "anti-pattern" registry to serve the opposite function (things to avoid, aiming at constant overall code quality improvement)

### Non-goals ("out of scope"s)

- code refactoring
- self-organizing abominable all-orchestrating platform
- complex NL-related or agent-related stuff should be delegated to dedicated project instances
- in fact, anything complex is off limits

## Table of contents

<nav>

- [Overarching goal](#overarching-goal)
  - [Scope](#scope)
  - [Non-goals ("out of scope"s)](#non-goals-out-of-scopes)
- [Purpose](#purpose)
- [How (concepts in brief)](#how-concepts-in-brief)
- [Example project (demo / case study)](#example-project-demo-case-study)
- [Current status of the ASC project](#current-status-of-the-asc-project)
- [Documentation](#documentation)
  - [Skills, Instructions, Capabilities (`AGENTS.md` & `SKILL.md`)](#skills-instructions-capabilities-agentsmd-skillmd)
  - [Design patterns vs. Anti-patterns](#design-patterns-vs-anti-patterns)
    - [Design patterns : DOS / HOWTOS](#design-patterns-dos-howtos)
    - [Anti-patterns : DONTS](#anti-patterns-donts)
    - [Enforcement, "alignment" (drift control)](#enforcement-alignment-drift-control)
    - [Guards, "gates"](#guards-gates)
  - [Specs, Contracts, Living Docs (SPECS)](#specs-contracts-living-docs-specs)
  - [Changes, Implementation Steps, Execution Plans (PLANS)](#changes-implementation-steps-execution-plans-plans)
  - [Problems, Improvements (ISSUES)](#problems-improvements-issues)
  - [Priorities (NEXT_STEPS)](#priorities-nextsteps)
  - [Guards, "gates"](#guards-gates-1)
- [ASC concepts](#asc-concepts)
  - [General notes](#general-notes)
  - [Vendor (= third-party) libs](#vendor-third-party-libs)
  - [Genericity (scale)](#genericity-scale)
    - [Core](#core)
    - [Extensions](#extensions)
      - [Enabling and disabling extensions](#enabling-and-disabling-extensions)
    - [Overrides](#overrides)
    - [Project-specific implementations](#project-specific-implementations)
  - [Bootstrap (ASC-bootstrapped context)](#bootstrap-asc-bootstrapped-context)
    - [Initial (= cold) VS initialized (= warm) VS "out of sync" (= stale) contexts](#initial-cold-vs-initialized-warm-vs-out-of-sync-stale-contexts)
    - [Always (= eager) VS conditionally (= lazy) sourced includes](#always-eager-vs-conditionally-lazy-sourced-includes)
      - [Exceptions](#exceptions)
      - [Recap](#recap)
  - [Project instance (re)initialization process](#project-instance-reinitialization-process)
    - [Cold → Warm : the initialization process](#cold-warm-the-initialization-process)
    - [Stale → Warm : drift re-alignment](#stale-warm-drift-re-alignment)
    - [(any state) → Cold](#any-state-cold)
    - [Interdependence](#interdependence)
  - [Extension Point](#extension-point)
  - [Active Dir](#active-dir)
  - [Actions = (make) _Entry points_](#actions-make-entry-points)
  - [Environment variables (*env vars*)](#environment-variables-env-vars)
    - [Declaring globals (= constants)](#declaring-globals-constants)
    - [Interactive terminal prompts during (instance) init](#interactive-terminal-prompts-during-instance-init)
    - [Git-ignored, "private" _globals_](#git-ignored-private-globals)
  - [Hooks (and variants)](#hooks-and-variants)
    - [Most specific hooks (`hook_ms()`) lookup and collisions](#most-specific-hooks-hookms-lookup-and-collisions)
  - [Hosts](#hosts)
  - [(Projet) Instance(s)](#projet-instances)
  - [ASC discovery recap](#asc-discovery-recap)
  - [Tests](#tests)
    - [ASC core tests](#asc-core-tests)
    - [Pre and post test suite execution (shunit2) functions](#pre-and-post-test-suite-execution-shunit2-functions)
    - [Test results](#test-results)
  - [ASC domain-specific language : *DSL* syntax](#asc-domain-specific-language-dsl-syntax)
    - [Entry points](#entry-points)
    - [Arguments](#arguments)
    - [Variables](#variables)
    - [Functions](#functions)
    - [Chaining](#chaining)
    - [Parallel](#parallel)
    - [Piping](#piping)
    - [Conditional execution](#conditional-execution)
    - [Redirecting](#redirecting)
    - [Iterations (= loops, foreach, for ... in)](#iterations-loops-foreach-for-in)
    - [Filename-safety](#filename-safety)
    - [DSL examples](#dsl-examples)
  - [Data dirs = "data pivots"](#data-dirs-data-pivots)
    - [ASC data convention](#asc-data-convention)
    - [Deployable local project instance settings (instance-level + host-level)](#deployable-local-project-instance-settings-instance-level-host-level)
    - [ASC cache : `data/asc/cache`](#asc-cache-dataasccache)
    - [Logs : `data/log`](#logs-datalog)
    - [Test `data/test`](#test-datatest)
      - [Results `data/test/result`](#results-datatestresult)
      - ["Frozen" results `data/test/frozen`](#frozen-results-datatestfrozen)
      - [Reports `data/test/report`](#reports-datatestreport)
    - [Temporary files : `data/tmp`](#temporary-files-datatmp)
- [Workflow](#workflow)
  - [Host copies and storage](#host-copies-and-storage)
  - [(re)Search](#research)
  - [Ideas](#ideas)
  - [Change(log)s](#changelogs)
  - [Doubts](#doubts)
- [Naming convention](#naming-convention)
  - [File names](#file-names)
  - [Coding style](#coding-style)
- [Usage / Getting started](#usage-getting-started)
  - [Prerequisites](#prerequisites)
  - [Placement](#placement)
  - [Step by step](#step-by-step)
  - [Setup parameters](#setup-parameters)
  - [Project stack "lifecycle" entry points](#project-stack-lifecycle-entry-points)
- [File structure](#file-structure)
- [Contributors](#contributors)
- [License](#license)

</nav>

## Purpose

ASC organizes (mostly bash) scripts around conventions so you can swap implementations without rewriting every project’s workflow :

- host-level dependencies / provisioning
- credentials and registries
- building / running / stopping / destroying instances (variants per env type)
- generating local app settings
- linting / watching / compiling
- cron / long-running loops
- automated tests
- remote two-way sync
- etc.

## How (concepts in brief)

ASC borrows some designs present in Git and in the [Drupal™](https://drupal.org) project. Those were originally transposed in a minimal fashion for devops-related tasks in Bash, but ASC is far less broad in scope and relies on **filesystem structure** and **naming conventions**. The crux of it is essentially :

| Concept | Summary |
|---------|---------|
| **Globals** | Instance env vars from `env.yml` / `global.vars.sh`, written to `.env` + `data/asc/globals.sh` |
| **Bootstrap** | `. asc/bootstrap.sh` ; eager `*.inc.sh` vs lazy `*.opt-inc.sh` |
| **Instance init** | Aggregates globals, optional git hooks, generates make shortcuts |
| **Actions** | Folders = subjects, files = actions → `data/asc/pivots.mk` |
| **Hooks** | File-based events (e.g. `*.hook.sh`) with variant combinations |

The rest of this README contains a bit more details, hopefully enough to decide whether it fits whatever reason have led your eyes here :)

## Example project (demo / case study)

Here is what I am currently building with it (when I have some free time) :

["_Projet Complexe_", a "second brain" project incorporating agentic task-oriented and knowledge-oriented implementations](data/ideas/2026/08/Projet%20Complexe%202026%20Revival%20(v2)%20-%20ASC,%20Projet%20Complexe%20and%20Projet%20Complexe%20ASC.pdf)

See :

- the corresponding [Projet Complexe ASC stack repo](https://github.com/Paulmicha/projet-complexe-asc)
- and [the UI (Tauri app) repo](https://github.com/Paulmicha/projet-complexe)

## Current status of the ASC project

*Massive rewrite* ☢️ to shrink it to bare essentials, rethink things through.

Potential collisions in filesystem :

- `$subject` / `$action`
- `$subject` / `$object` / `$action`

Resolution : agnostic stance. In terms of ASC entity representation, `$subject` may or may not choose to implement that extra level.

Implications : change ASC core current files discovery mechanisms to support both. Core discovery + pivots now see both nestings; remaining work is adopting the extra level in more trees (see README § ASC discovery recap).

1. [x] ~~Finish describing ASC "core" concepts explicitly~~
1. [x] ~~Stabilize Naming convention~~
1. [x] ~~Stabilize hooks~~
1. [x] ~~Stabilize DSL~~
1. [x] ~~Stabilize Yml~~
1. [x] ~~Refactor Bootstrap~~
1. [x] ~~Refactor core + core extensions~~
1. [x] ~~Refactor tests~~
1. [ ] Complete the Builder core extension
1. [ ] Complete DSL interpreter
1. [ ] Complete all synchronization entry points (instance, host, data)
1. [ ] Stabilize Stack and Host orchestration (containerization, virtualization, etc)
1. [ ] Stabilize docs and skills
1. [ ] Stabilize workflow (agent loop controls, git branching model, gates)
1. [ ] Agents (for now : Cursor + Codex + Ollama + Ollaya, next : Claude Code)
1. [ ] Sandboxing and Permissions ?

## Documentation

At the time of writing (mostly july to october 2026), there seems to be emerging open standards specifically built for AI context and standardized Markdown conventions aiming at constraining and structuring tasks.

ASC attemtps to unify humans and AI agents use of "prose" by using distinct types of documents while leveraging those emergent patterns where appropriate.

The [Diátaxis compass](https://diataxis.fr/compass/#compass) is a useful reference here. It breaks down documentation files into 4 types (*user* can also be an **agent** in our case) :

| If the content… | …and serves the user’s… | …then it must belong to… |
|-----------------|-------------------------|--------------------------|
| informs *action* | *acquisition* of skill | a **tutorial** |
| informs *action* | *application* of skill | a **how-to guide** |
| informs *cognition* | *application* of skill | **reference** |
| informs *cognition* | *acquisition* of skill | **explanation** |

In projects using ASC, we aim to follow this categorization whenever a documentation file (in the `docs` folder) is created.

TODO 2026-11-25 : Decide if we want strict paths enforcement like docs/tutorials, docs/howtos, docs/references, docs/explanations, or keep the current "loose" organization of (usually markdown) prose documents. We can even think about extending the structure to things like docs/dos and docs/donts, but I think the "gains" of enforcing such rigidity deserves scrutiny. We may not need that level of detail in the organization of documentation files.

### Skills, Instructions, Capabilities (`AGENTS.md` & `SKILL.md`)

ASC core (this repo = "mother" ASC repo) contains an `AGENTS.md` document pointing at the following skills :

- `.agents/skills/asc-actions-priority` prioritizes the use of local project instance ASC entry points defined as preferred alternatives compared to custom scripts and commands (e.g. like Docker compose, see the corresponding ASC extension) ;
- `.agents/skills/asc-author-docs` tells which documents are used to describe which rules, constraints, instructions, etc. - and what agents are allowed and not allowed to do in those docs ;
- `.agents/skills/asc-author-code` describes ASC-specific (bash) shell coding styles and design patterns ;
- `.agents/skills/asc-mother-guard` guards against potential privacy-related issues when improvements made on ASC itself is being contributed to this "mother" (*upstream*) repo from other projects using ASC.

&lt;proposal-2026-10-30&gt;

TODO [wip] we need to clarify things for the special use case of eventually turning the linux home dir into an ASC project instance, and more generally, how the eventual customzing of local project instances skills may conflict with eventual ASC upstream updates to be merged into individual project instances.

**The home directory becomes both an ASC instance and the location of user-wide agent configuration.** The distinction is the path and the agent feature involved.

For example, on a laptop, the four ASC skills in [`~/.agents/skills/`](~/.agents/skills) are **available across local workspaces** to Codex and Cursor. Codex sessions see both those home copies and the mother checkout’s project copies. Cursor also documents `~/.agents/skills/` as a global local-machine location. [Cursor skills documentation](https://cursor.com/help/customization/skills)

**Available everywhere does not mean applied in full on every task.** A skill supplies a name and description for discovery; the agent reads its `SKILL.md` when the task calls for it or when instructed to use it. An `AGENTS.md` instruction can make that use mandatory for a particular kind of work. [OpenAI skills documentation](https://developers.openai.com/plugins/concepts/skills)

| Location | Role on this laptop |
|---|---|
| `~/asc/` and `~/AGENTS.md` | Parts of the home-directory ASC instance. Its `AGENTS.md` is project guidance when that instance is in scope; it is not the same thing as Codex’s global instruction file. |
| `~/.agents/skills/` | User-wide skills location for local Codex and Cursor sessions—even in unrelated projects. The ASC skills themselves describe when they apply. |
| Mother `.agents/skills/` | Project copies belonging to the mother checkout. Other ASC instances can have their own project copies. |
| `~/.cursor/rules/` | Separate Cursor user-level rule files. Several currently say `alwaysApply: true`, including ASC-related rules; some of their text limits their applicability to ASC work. Cursor documents these as machine-local user rules, but I haven’t tested their delivery in a fresh Cursor session. [Cursor rules documentation](https://prod.cursor.com/help/customization/rules) |

For **Codex**, the global `AGENTS.md` location is under `~/.codex`; project instructions are discovered from the repository root toward the working directory. Consequently, don’t assume `~/AGENTS.md` is injected into every separate repository under your home directory. In this chat, the instructions injected for the mother checkout are its own project instructions. [OpenAI’s AGENTS.md guidance](https://learn.chatgpt.com/docs/agent-configuration/agents-md)

For the goal of getting mother skills into every ASC instance, the current mother checkout’s [`asc/core/upgrade.sh`](~/Documents/asc/asc/core/upgrade.sh:94) explicitly replaces the four named skill directories in the **instance where the upgrade runs**. If run from the home instance, those destinations are also the user-wide `~/.agents/skills` locations. It also **overwrites that instance’s `AGENTS.md`**, so instance-specific instructions in that file need attention before an upgrade.

The upgrade script `asc/core/upgrade.sh` copies from the selected upstream branch, and the script actually running in an instance may differ from the mother checkout’s current version. A local home copy does not necessarily travel automatically to other machines or Cursor cloud agents; Cursor specifically says `~/.agents/skills/` stays local.

The practical arrangement is therefore: **keep the mother as the maintained source, distribute its skills into each ASC instance, and treat the home instance’s copies as globally discoverable on this laptop.** Project-level copies and `AGENTS.md` remain valuable for other machines, collaborators, and remote agents.

&lt;/proposal-2026-10-30&gt;

### Design patterns vs. Anti-patterns

TODO Introduction paragraph. Skills need to be aware of such docs (markdown prose, eventual frontmatter spec). 

#### Design patterns : DOS / HOWTOS

TODO see `asc/extensions/builder` + decide if we need a more "controlled" vocabulary like [Atomic Design](https://atomicdesign.bradfrost.com/chapter-2/).

#### Anti-patterns : DONTS

TODO see `docs/anti-patterns` + decide **how to "wire" these with agents skills**, perhaps as a generic hook that generates skills and/or docs somewhere gitignored (like the `data` folder).

#### Enforcement, "alignment" (drift control)

TODO 

#### Guards, "gates"

TODO

### Specs, Contracts, Living Docs (SPECS)

Currently, the ASC main README file (this file) is serving as the main source of truth for all ASC-related implementations. It is entirely human-written, with eventual LLM-generated prose clearly delimited by escaped tags like `<proposal-2026-10-02>` and `</proposal-2026-10-02>` for marking what is currently being reviewed and rewritten.

&lt;proposal-2026-10-02&gt;

**Three-Tier Boundary System** : A standard practice within agent specs that categorizes rules into :

- Always do (e.g., run tests before committing)
- Ask first (e.g., deleting a file, adding a new npm package)
- Never do (e.g., rewriting historical git history)

&lt;/proposal-2026-10-02&gt;

### Changes, Implementation Steps, Execution Plans (PLANS)

TODO [wip]

### Problems, Improvements (ISSUES)

TODO [wip]

### Priorities (NEXT_STEPS)

TODO [wip]

### Guards, "gates"

TODO [wip]

## ASC concepts

### General notes

Unless explicitly stated, everything always **must** run from `$PROJECT_DOCROOT`, which is the folder where every project instance using ASC is installed locally (on the host used to work on - or run - the project).

In this README, the `$` prefix always means the following :

- `$subject` : any *active dir* folder representing an ASC *subject*.
- `$object` subfolders are almost identical, but they only support `$action` scripts (**not** hook implementations).
- `$action` are (Bash) shell script files placed in *active dirs* or `$object` subfolders.
- `$extension` are folders containing *active dirs* representing **enabled** extensions only.

### Vendor (= third-party) libs

Vendor libs should generally not be added into ASC project instances repositories. Exceptions live inside ASC core dir `asc/vendor` and exist to support ASC tests (`asc/vendor/shunit2`), minimal bash Yaml support (`asc/vendor/bash-yaml`) and pdf docs generation (`asc/vendor/katex`, `asc/vendor/mermaid.esm.min.mjs`). The recommended way to deal with dependencies is to delegate their setup to tools like pipx, uv, pnpm, cargo, appimage, snap, apt, or even apt, or simply docker and/or docker compose.

### Genericity (scale)

Two axes. This list is **kind**. Lookup lists later (extension points, active dirs, collisions) are **which file wins** — not this scale. `$object` is nesting, not a rung. **Kernel** means the five always-sourced includes, not Core.

1. **Core** = "generic" implementations that are systematically relevant across all projects using ASC (some of which - the core extensions themselves - are opt-in),
1. **Extensions** = namespaced bundles of actions by subjects and/or objects (including contrib, as in the Drupal ecosystem),
1. **Overrides** = alterations of implementations provided by core and/or extensions,
1. **Specifics** = implementations with low or no potential for reuse outside the current project ASC is used for.

#### Core

**Core** implementations include :

- Whatever ASC needs to work the way it does (low-level implementations like globals, shell scripts auto includes, hooks implementations discovery and conflicts resolution, instance and host-related implementations, etc.),
- Wrappers around common shell utilities (threads, logs, cronjobs, etc.),
- Minimal shell-based tests (using `asc/vendor/shunit2`),
- Generic utilities (a few basic shell scripting utilities - arrays, strings, filesystem-related, ssh-related, templating-related, git-related, yml-related - see `asc/vendor/bash-yaml`, etc.),
- A few opt-in extensions :
    - `asc/extensions/agent` : wraps and chains LLMs prompts (with pre- and post- process hooks), and provides generic abstractions to manage things like `SKILL.md` (see [pi](https://github.com/earendil-works/pi)) / `CLAUDE.md` / Cursor rules
    - `asc/extensions/builder` : minimalist ASC "clean" code generator
    - `asc/extensions/compose` : default Docker compose - related implementations
    - `asc/extensions/crontab` : default crontab-related implementations
    - `asc/extensions/db` : generic abstract placeholders (hooks) for database-related operations
    - `asc/extensions/file_registry` : minimalist local file-based key/value store (supports host-level and instance-level scopes). Host scope defaults to `$HOME/.local/state/asc/registry`.
    - `asc/extensions/interaction` : generic abstract placeholders (hooks) for interaction-related operations (like triggering input devices actions - e.g. mouse, keyboard, touch events, etc.)
    - `asc/extensions/memory` : generic abstract placeholders (hooks) for memory-related operations (like : find out if and where something is stored, using which storage, etc.)
    - `asc/extensions/remote` : default implementations related to remote communication (ssh, etc)
    - `asc/extensions/remote_instance` : implementations related to remote ASC project instances
    - `asc/extensions/software` : default implementations for managing software - usually dependencies, i.e. : updates, configuration, (un)installation, etc.
    - `asc/extensions/workflow` : default implementations for streamlining work processes, kinda like a minimalist and simpler implementation of [superpowers](https://github.com/obra/superpowers) for projects using ASC (complements the `rules` extension)

#### Extensions

An **extension** is a namespaced bundle under one of these folders (lookup order). `./asc/$subject` is Core. `scripts/asc/extend` is Specifics.

1. `./asc/extensions` — Core, opt-in
1. `./scripts/asc/contrib/asc` — Extension (ASC contrib)
1. `./scripts/asc/contrib/$vendor` — Extension (vendor contrib)

The default extensions provided by the main ASC repo are all *disabled* by default, except for `asc/extensions/file_registry`.

##### Enabling and disabling extensions

Edit `.asc_extensions_ignore` : like `.gitignore` files, it lists *disabled extensions* (extensions *not* listed in there are *enabled*). Each line must be either :

- an extension dir name in `asc/extensions` (e.g. `db`, `workflow`, `rules`, etc.),
- or a namespace-prefixed contrib extension dir name in `scripts/asc/contrib` (e.g. `asc/arcadedb`, `asc/docling`, `asc/ollama`, etc. - where the prefix is the `$vendor/` name).

The `make list-extensions` allows to inspect what's in current project instance :

```yml
# List enabled extensions only (default) :
make list-extensions
# Or :
asc/instance/list_extensions.sh

# List all extensions (enabled + disabled) :
make list-extensions 'a'
make list-extensions 'all'
# Or :
asc/instance/list_extensions.sh 'a'
asc/instance/list_extensions.sh 'all'

# List disabled extensions only :
make list-extensions 'd'
make list-extensions 'disabled'
# Or :
asc/instance/list_extensions.sh 'd'
asc/instance/list_extensions.sh 'disabled'
```

#### Overrides

Overrides are specific file paths allowing to swap includes provided by core and contrib implementations. They are not a lookup slot.

If the "counterpart" of a given file exists in the folder `scripts/asc/override`, it will be used instead of the original file. It's a mechanism that applies to both "autoload" includes (`*.inc.sh` and `*.opt-inc.sh`) and hook implementations.

The matching is done by replacing the leading `asc/` or `scripts/asc/contrib/` in filepaths with `scripts/asc/override/`.

Examples :

- if we want to *override* `asc/git/init.hook.sh` = **swap** it with our own copy of that file, we'll place it at that path : `scripts/asc/override/git/init.hook.sh` ;
- `asc/extensions/docker-compose/docker-compose.inc.sh` → `scripts/asc/override/extensions/docker-compose/docker-compose.inc.sh` ;
- etc.

This overriding mechanism is not to be confused with :

- `env.yml` files : see *env vars*
- `compose.override*.yml` : see (docker) *compose* extension

#### Project-specific implementations

For anything that has low or no reuse potential outside the current project, we can use custom *active dirs* placed in `./scripts/asc/extend`.

### Bootstrap (ASC-bootstrapped context)

A *bootstrapped* context is any shell context that has sourced `asc/bootstrap.sh`.

Sourcing the ASC bootstrap file loads *env vars* and Bash functions in the current *shell scope*, depending on "auto" (= "eager" = files using the `*.inc.sh` double extension), or "lazy" (= files using the `*.opt-inc.sh` double extension) loading of Bash shell script includes *corresponding to the entry point used*.

#### Initial (= cold) VS initialized (= warm) VS "out of sync" (= stale) contexts

There are 3 kinds of bootstrapped contexts :

1. when a project instance is not initialized yet (i.e. before `make init` = `asc/instance/init.sh` has run, also called during `reinit` and/or `setup`),
1. after initialization has run (usually once in a local project instance),
1. and after initialization has run but with some changes that make the cached files outdated (e.g. when some env vars change, or when a new extension is added or removed, etc).

**Initial (= cold)** state is the "out of the box" state (or after `make uninit`). In this state, none of the files above have been generated yet. See `Makefile` and `asc/make/default.mk` to see the default `make` entries that will work in this state (notably `init`, `setup`, and `globals-lp`). If the optional `scripts/asc/extend/custom.mk` file exists, the entries it contains will also work out of the box, before instance (re)init or setup has run.

**Initialized (= warm)** means the generated files listed above exist and correctly match the current local project instance state. The bootstrap runs faster because there is no need for the core discovery mechanisms to run (they just get sourced where appropriate). The hook cache progressively gets more and more complete, i.e. : if any hook call does not yet have a corresponding cache file, the corresponding discovery process runs once and generates the missing cache file.

**"Out of sync" (= stale)** means some or all of the generated files listed above do not correctly match the state of the local project instance discoverable files, `env.yml` files, etc. Running `make reinit` ensures the generated files are in sync again after any impacting modification. The `data/asc/cache/core/stamp` file informs wether something has changed and warrants to reinit the local project instance.

#### Always (= eager) VS conditionally (= lazy) sourced includes

Typical ASC use cases aren't complex or "big" *by design*, but its extensibility mechanisms may easily load relatively big amounts of bash code, potentially mostly unused. That is why there are 2 types of automatic scripts sourcing :

1. **Eager** : all the files using the `*.inc.sh` double extension whose filename matches the parent dir name in *active dirs* and *extension points* (e.g. `asc/instance/instance.inc.sh`, `asc/extensions/compose/compose.inc.sh`, etc) are always loaded. They contain functions that are shared in every bootstrapped context.
1. **Lazy** : files using the `*.opt-inc.sh` double extension are conditionally loaded depending on where the ASC bootstrap include is sourced. This convention allows to load less potentially unused code on every bootstrapped context. This *lazy sourcing* is either based on :
    1. an entry point's `$subject` (= script's parent dir name) and `$action` (= script's file name),
    1. or on a cached hook call.

##### Exceptions

`asc/core/utils.inc.sh` acts like a hub file for other, hardcoded, "pivot" opportunist file and dir names and paths. The filesystem path itself may tell a story in a self-explainable way. That is the pursuit and overall idea of the "synonyms - tokens" gap filling in human - agent communication. Generally, there are no other rules other that what is set in stone in this exclusively human-written root README file of the project.

That is an invitation to get creative. There's a lot of space to explore. This is fundamentally a fun garage project.

`asc/core/utils/` is not a caller dir and has no `*.hook.sh`, so a `*.opt-inc.sh` there is never auto-derived; callers must `.` it.

##### Recap

Here are a few examples to illustrate how this works :

| Bootstrapping context | Type | File | Sourced | Why |
|-----------------------|------|------|---------|-----|
| (any) | eager | `asc/host/host.inc.sh` | ✅ yes | `asc/host` is an *active dir* and `host.inc.sh` matches its name |
| (any) | eager | `asc/extensions/compose/compose.inc.sh` | ✅ yes | `asc/extensions/compose` is an *extension point* and `compose.inc.sh` matches its name |
| (any) | eager | `asc/core/utils/fs.manual-inc.sh` | ✅ yes | The hardcoded kernel "hub" include file `utils.manual-inc.sh` always includes it ; it is not "autoloaded". |
| (any) | manual | `asc/core/utils/fs_compression.manual-inc.sh` | ❌ not unless a caller manually sources it | not a name match, not caller-dir |
| `make db-sync-to` | subject-lazy | `asc/extensions/remote_instance/db/db.opt-inc.sh` | ✅ yes | Caller dir `db/` → 2-level `$subject` `db`. |
| `make git-write-hooks` | subject-lazy | `asc/extensions/remote_instance/db/db.opt-inc.sh` | ❌ no | Wrong caller. Caller opt-inc only looks next to `BASH_SOURCE[1]`. |

### Project instance (re)initialization process

This is the detailed overview of the transitions between the following states that determine the bootstrap context discussed above :

- initial : **cold**
- initialized : **warm**
- out of sync : **stale**

#### Cold → Warm : the initialization process

This describes what happens during the (instance) **init** = `make init` action is triggered, which also get called during (instance) **setup** = `make setup`.

The "warming" process runs the following operations in that order :

1. generate `data/asc/cache/core/active.sh` and `data/asc/cache/core/stamp` : discovered **enabled** *extensions* and *active dirs* (before `globals.sh` exists),
1. generate `data/asc/globals.sh` : discovered readonly global env vars (declared in files like `env.yml` and `global.vars.sh`),
1. generate `data/asc/pivots.mk` and `data/asc/cache/pivots.sh` : discovered entry points (= actions) mapped as `make` entries,
1. call `hook -p 'pre' -a 'init'` (*any* subject can implement that hook)
1. call `hook -a 'init' -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'` (*any* subject can implement that hook)
1. call `hook -s "$subjects instance" -a 'ensure_dirs_exist'` : this is specifically designed to allow extensions create any dirs that are gitignored but required for applications in the local project instance stack to function
1. call `f_instance_set_permissions` reinitializes all project instance files permissions
1. `hook -p 'post' -a 'init'` : includes the generation of a bunch of hardcoded pre-warmed `data/asc/cache/hook/*.sh` cache files.

#### Stale → Warm : drift re-alignment

Short answer : run `make reinit`.

Specific individual steps may be separately run :

- TODO only reinit env vars
- TODO only rebuild hook cache

Some convenience entry points exist for tasks that usually run together, like `make rere` = `make reinit` then `make restart`.

#### (any state) → Cold

This one is the easiest : just run `make uninit` and all the volatile (generated) files and dirs are gone.

#### Interdependence

TODO document chicken and egg problems like `asc/instance/switch_stack_version.sh` (why it exists)

### Extension Point

An **extension point** (noted "ext.point" in the *File structure* section, or `$extension`, or just `$ext`) designates folders containing *active dir(s)* (see below). It's possible to exclude some sub-folders from the detection mechanism (during *(re)init*) using `.asc_subjects_ignore` files, which are essentially `.gitignore` files for ASC discovery.

&lt;proposal-2026-09-22&gt;

`.asc_subjects_ignore` = names that must **not** become subjects. Do **not** add `$subject/.asc_extensions` (positive nest list never loaded; superseded by `$subject/$object/$action`). See [22-deprecate-subject-asc-extensions.md](docs/plans/2026/09/22-deprecate-subject-asc-extensions.md).

&lt;/proposal-2026-09-22&gt;

**List of extension points** (lookup order, Core → Extension → Specifics) :

1. `./asc` — Core
1. `./asc/extensions/$extension` (ex: `asc/extensions/compose`) — Core, opt-in
1. `./scripts/asc/contrib/asc/$extension` (ex: `scripts/asc/contrib/asc/tesseract`) — Extension
1. `./scripts/asc/contrib/$vendor/$extension` — Extension
1. `./scripts/asc/extend` — Specifics

### Active Dir

An *active dir* is a folder where files following the naming conventions below allow things like :

- auto (= eager = files using the `*.inc.sh` double extension), or lazy (= files using the `*.opt-inc.sh` double extension) loading (= sourcing) of bash shell script includes in ASC-bootstrapped contexts,
- global env vars definitions,
- hook implementations (with variants), including yaml files, python scripts, etc.

These folders are automatically discovered during instance init (and setup). The implementations they contain depend on things like :

- which **extensions** are enabled (using `.gitignore`-like declarations, see `.asc_subjects_ignore` files),
- which **env vars values** are set,
- which **lookup** rung (= "specificity level") the contained implementations have - this determines conflicted "winners",
- and whether they relate to a `$subject` or an `$object` (by subject) given the **entry point** (= `$action`) used.

So, in essence :

> an *active dir* is any `$subject` dir (core, enabled extension, or project-specific).

NB : an additional `$object` subdir may be used for regrouping actions (see _actions_).

**List of active dirs** in lookup order (= most "generic" to most "specific"), i.e. roughly Core → Contrib → Project-specific :

| Rung (~ "specificity level") | Active dir | Example | Meant for |
|------------------------------|------------|---------|-----------|
| 0 | `./asc/$subject/` | `asc/host` | core, low-level, "kernel" |
| 0 (bis) | `./asc/extensions/$extension/$subject/` | `asc/extensions/compose/service` | opt-in core "low-level" generic extensions, "abstract" entry points (= pivots) |
| 1 | `./scripts/asc/contrib/asc/$extension/$subject/` | `scripts/asc/contrib/asc/tesseract/recognize` | opt-in core "concrete", (vendor-, software-, tool-)specific extensions |
| 2 | `./scripts/asc/contrib/$vendor/$extension/$subject/` | (no example yet) | reusable implementations, potentially third-party (contributed) |
| 3 | `./scripts/asc/extend/$subject/` | (this is the ASC "mother" repo, so no project-specific example here) | Project-specific implementations |
| 4 | `./` (project root dir) | `env.yml` | Current project "root" dir is where really prominent things / high impact implementations live (i.e. files like .gitignore, .env, compose.yml, etc.) |

NB : the level 4 rung is not a real active dir, but it is included in the same scale because it can contain some hooks implementations (when the hook call uses the `-r` argument).

### Actions = (make) _Entry points_

ASC actions are any shell scripts placed in *active dirs* with a file name :

- using the `*.sh` extension
- not beginning with a dot
- not using any double extension

There are 2 nesting levels supported for *entry points* (or *actions*) :

- `$subject` / `$action` (ex: `service-run` → `asc/extensions/compose/service/run.sh`)
- `$subject` / `$object` / `$action` (ex: `host-dependency-install` → `asc/host/dependency/install.sh`)

Note that `$object` dirs do not support hook implementations. They are a convenience extra nesting level for grouping *actions* only, otherwise the possible lookup paths list for hooks could get too big.

### Environment variables (*env vars*)

_Env vars_ are (Bash) shell variables containing values that are either :

1. **readonly globals** declared using the `global` bash function that ASC provides, see `asc/core/global.opt-inc.sh` (generated readonly *constants*) ;
1. or **calling-scope mutables** - as in any "normal" shell script.

They aren't the same thing as variables only used inside the scope of a bash function. In these cases, they must be declared as `local` variables, and they must follow the naming conventions detailed below.

On init, *globals* are written to:

- `.env` — Makefile and other tools (like Docker compose)
- `data/asc/globals.sh` — sourced every bootstrap

Mutables (`DB_*`, `REMOTE_INSTANCE_*`, …) are **not** written by `u_global_write`; hooks/loaders set them mid-run.

#### Declaring globals (= constants)

There are 2 ways to customize or add globals :

1. by editing `env.yml` configuration files. Various names can be used so later lookup files **replace** values between instance types, and the YAML syntax is then transformed into globals declarations (and/or `f_instance_init()` arguments). You can see an example file in this repo's docroot : `SPECIMEN.env.yml`, which you can rename to `env.yml` (or `.env-local.yml`) to quickly get started.
1. by providing `global.vars.sh` file(s) in active dirs.

The `env.yml` method is meant for simple declarations, while `global.vars.sh` allow things like deferred and/or conditional assignments, dynamic values, and plain bash scripting.

Here's the list of `env.yml` variants lookup paths available for later files to replace values if needed :

```text
env.$INSTANCE_TYPE.yml
env.$STACK_VERSION.yml
env.$HOST_TYPE.$INSTANCE_TYPE.yml
env.$STACK_VERSION.$HOST_TYPE.yml
env.$STACK_VERSION.$INSTANCE_TYPE.yml
env.$STACK_VERSION.$HOST_TYPE.$INSTANCE_TYPE.yml
```

In the list above, in case of collision, the last file "wins". Ex :

- `env.yml` declares `STACK_VERSION='foobar-2025'`
- `env.local.dev.yml` declares `STACK_VERSION='foobar-2026'`

Result : any "local dev" project instance gets the `foobar-2026` stack. The rest (e.g. `remote` instances, or `prod` local instances, etc.) still stay on the `foobar-2025` stack.

Switching between stack versions has its own little convenience script, usually followed by an "instance rebuild" action :

```sh
make switch-stack-version 'foobar-2025'
make rebuild
# Or :
asc/instance/switch_stack_version.sh 'foobar-2025'
asc/instance/rebuild.sh
```

#### Interactive terminal prompts during (instance) init

By default, when "instance init" runs (= `make init` = `asc/instance/init.sh`, also called during `reinit`), if the `-y` flag is not used, every global will trigger a terminal prompt (i.e. `read`) in order to manually input or confirm the default value.

If all you need is a constant, the following syntax will not prompt for user input in terminal during *instance init* :

```sh
global MY_CONSTANT_VALUE "the value"
```

The same declaration using the `env.yml` method can be done in the following *strictly equivalent* ways :

```yaml
my:
  constant:
    value: the value
```

```yaml
my_constant:
  value: the value
```

```yaml
my_constant_value: the value
```

And if you need to always prompt for input during *instance init* (when the `-y` flag is not set), use only the 1st argument :

```sh
global MUST_INPUT_ON_INIT
```

See `asc/core/global.manual-inc.sh` for details about the `global()` function, but we'll mention here one of its most commonly useful feature : the ability to append values on each call with the same var name, which will be separated by a space (and can be placed in different files because they will share the same namespace during *instance init*), e.g. :

```sh
global VALUES_WILL_CONCAT "[append]=path/to/file-1.txt"
global VALUES_WILL_CONCAT "[append]=path/to/file-2.txt"
global VALUES_WILL_CONCAT "[append]=path/to/file-3.txt"
global VALUES_WILL_CONCAT "[append]='(if value has space or special characters, use enclosing single quotes)'"

# Example usage elsewhere, once "instance init" has run :
for value in $VALUES_WILL_CONCAT; do
  echo "$value"
done
```

To show where the declarations can be placed in order to get picked up for aggregation - and in which order - during *instance init* in current project instance, you can use the following convenience command :

```sh
make globals-lp
# Or :
asc/core/global_lookup_paths.make.sh
```

Note that if the above helper is run **after** *instance init*, more variants will appear for `env.yml` files, as the lookup paths themselves may depend on things like enabled extensions and env vars values.

The declarations found in `env.yml` take precedence over `global.vars.sh`, as they get loaded last during the aggregation process.

#### Git-ignored, "private" _globals_

If you need local, "private" *readonly* values that must NOT be checked out in any git repo, the following file can be used : `.env-local.yml` (same as `env.yml` but with a single dot prefix).

If needed, additional lookup paths are available in order to replace values in the same way as for the `env.yml` file :

```txt
.env-local.$HOST_TYPE.yml
.env-local.$INSTANCE_TYPE.yml
.env-local.$STACK_VERSION.yml
.env-local.$HOST_TYPE.$INSTANCE_TYPE.yml
.env-local.$STACK_VERSION.$HOST_TYPE.yml
.env-local.$STACK_VERSION.$INSTANCE_TYPE.yml
.env-local.$STACK_VERSION.$HOST_TYPE.$INSTANCE_TYPE.yml
```

### Hooks (and variants)

The `hook` function triggers an "event", optionally filtered by **subject(s)**, **action(s)**, **prefix**, and **variant(s)**. It will source all file located in active dirs that match its arguments.

Variants are **combinatory**. They can be *any bash variable* present in the calling scope.

For example, when `PROVISION_USING='compose'` and `INSTANCE_TYPE='dev'`, calling :

```sh
hook -s 'my_subject' -a 'my_action' -v 'PROVISION_USING INSTANCE_TYPE'
```
... will source all of the following bash script files (any that exists) in any *extension point*, here noted `*` :

- `*/my_subject/my_action.hook.sh`
- `*/my_subject/my_action.compose.hook.sh`
- `*/my_subject/my_action.compose.dev.hook.sh`
- `*/my_subject/my_action.dev.hook.sh`

The paths above are all relative to active dirs.

Also note that each argument (except *prefix*) accepts several values by using a space to separate them. E.g. :

```sh
hook -s 'stack service instance app' -a 'start'
```

NB : there is a cache warmup that runs after every "instance init" action, where a bunch of hooks get dry-run in order to pre-generate some usual hook calls in cache. See `asc/instance/post_init.hook.sh`

Here are a few examples. All paths are relative to active dirs, noted `*` below :

```sh
# 1. Providing a single action :
# (given INSTANCE_TYPE='prod')
hook -a 'bootstrap'
# Yields the following lookup paths (ALL includes found are sourced) :
# - */$subject/bootstrap.hook.sh
# - */$subject/bootstrap.prod.hook.sh

# 2. When providing an action + a filter by subject :
# (given INSTANCE_TYPE='prod')
hook -s 'stack' -a 'init'
# Yields the following lookup paths (ALL includes found are sourced) :
# - */stack/init.hook.sh
# - */stack/init.prod.hook.sh

# 3. When providing an action + a filter by 1 or several subjects + 1 or several
# variants filter :
# (given INSTANCE_TYPE='dev' and HOST_TYPE='local')
hook -s 'stack' -a 'init' -v 'HOST_TYPE INSTANCE_TYPE'
# Yields the following lookup paths (ALL includes found are sourced) :
# - */stack/init.hook.sh
# - */stack/init.local.hook.sh
# - */stack/init.local.dev.hook.sh
# - */stack/init.dev.hook.sh

# 4. Extensions filter (-e) :
# (given INSTANCE_TYPE='prod')
hook -e 'foobar' -a 'toto'
# Yields the following lookup paths (ALL includes found are sourced) :
# - asc/extensions/foobar/$subject/toto.hook.sh
# - asc/extensions/foobar/$subject/toto.prod.hook.sh
# - scripts/extensions/asc/foobar/$subject/toto.hook.sh
# - scripts/extensions/asc/foobar/$subject/toto.prod.hook.sh
# - scripts/extensions/contrib/foobar/$subject/toto.hook.sh
# - scripts/extensions/contrib/foobar/$subject/toto.prod.hook.sh

# 5. Prefixes filter (-p) are exclusive by default, which means pure actions are
#   not included. Ex :
# (given INSTANCE_TYPE='prod')
hook -a 'bootstrap' -p 'pre'
# Yields the following lookup paths (ALL includes found are sourced) :
# - */$subject/pre_bootstrap.hook.sh
# - */$subject/pre_bootstrap.prod.hook.sh

# 6. Project root dir additional lookup (-r) with custom extension filter (-c) :
# (given HOST_TYPE='local' and INSTANCE_TYPE='dev')
hook -s 'instance' -a 'env' -c 'yml' -v 'HOST_TYPE INSTANCE_TYPE' -t -r
# Yields the following lookup paths (not sourcing matches because -t flag) :
# - */instance/env.yml
# - */instance/env.local.yml
# - */instance/env.local.dev.yml
# - */instance/env.dev.yml
# - env.yml
# - env.local.yml
# - env.local.dev.yml
# - env.dev.yml
```

Finally, **semver** suffixes will automatically produce "regressive" lookup paths, for example :

```sh
toto=foobar-1.2.3
make hook-debug s:stack a:service_add v:toto
```

Yields (from fewer to more variant tokens = from least to most "specific") :

- `*/stack/service_add.hook.sh`
- `*/stack/service_add.foobar.hook.sh`
- `*/stack/service_add.foobar-1.hook.sh`
- `*/stack/service_add.foobar-1.2.hook.sh`
- `*/stack/service_add.foobar-1.2.3.hook.sh`

#### Most specific hooks (`hook_ms()`) lookup and collisions

TODO include `hook_ms()` explanation + score-based specificity calculations example.

### Hosts

TODO

### (Projet) Instance(s)

TODO local vs remote

`includes` make possible to reuse blocks of Yaml in the same file like this :

```yml
includes:
  default:
    shell: ash
    tools:
      run: service-run(d1,a)
  front:
    docroot: /var/www/html
    logs: /var/log/apache2
  api:
    docroot: /var/www/api
    logs: /var/log/api
  auth:
    docroot: /opt/keycloak
    logs: /var/log/auth
  index:
    docroot: /opt/search
    logs: /var/log/search

dev:
  site:
    includes: default front
    hostname: www.dev.specimen.home.arpa
  api:
    includes: default api
    hostname: api.dev.specimen.home.arpa
  auth:
    includes: default auth
    hostname: auth.dev.specimen.home.arpa
  search:
    includes: default index
    hostname: search.dev.specimen.home.arpa

prod:
  site:
    includes: default front
    hostname: www.prod.specimen.home.arpa
  api:
    includes: default api
    hostname: api.prod.specimen.home.arpa
  auth:
    includes: default auth
    hostname: auth.prod.specimen.home.arpa
  search:
    includes: default index
    hostname: search.prod.specimen.home.arpa
```

The result is that every place where `includes` is specified, the space-separated list of targeted resusable blocks will be placed in the tree, e.g. :

```yml
dev:
  site:
    includes: default front
    hostname: www.dev.specimen.home.arpa
```

... becomes :

```yml
dev:
  site:
    shell: ash
    tools:
      run: service-run(d1,a)
    docroot: /var/www/html
    logs: /var/log/apache2
    hostname: www.dev.specimen.home.arpa
```

### ASC discovery recap

In the following list, `$ext` means any one of these extension points (paths) :

- the `./asc` dir : core, low-level, "kernel"
- any dir inside `./asc/extensions` : opt-in core "low-level" generic extensions, "abstract" entry points (= pivots)
- any dir inside `./scripts/asc/contrib/asc` : opt-in core "concrete", (vendor-, software-, tool-)specific extensions
- any dir inside `./scripts/asc/contrib/$vendor` : reusable implementations, potentially third-party (contributed)
- and finally, `$ext` can also be the `./scripts/asc/extend` dir itself (Project-specific implementations)

The following naming conventions will get automatically discovered :

- ✅ `$ext/$subject/$action.sh` = (action) script = entry point = pivot
- ✅ `$ext/$subject/$object/$action.sh` = entry points = pivots *regrouped* (by object)
- ✅ `$ext/$subject/global.vars.sh` = constants declarations
- ✅ `$ext/$subject/*.hook.sh` = (default) hook implementations

But not :

- ❌ `$ext/$subject/$object/global.vars.sh`
- ❌ `$ext/$subject/$object/*.hook.sh`

Also, there are cases where hook calls may specify any file extensions, like :

```sh
hook_ms 'dry-run' -s 'stack' -a 'compose' -c 'yml' -v 'DC_YML_VARIANTS' -t
hook_ms 'dry-run' -s 'stack' -a 'compose.override' -c 'yml' -v 'DC_YML_VARIANTS' -t
```

... which would discover the most-specific match among files like :

- `$ext/stack/compose.yml`
- `$ext/stack/compose.override.local.dev.yml`
- etc.

### Tests

ASC tests are integrated in levels :

- entry point (level 0)
- test batch (level 1)
- test suite (level 2)
- test case (level 3)
- assertions (level 4)

#### ASC core tests

ASC core provides its own coverage, see :

- level 0 (*entry point*) = `asc/test/core.sh` : defines the `test-core` entry point, which triggers a hook so that other extensions may implement their own low-level ASC tests - i.e. `hook -s 'test' -a 'core' -v 'PROVISION_USING HOST_TYPE HOST_OS'`
- level 1 (*batch*) = `f_test_batch_exec 'asc/test/core'` in `asc/test/core.hook.sh` : ASC core itself implements its own hook to run default low-level tests
- level 2 (*suite*) = e.g. `asc/test/core/bootstrap.test.sh` : a test suite is a file named like `$suite.test.sh` in the dir passed as argument to the `f_test_batch_exec()` function
- level 3 (*case*) = e.g. `test_asc_has_essential_globals()` in `asc/test/core/bootstrap.test.sh` : a single test case is a function named like `test_$case()`
- level 4 (*assertion*) = individual calls to shunit2 functions like `assertFalse()` or `assertTrue()` inside test case functions (see `asc/vendor/shunit2/shunit2`)

#### Pre and post test suite execution (shunit2) functions

Test suites can implement the following special functions picked up by shunit2 :

```sh
oneTimeSetUp() {
  # This runs ONCE before any test starts.
}
```

```sh
oneTimeTearDown() {
  # Only when teardown is needed (purge, cleanup). Omit if empty.
}
```

See the embedded vendor [shunit2 README](asc/vendor/shunit2/README.md) for additional details.

#### Test results

Tests results are (for now) stored in `data/test/result`. This was done to track the current status of unstable branches in git, but the decision is subject to eventually change according to future enhancements to workflow-related implementations.

### ASC domain-specific language : *DSL* syntax

TODO rewrite DSL intro.

#### Entry points

As in `make`. Ex :

- `start` = `make start` = `asc/instance/start.sh`
- `service-rebuild` = `make service-rebuild` = `asc/extensions/compose/service/rebuild.sh`
- etc.

&lt;proposal-2026-11-18&gt;

`asc/dsl.sh` and the hardcoded `make ds` target reach the `f_asc_dsl` stub.
The proposed direct interface is `asc/dsl.sh '<expression>'`. Make expands
its goals into a shell recipe, so the supported Make quoting and argument
rules still need verification. See the [DSL spec](docs/specs/asc/dsl.md).

&lt;/proposal-2026-11-18&gt;

&lt;proposal-2026-11-19&gt;

Direct calls use `asc/dsl.sh '<expression>'` (and in-process `f_asc_dsl`).
The Make carrier is `ASC_DS_EXPR='<expression>' make ds` — the expression is
never a Make goal. See the [DSL spec](docs/specs/asc/dsl.md).

&lt;/proposal-2026-11-19&gt;

#### Arguments

Arguments are specified using `()` and are separated by `,` :

- `test-in(foobar,bar,baz)` -> `asc/test/in.sh 'foobar' 'bar' 'baz'`

Special characters are usually forbidden, but the DSL supports the following custom substitutions :

- if you need to pass the wildcard character `*`, use `%` in the DSL syntax
- Same for `**` : use `%%`

**Positional arguments :**

- `a` = `$@` (all arguments are forwarded "as is")
- `s1` = all arguments are forwarded "as is" after shifting 1 argument
- `s2` = all arguments are forwarded "as is" after shifting 2 arguments, etc.
- `p1` = `$1`
- `p2` = `$2`
- etc.

&lt;proposal-2026-11-18&gt;

The proposed caller binds its argv with
`f_asc_dsl '<expression>' -- "$@"`. `slug(p1)` uses the first bound value
and `slug('p1')` uses the literal string `p1`.

&lt;/proposal-2026-11-18&gt;

**Boolean options :** (shrink all `--` to `-` in prefixed syntax)

- `b-y` = `-y` = any boolean option prefixed by a single `-`
- `bb-oneline` = `--oneline` = any boolean option prefixed by a double `--`
- `ba` = all boolean options prefixed by a single `-` are forwarded - and ONLY those boolean options
- `bba` = all boolean options prefixed by a double `--` are forwarded - and ONLY those boolean options

**Named options :**

- `o-m-4` = `-m 4` = any named option prefixed by a single `-`
- `oo-max-4` = `--max 4` = any named option prefixed by a double `--`
- `o-max~4` = `-max=4` = any named option prefixed by a single `-` with an `=` sign before the value
- `oo-max~4` = `--max=4` = any named option prefixed by a double `--` with an `=` sign before the value
- `oa` = all named options prefixed by a single `-` are forwarded - and ONLY those named options
- `ooa` = all named options prefixed by a double `--` are forwarded - and ONLY those named options

&lt;proposal-2026-11-19&gt;

**Supersedes** the hyphen-attached Named options sketches above (`o-m-4`,
`oo-max-4`, `oe-max-4`, `ooe-max-4`). Prefer comma-separated literals already
in the grammar, e.g. `pivot(-m,4)` → `-m` then `4`, and `pivot(--max,4)` →
`--max` then `4`. For a single attached `name=value` argv entry, require
`~`: `oe-max~4` → `-max=4`, `ooe-max~4` → `--max=4`, `ooe-output-file~` →
`--output-file=`. Split on the first `~`; empty values and later tildes in
the value are allowed; the value part is literal (`p1` / `%` not expanded
there). Commas separate DSL argument expressions only; space-separated forms
such as `pivot(-q file)` are not accepted. Program text must not contain raw
`=` (including in quotes); pass `=` via bindings or via `~`-generated argv.
Full contract:
[Argument separators and attached option values](docs/specs/asc/dsl.md#argument-separators-and-attached-option-values-proposed-contract)
and [Raw equals character ban](docs/specs/asc/dsl.md#raw-equals-character-ban-proposed-contract).
The current parser still rejects `~` until an options slice lands.

&lt;/proposal-2026-11-19&gt;

#### Variables

**Any bash var in (hook) calling scope :**

Using the `v-` prefix :

- `v-input_file_path` = whatever value the `$input_file_path` bash variable has e.g. in a `hook()` calling scope.

This is useful for the example mentionned below : `*/$subject/transcribe-file(v-input_file_path).pre-index.hook.sh`

#### Functions

**Any (whitelisted) bash function :**

Using `[]` enclosure :

- `[echo(a)]` = calls `echo "$@"`
- `[f_db_clear(foobar)]` = calls `f_db_clear 'foobar'`
- `[f_db_clear(v-DB_NAME)]` = calls `f_db_clear "$DB_NAME"`

The DSL uses subshells for nested cases like `[f_db_clear([slug(p1)])]` :

```sh
f_db_clear "$(slug 'foobar')"
```

&lt;proposal-2026-11-18&gt;

`[f_db_clear(slug(p1))]` shows a listed function receiving stdout from
the `slug` pivot as one argument. The [draft DSL spec](docs/specs/asc/dsl.md#nested-calls-proposed)
covers nested failures and the open function list.

&lt;/proposal-2026-11-18&gt;

#### Chaining

- `[echo(v-baz)];echo(foobar)` = calls `echo "$baz" ; echo 'foobar'`
- `[echo(v-baz)];;echo(foobar)` = calls `echo "$baz" && echo 'foobar'`

&lt;proposal-2026-11-18&gt;

Each listed function or builtin call carries brackets, as in
`[echo(v-baz)];[echo(foobar)]`. Bare call names resolve ASC pivots.

&lt;/proposal-2026-11-18&gt;

#### Parallel

- `[echo(v-baz)]-;-echo(foobar)` = calls `echo "$baz" & echo 'foobar' ; wait`

#### Piping

- `[echo(v-baz)]+grep(foobar)` = calls `echo "$baz" | grep 'foobar'`

#### Conditional execution

- `[echo(v-baz)]++[exit(1)]` = calls `echo "$baz" || exit 1`

&lt;proposal-2026-11-18&gt;

`++` runs a fallback on failure. Use a pivot or a listed function as the
fallback. The interpreter returns status to the embedding, which can
then exit or run cleanup.

&lt;/proposal-2026-11-18&gt;

#### Redirecting

- `[echo(v-baz)]--v-output_file_path` = calls `echo "$baz" > "$output_file_path"`
- `[echo(v-baz)]---v-output_file_path` = calls `echo "$baz" >> "$output_file_path"`

#### Iterations (= loops, foreach, for ... in)

Loop on **array items** :

- `[[echo(v-item)]v-foobar_arr]` yields :

```sh
for item in "${foobar_arr[@]}"; do
  echo "$item"
done
```

Loop on **output lines** (or on anything that can go inside `[]`) :

- `[[echo(v-item)]myfunc]` yields :

```sh
while read -r item; do
  echo "$item"
done < <(myfunc)
```

#### Filename-safety

DSL syntax is filename-safe (Linux, Windows, IOS) in order to allow for simple actions or combinations to be expressed in the filename itself, e.g :

```text
*/$subject/transcribe-file(v-input_file_path).pre-index.hook.sh
```

&lt;proposal-2026-11-18&gt;

The filename example is a proposed hook convention. Its supported grammar
and discovery behavior remain open.

&lt;/proposal-2026-11-18&gt;

#### DSL examples

The authoritative form of expressing one's need is the following :

"In order to achieve X I need: first Task 1, then Task 2, Then e.g. combinations, batch..."

1. Agents skills, or even plans, may be partly or wholly expressed in *.dsl.txt
1. The go game analogy is meant to orient the semantic space strategy in relation to human prose (like domain names, but in occupying names and verbs in this competing space for clever "namespaces"), under this undeerlying question : how is this most eloquently and naively expressed in simple english ?
1. This is where the languages meet : prose and code, pivoted both ways.
1. The preferred words for actions and subjects must be carefully chosen.
1. Puns intended are welcome, if not too heavily.

There may exist guidelines in docs to orient decisions, such as ordering actions by subjects - like (either) :

- `$subject` / `$action`
- `$subject` / `$object` / `$action`

Example :

`db-dump(path/to/foobar.sql.gz)` pivoting to `asc/extensions/db/db/dump.sh`

Above, the path `asc/extensions/db` is the relative DSL "execution context". This could inform sandboxing and general permissions handling.

Other example :

`transcribe-file(path/to/file.mp4)` pivoting to `asc/extensions/transcription/transcribe/file.sh path/to/file.mp4`

Thanks to the magically disappearing `instance` subject (the default subject is the ASC project instance itself, in PROJECT_DOCROOT), you can get minimal things like :

`gen(path/to/foobar.yml)` pivoting to `asc/extensions/builder/instance/gen.sh path/to/foobar.yml`

There are infinite examples of "normal" things like :

`core-sync` pivoting to `asc/core/sync.sh`

In DSL, combinations freely operate :

```txt
report(
  plan-exec(
    plan(
      goal(path/to/foobar.yml)

      idea(path/to/idea-1.md)
      idea(path/to/idea-2.md)
      idea(path/to/idea-3.md)

      need(plan-tests)
      need(plan-skills)
      need(plan-tools)
      need(plan-guardrails)
      need(plan-tasks)

      need(
        decision(
          chat(
            agent-role(reviewer)
            prompt(path/to/foobar.prompt.md)
          )
        )
      )
    )
  )
)
```

Template processing is a good hook implementation opportunity, with any variants
we'd like - take this string for example in hypothetical `path/to/foobar.prompt.md` :

"For the following '{{ subject }}', I need to create a new pivot with variants control for an action : '{{ action }}'."

The prompt itself is a string template, that's why the `prompt` pivot (`asc/extensions/agent/instance/prompt.sh`) exists.

Depending on the selected agent role, it may ultimately produce calls like :

```txt
make model-prompt 'codex' 'gpt-6.1-terra-high' 'worspace-foobar' 'path/to/foobar.prompt.md'
```

The "advertising" of mutable *scoped variables* remains something to be specified.

These may contain hook variants, answering needs such as :

- Does this host (laptop, server) have the necessary software requirements ? (variants : debian, bluefin, pi, synology, tiiny...)
- Are the software requirements met ?
- Is the stack started ?
- Healthchecks ?
- Multiple project instance on the same host (local domains centralized routing) ?
- ASC upstream "mother" repo instanciated on the same host ?
- etc.

This is why the `core-sync` pivot exists (`asc/core/sync.sh`). Here's the crux of it :

```bash
export instance_path="$1"

if [[ -z "$instance_path" ]]; then
  instance_path="$PROJECT_DOCROOT"
fi

if [[ ! -d "$instance_path" ]]; then
  echo >&2
  echo "Error in $BASH_SOURCE line $LINENO: instance path does not exist." >&2
  echo "-> Aborting (1)." >&2
  echo >&2
  exit 1
fi

# Instead of a full, slow "make reinit", target specific diffed trees only.
# "Wireable" as a git hook or anything.
asc/dsl.sh << DSL

ext-sync
cache-sync
data-sync
specs-sync
providers-sync
models-sync
skills-sync
host-sync
remote-hosts-sync
agents-sync
docs-sync
stack-sync

DSL

exit $?
```

### Data dirs = "data pivots"

Files placed in `data/*` are usually writeable per project instance. They are meant for ASC core, contrib and/or custom implementations.

The goal is to preferably aim for mimicking the ASC file structure, swapping the
extension points' relative dirs for `data`.

This applies to both volatile / temporary *and* frozen / deployable filesystem records (or "sidecars"), scoped by ASC project instance by default.

Example :

- Local cache files
- DB dumps
- SQLite / [Turso](https://docs.turso.tech/agentfs/introduction) - like databases
- Doc fixtures
- Doc fonts
- Frozen test results
- Host-level dependencies
- Remote instances bidirectional sync
- etc.

#### ASC data convention

The general guideline is this :

- In the same way actions are scoped by subjects (i.e. `$subject` / `$action`), all data read from and written to the local project instance filesystem must be also scoped by the same "by subject" organizing principle (i.e. `data/$subject`).
- For cases like `$subject` / `$object` / `$action`, it follows : `data/$subject/$object`

Examples :

|  | Extension point | Data pivot | Example |
|--|-----------------|------------|------------|
| Core cache files | `asc/core` | `data/asc/cache` | `data/asc/cache/hook/s-asc.a-bootstrap.v-v1,compose.sh` |
| Doc fixtures | `asc/doc` | `data/doc/fixtures` | `data/doc/fixtures/long-code.pdf` |
| Doc fonts | `asc/doc` | `data/doc/fonts` | `data/doc/fonts/Spectral/Spectral-Medium.ttf` |
| Local Frozen test results | `asc/test` | `data/test/frozen` | `data/test/frozen/local/core/bootstrap.test_asc_autoload_override_works.txt` |
| Remote Frozen test results (ex: `preprod` remote) | `asc/test` | `data/test/frozen` | `data/test/frozen/preprod/core/bootstrap.test_asc_autoload_override_works.txt` |
| Local Test reports | `asc/test` | `data/test/report` | `data/test/report/local/2026/11/21-asc-tests-report.pdf` |
| Remote Test reports (ex: `preprod` remote) | `asc/test` | `data/test/report` | `data/test/report/preprod/2026/11/21-asc-tests-report.pdf` |
| Local host(s) | `asc/host` | `data/host/local` | `data/host/local/foobar.local-domain.home.arpa.yml` |
| Remote host(s) | `asc/extensions/remote/host` | `data/host/remote` | `data/host/remote/foobar.remote-domain.com.yml` |
| Local project instances | `asc/instance` | `data/instance/local` | `data/instance/local/foobar.yml` |
| Remote project instances | `asc/extensions/remote/instance` | `data/instance/remote` | `data/instance/remote/foobar.remote-domain.com/foobar.yml` |

#### Deployable local project instance settings (instance-level + host-level)

TODO document the **sync** process separately and/or just the **spec** here ?

#### ASC cache : `data/asc/cache`

Lookup artifacts only. `make cc` (`asc/core/cache_clear.sh`) deletes `data/asc/cache/` and **must not** delete `data/asc/globals.sh`, `data/asc/pivots.mk`, or `.env`. Those are instance state: `make reinit` rewrites them; `make uninit` wipes them (and the cache).

```text
data/
  asc/
    global.vars.sh              ← instance env (reinit / uninit)
    pivots.mk                   ← Make include (reinit / uninit)
    cache/
      tree/
        graph.txt               ← filtered cached copy of instance filesystem
      core/
        active.sh               ← discovery lists + ASC_INC (stamp-gated)
        stamp                   ← discovery inputs (not hook file bodies)
      hook/
        <canonical-key>.sh   ← hook lookup (bodies still sourced from disk)
      pivots.sh
      test-cases.sh
```

Bootstrap always sources the four kernel includes (`utils.inc.sh`, `core.inc.sh`, `hook.inc.sh`, `autoload.inc.sh`). `yml.inc.sh` is eager via `ASC_INC` (`asc/yml` is an *active dir*). Then, if `global.vars.sh` exists, it is sourced. Then `f_asc_primitives_cache_ensure`: stamp match → source `core/active.sh`; miss → `f_asc_extend`, rewrite `active.sh` + stamp, wipe `cache/hook/` only. `pre_bootstrap` / `alias` / `bootstrap` still run on both the cold and warm paths.

&lt;proposal-2026-09-21&gt;

Kernel four are `utils.manual-inc.sh`, `core.manual-inc.sh`, `hook.manual-inc.sh`, `autoload.manual-inc.sh`. Not on `ASC_INC`. `yml.inc.sh` stays eager via `ASC_INC`.

&lt;/proposal-2026-09-21&gt;


Stamp v1 watches instance identity (`HOST_TYPE`, `INSTANCE_TYPE`, `STACK_VERSION`, selected `.asc_extensions_ignore` path), ignore-file mtimes, and directory mtimes of `asc/`, `asc/extensions/`, `scripts/asc/`, contrib, and extend. A new `*.hook.sh` or `$subject/$action.sh` inside an **existing** folder still needs `make cc` (and `make reinit` when a new Make target is required). Nested-file discovery is v1.1.

Hook cache keys come from **parsed** flags (not `"$@"`): `s`, `a`, `p`, `v`, `e`, `c`, then `t` / `r`. Variant **values** stay in the key. `-d` and `-w` do not. Multi-value lists use comma.

After `make cc`, the next bootstrap is a stamp miss: one `f_asc_extend`, then hook files refill on miss. Make targets and env remain.

See `docs/plans/2026/09/11-bootstrap-cache-layout-and-invalidation.md`.

#### Logs : `data/log`

TODO

- `logged-*` prefix ? (logged-thread, logged-batch...)
- stdout / stderr / both ?

#### Test `data/test`

##### Results `data/test/result`

TODO

##### "Frozen" results `data/test/frozen`

TODO

##### Reports `data/test/report`

TODO

#### Temporary files : `data/tmp`

TODO

## Workflow

ASC provides a minimal, customizable and extensible workflow meant to be implementable by either humans or agents.

The project docroot file `gates.yml` is a `hook_ms()` implementation (like `env.yml`) that contains pointers to current project instance changelog files.

&lt;proposal-2026-09-22&gt;

`hook_ms` returns the live gates file. `SPECIMEN.gates.yml` is the anonymized copy model. This checkout uses `gates.core.yml` when `INSTANCE_TYPE` is `core`.

&lt;/proposal-2026-09-22&gt;

Whenever a human pushes a change to that file, the "next step tasks list" may need to launch new workers.

This is a job for any of those extension points :

- ASC core "agent" extension and contrib provider extensions: the proposed [agent-plan design](docs/ideas/2026/11/10-agent-plan-cursor-codex-ollaya.md) describes the planned chat, readiness, and orchestration entry points and their provider hooks.
- ASC core "rules" extension : next step chains supporting DSL with constant readjustment updates for correct priority queuing based on gates.yml and the "next steps" storage system eventually chosen (either reg-set / reg-get or entities)

TODO settle the "next step tasks list" storage.

&lt;proposal-2026-09-22&gt;

Every local ASC project instance takes upstream updates from the ASC mother project instance. One repo shared by several machines keeps a common branch as the buffer they pull and push. A machine branch is a child of that branch, and that machine pulls the buffer current before it pushes. A change shared by those machines moves up onto the buffer. A change shared by every instance moves up into the mother. Example: the linux home-directory instance, branch `debian-13`.

&lt;/proposal-2026-09-22&gt;

&lt;proposal-2026-09-24&gt;

### Host copies and storage

One host may hold two checkouts of the same repository. The buffer branch is the parent (`debian-<major>` in the home-directory example). A machine branch appends a suffix. Git commits move up through that buffer, then into the ASC mother when every instance should share them. A second pass mirrors named directories between the two work trees, both directions. That pass is not `make core-upgrade`, and it is not written yet.

`asc/host/asc_core_sync.sh` is the entry point aimed at ASC core files (`asc/` and `scripts/asc/contrib/asc/`) between the mother work tree and each instance `asc/instance/discover.sh` lists. The script is still a stub. `docs/plans/2026/09/23-host-asc-core-sync.md` specifies a report and a forward mirror only, and its gates row is not a go. The bidirectional contract needs its own row. Discover is specified in `docs/plans/2026/09/20-host-scan-project-instances.md` and is not on disk. The catalog it will write uses the host registry path above.

Storage is several mechanisms at once. A sidecar contract stores volatile instances as YAML under `data/entities/<type>/`. A store names a backend (directory, registry, or a database). The registry stays one string per key. Entity types, instances, and the planned rules extension share one YAML shape for DSL combinations. Secrets stay in `.env-local.yml` or git-crypt. `docs/plans/2026/09/10-begin-entity-system-with-remote-instances.md` is the entity vocabulary. `docs/plans/2026/09/22-xdg-state-store.md` records the accepted host registry path. Memory stays disabled.

&lt;/proposal-2026-09-24&gt;

### (re)Search

TODO

### Ideas

TODO

### Change(log)s

TODO

### Doubts

In some implementation decisions, several alternatives may have been explored in more or less detail, and the final or current choice sometimes carries some amount of doubt, such as : *"we could have chosen to implement this in the following alternative manner, but we chose this one, and we may eventually revisit our decision depending on future use cases we chose not to pursue at this moment in time"*.

The doubts deserve their own dedicated documentation structure, which is part of ASC standard workfown process.

TODO define basic, simple structure for those docs + references to the other types of documents.

## Naming convention

### File names

In any ASC-active

- Bash shell includes auto-loaded in ASC-bootstrapped contexts use the double extension `*.inc.sh`
- Lazy-loaded bash shell includes use the double extension `*.opt-inc.sh`

### Coding style

- Function names are prefixed by `f_` (exceptions: global, hook, hookms, tpl)
- Variables storing *positional* argument values are prefixed by `p_`
- Variables storing *options* values are prefixed by `o_`
- Variables storing *boolean* options are prefixed by `b_`
- Variables storing *arrays* use the `_arr` suffix
- Variables storing *associative arrays* use the `_dict` suffix

## Usage / Getting started

### Prerequisites

- Bash **4+** (macOS: install a modern bash via Homebrew and set it as your shell if needed)
- Git
- An existing or new project directory
- [optional] Remote host with Bash 4+ over SSH
- [optional] GNU make

Disclaimer: ASC is primarily tested on Debian-based Linux.

### Placement

Two common layouts:

1. Single “monolithic” repo for the whole project
2. Application code in a separate Git repo (default assumption in this repo’s `.gitignore`)

ASC core (`asc/`) may sit inside the app (same docroot), in a parent “dev stack” repo (usual), or elsewhere on the host. App paths are typically declared per `ASC_APPS` entry (e.g. `SITE_DOCROOT`) via `env.yml`. **All** ASC scripts and `make` targets must be run from `$PROJECT_DOCROOT`.

### Step by step

1. Copy this repo’s files into the chosen docroot (or clone and use as the stack root).
2. Review [`.gitignore`](.gitignore) and adapt it.
3. Enable or disable extensions: edit `.asc_extensions_ignore` (delete a line to **enable** that extension).
4. Copy [`SPECIMEN.env.yml`](SPECIMEN.env.yml) → `env.yml` and edit. Settings that **do not vary** much between instance types belong here (stack version, apps, paths). Use gitignored `.env-local.yml` for machine-private instance env.
5. Optionally implement project-specific things under `scripts/asc/extend/` and overrides (= swap) under `scripts/asc/override/`.
6. Run **instance setup**:

```sh
make setup
# Or:
asc/instance/setup.sh
```

Setup runs, in order:

1. **instance init** — write globals (`.env`, `data/asc/globals.sh`), generate `data/asc/pivots.mk`, optional git hooks, caches
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
| 4 | `PROVISION_USING` | `asc` |

Examples:

```sh
make setup
make setup prod
make setup prod remote myproject-2026 compose
```

### Project stack "lifecycle" entry points

This applies to projects using ASC with Docker compose (or any tool(s) sharing the same kind of mechanics).

When we modify anything in the project stack declaration in the currently active STACK_VERSION with services already running, e.g. typically :

- `scripts/asc/extend/stack/compose.foobar-2026.yml`
- `scripts/asc/extend/stack/compose.override.foobar-2026.local.dev.yml`

... then we have to :

```sh
# Shortcut for Reinit + Restart :
make rere
# Or :
asc/instance/rere.sh
```

If we did **not** touch any *env var* value, this will suffice :

```sh
make compose-update
# Or :
asc/extensions/docker-compose/compose/update.sh
```

In both cases, this will re-generate the (git-ignored) files in PROJECT_DOCROOT that `docker compose` will use :

- `compose.yml`
- `compose.override.yml`

... and restart the whole stack immediately.

Finally, if on or more custom `Dockerfile` was modified, then the `rebuild` action is required for those changes to take effect (to be run *after* `reinit` if some env var(s) were modified as well) :

```sh
make rebuild
# Or :
asc/instance/rebuild.sh
```

## File structure

```txt
/path/to/my-project/          ← $PROJECT_DOCROOT
  ├── .agents/
  │   └── skills/             ← default, generic ASC rules for agents
  │       ├── asc-author-code/
  │       │   └── SKILL.md
  │       └── ...
  ├── .git
  │   ├── hooks/
  │   │   ├── pre-commit      ← [optional] local instance git ↔ ASC hooks wiring
  │   │   └── ...
  │   └── ...
  ├── app,site,api/ …         ← [optional, nested git repos] application trees (per ASC_APPS / env.yml)
  ├── changelog/              ← [optional] documentation of past or planned modifications
  ├── asc/                    ← [$subject/$action ext.point] ASC core (update = replace folder)
  │   ├── core/               ← low-level, "kernel" functions & utilities
  │   ├── doc/                ← markdown-related functions & markdown to pdf generation
  │   ├── extensions/         ← bundled extensions (opt-in via ignore file)
  │   │   ├── $ext/           ← [$subject/$action ext.point] core asc extension
  │   │   │   ├── .asc_subjects_ignore  ← [$subject/$action ext.point] blacklisted subfolder(s)
  │   │   │   └── ...
  │   │   └── ...
  │   ├── git/                ← git hooks integration + utilities
  │   ├── host/               ← host provision, registry, vitals
  │   ├── instance/           ← core unprefixed entry points (generic init, setup, etc)
  │   ├── log/                ← [wip] TODO refactor in progress
  │   ├── make/               ← default.mk + call_wrap
  │   ├── test/               ← shunit2 low-level tests suite
  │   ├── thread/             ← [wip] TODO refactor in progress
  │   ├── vendor/             ← shunit2, bash-yaml, katex, mermaid js + licenses
  │   ├── .asc_subjects_ignore  ← [$subject/$action ext.point] blacklisted subfolder(s)
  │   ├── escape.sh           ← custom script that escapes args for use in make shortcuts
  │   └── bootstrap.sh        ← sourced in all entry points: loads bash functions and globals
  ├── data/                   ← runtime / generated (mostly gitignored)
  │   ├── asc/                ← [git-ignored] Generated files for this instance
  │   │   ├── cache/          ← core ASC cache files (hooks & autoload-related)
  │   │   ├── registry/       ← [optional] contains keyed "file-based store" values
  │   │   ├── pivots.mk       ← current local instance generated make entry points
  │   │   └── globals.sh      ← current local instance generated (readonly) ENV vars
  │   ├── entities/               ← [optional, git-ignored] default place for logs (see also log-rotate)
  │   ├── logs/               ← [optional, git-ignored] default place for logs (see also log-rotate)
  │   ├── private/            ← [optional, git-ignored] default place for private files
  │   ├── test-results/       ← [optional] frozen (versionned) test results
  │   ├── threads/            ← [optional, git-ignored] default place for storing threads info
  │   ├── tmp/                ← [optional, git-ignored] default place for temporary files
  │   └── ...
  ├── scripts/
  │   └── asc/
  │       ├── contrib/
  │       │   ├── asc/             ← ASC ships its own "contrib" extensions
  │       │   │   └── ...
  │       │   ├── $vendor/         ← yields : $vendor.$ext exclusions patterns in .asc_extensions_ignore
  │       │   │   ├── $ext/            ← [$subject/$action ext.point] contrib asc extension
  │       │   │   │   └── ...
  │       │   │   └── ...
  │       │   └── ...
  │       ├── extend/             ← [$subject/$action ext.point] project-specific implementations
  │       │   ├── instance        ← [optional] active dir allowing unprefixed entry points
  │       │   └── ...
  │       ├── local/              ← [git-ignored] manual debug scripts
  │       └── override/           ← allows to swap "autoloaded" core + contrib includes and/or hooks implementations
  ├── .asc_extensions_ignore      ← lists disabled core and contrib extensions
  ├── .editorconfig               ← coding styles standardization
  ├── .gitignore
  ├── .env                    ← [git-ignored] generated current local instance ENV vars
  ├── .env-local.yml          ← [optional, git-ignored] secret ENV vars (hardcoded)
  ├── .env-local.foobar.yml   ← [optional, git-ignored] conditional (hook-based) secret ENV vars (hardcoded)
  ├── env.yml                 ← this project instance global env vars declaration
  ├── env.foobar.yml          ← [optional] conditional (hook-based) global env vars declaration
  ├── gates.yml               ← [optional, agent-related] this project instance human changelog approvals
  ├── gates.foobar.yml        ← [optional, agent-related] conditional (hook-based) human changelog approvals
  ├── Makefile
  ├── NEXT_STEPS.md
  ├── NEXT_STEPS.foobar.md
  ├── NEXT_STEPS.agent.md
  ├── NEXT_STEPS.agent.foobar.md
  ├── SPECIMEN.env.yml        ← copy to env.yml (and/or more specific variants)
  ├── SPECIMEN.gates.yml      ← [optional] copy to gates.yml (or and/or more specific variants)
  └── ...
```

&lt;proposal-2026-09-22&gt;

This checkout's next-steps files are `NEXT_STEPS.core.md` and `NEXT_STEPS.agent.core.md` (`INSTANCE_TYPE` `core`), same variant lookup as `env.yml`.

&lt;/proposal-2026-09-22&gt;

TODO update missing one-liner explanations in project docroot-level files newly added above.

The canonical path for writing files related to time-recurrent or long processes is :

```txt
data/<data_name>/YYYY/MM/DD/HH.MM.SS.MS.<file_name>.md
```

Ex : `data/event/2026/07/17/11.06.55.1234.drush_cron.md`

The `changelog/` dir tipically contains files like :

```txt
docs/plans/YYYY/MM/DD-<file_name>.md
```

Ex : `changelog/2026/07/17-implement-new-ollama-subject.md`

Generated (do not hand-edit):

- `.env`
- `data/asc/globals.sh`
- `data/asc/pivots.mk`
- `data/asc/cache/*`

## Contributors

Project name, ideas & "rock'n'rôle" : [arhkaos](https://github.com/arhkaos)

## License

Apache License 2.0 (see [LICENSE](LICENSE)).
