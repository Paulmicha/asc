# Agnostic Shell Controller (ASC) 🔤🔠🔡🔢🔣🆒🆓

ASC is not a program; it is the “glue” between programs. It is a generic, customizable, extensible toolbox for a wide range of **local development** tasks, with the ambition to serve humans and agentic systems alike.

It allows to set a common, shared vocabulary for anything interacting with the shell somehow. It provides mechanisms allowing to establish "pivots" that represent actions with varying implementations.

The only job of ASC is to serve as a thin layer that :

- **wraps** calls to other CLIs and/or OS-level operations ;
- **sets** a naming convention that persists despite implementation changes, i.e. the *action* `make transcribe-file -- path/to/file.mp4` will remain identical, even when the program(s) used to do the actual transcribing in a project using ASC do ;
- allows to provide **adaptations** to a variety of contextual *specificities* such as host types (local, remote), OS (debian, alpine, windows, ios, etc), or any other *variants*.

## Overarching goal

Like the Go game, but with (make) entry points, (global) env vars, hooks (variants), wrappers (scripts), metadata (yml), and some generic implementations (opt-in).

***Let's make words matter*** 📚

### Scope

- Thin layer to organize generic (pivot) shell entry points, enforcing a common implementation blueprint for (self-)building by humans and agents alike
- Simple, minimal, self-explanatory
- Delegate as much as possible, but still provide usual, optional (opt-in), generic needs as (overridable) "exemplar" implementation blueprints
- Define things and (implementation) contracts
- Generate simple ASC code from folder or string templates (i.e. `asc/extensions/builder`).

### Non-goals ("out of scope"s)

- code refactoring
- self-organizing abominable all-orchestrating plaform
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
- [Core ASC concepts](#core-asc-concepts)
  - [General notes](#general-notes)
  - [Genericity (scale)](#genericity-scale)
    - [Primordial](#primordial)
    - [Primitives](#primitives)
    - [Core](#core)
    - [Extension](#extension)
      - [Enabling and disabling extensions](#enabling-and-disabling-extensions)
    - [Overrides](#overrides)
    - [Project-specific implementations](#project-specific-implementations)
  - [Bootstrap (ASC-bootstrapped context)](#bootstrap-asc-bootstrapped-context)
  - [Extension Point](#extension-point)
  - [Active Dir](#active-dir)
  - [Specificity and collisions handling](#specificity-and-collisions-handling)
  - [Actions = (make) _Entry points_](#actions-make-entry-points)
  - [Environment variables (*env vars*)](#environment-variables-env-vars)
    - [Declaring _env vars_](#declaring-env-vars)
    - [Interactive terminal prompts during (instance) init](#interactive-terminal-prompts-during-instance-init)
    - [Git-ignored, "private" _globals_](#git-ignored-private-globals)
  - [Hooks (and variants)](#hooks-and-variants)
  - [Wrappers](#wrappers)
  - [Entities](#entities)
    - [Custom Yaml syntax (with collisions)](#custom-yaml-syntax-with-collisions)
      - [Reserved root-level keys](#reserved-root-level-keys)
      - [Special notations](#special-notations)
    - [Definition and storage](#definition-and-storage)
    - [Field vs Prop](#field-vs-prop)
    - [Contracts (= capabilities = abilities = skills ~= SKILL.md blueprints)](#contracts-capabilities-abilities-skills-skillmd-blueprints)
    - [Combination (= inclusion), Overriding (= replacement), Alteration (= merging), Appending (= incrementing)](#combination-inclusion-overriding-replacement-alteration-merging-appending-incrementing)
    - [Reusable Yaml blocks (`includes` : plural)](#reusable-yaml-blocks-includes-plural)
    - [Instanciation ("concrete" entity instances)](#instanciation-concrete-entity-instances)
    - [Linking, adressing (relationships, references)](#linking-adressing-relationships-references)
  - [Tests](#tests)
    - [Organization](#organization)
    - [Pre and post test suite execution (shunit2) functions](#pre-and-post-test-suite-execution-shunit2-functions)
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
    - ["Normal" DSL example](#normal-dsl-example)
    - [DSL in Yaml](#dsl-in-yaml)
  - [Data dirs](#data-dirs)
    - [ASC cache : `data/asc/cache`](#asc-cache-dataasccache)
    - [Default file-based entity storage : `data/entities`](#default-file-based-entity-storage-dataentities)
      - [Queue entities : `data/entities/queue`](#queue-entities-dataentitiesqueue)
      - [Thread entities : `data/entities/thread`](#thread-entities-dataentitiesthread)
    - [Logs : `data/logs`](#logs-datalogs)
    - [Private files : `data/private`](#private-files-dataprivate)
    - [Prompts local archive : `data/prompts`](#prompts-local-archive-dataprompts)
    - [Test results : `data/test-results`](#test-results-datatest-results)
    - [Temporary files : `data/tmp`](#temporary-files-datatmp)
    - [Default file-based agent skills storage : `data/skills`](#default-file-based-agent-skills-storage-dataskills)
- [Workflow](#workflow)
  - [(re)Search](#research)
  - [Ideas](#ideas)
  - [Change(log)s](#changelogs)
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
| **Globals** | Instance env vars from `env.yml` / `global.vars.sh`, written to `.env` + `data/asc/global.vars.sh` |
| **Bootstrap** | `. asc/bootstrap.sh` ; eager `*.inc.sh` vs lazy `*.opt-inc.sh` |
| **Instance init** | Aggregates globals, optional git hooks, generates make shortcuts |
| **Actions** | Folders = subjects, files = actions → `data/asc/generated.mk` |
| **Hooks** | File-based events (e.g. `*.hook.sh`) with variant combinations |

The rest of this README contains a bit more details, hopefully enough to decide wether it fits whatever reason have led your eyes here :)

## Example project (demo / case study)

Here is what I am currently building with it (when I have some free time) :

["_Projet Complexe_", a "second brain" project incorporating agentic task-oriented and knowledge-oriented implementations](data/ideas/2026/08/Projet%20Complexe%202026%20Revival%20(v2)%20-%20ASC,%20Projet%20Complexe%20and%20Projet%20Complexe%20ASC.pdf)

See :

- the corresponding [project-specific ASC (stack) repo](https://github.com/Paulmicha/projet-complexe-asc)
- and [the UI (Tauri app) repo](https://github.com/Paulmicha/projet-complexe)

## Current status of the ASC project

*Massive rewrite* ☢️ to shrink it to bare essentials, rethink things through.

Potential collisions in filesystem :

- `$subject` / `$action`
- `$subject` / `$object` / `$action`

Resolution : agnostic stance. In terms of ASC entity representation, `$subject` may or may not choose to implement that extra level.

Implications : change ASC core current files discovery mechanisms to support both.

1. [ ] Finish describing ASC "core" concepts explicitly
1. [x] ~~Stabilize Naming convention~~
1. [x] ~~Stabilize hooks~~
1. [x] ~~Stabilize DSL~~
1. [ ] Stabilize Yml
1. [ ] Refactor Bootstrap
1. [ ] Stabilize workflow + git flow
1. [ ] Refactor core + core extensions
1. [ ] Refactor tests (switch to nestable entity)
1. [ ] Complete the Builder
1. [ ] Complete the baseline implementations
1. [ ] Implement agents (for now : Ollama and Cursor to test MVP)

## Core ASC concepts

### General notes

Unless explicitly stated, everything always **must** run from `$PROJECT_DOCROOT`, which is the folder where every project instance using ASC is installed locally (on the host used to work on - or run - the project).

In this README, the `$` prefix always means the following :

- `$subject` : any *active dir* folder representing an ASC *subject*.
- `$object` subfolders are almost identical, but they only support `$action` scripts (**not** hook implementations).
- `$action` are (Bash) shell script files placed in *active dirs* or `$object` subfolders.
- `$extension` are folders containing *active dirs* representing **enabled** extensions only.

### Genericity (scale)

1. **Primordial** = the unique Yaml file at the top of the Yaml inclusion chain : `yml.yml` (akin to the very first living cell that existed on earth),
2. **Primitives** = Yaml files defining "low-level" structural stuff (like : which root properties the including Yaml files can use to specify things),
3. **Core** = "generic" implementations that are systematically relevant across all projects using ASC (some of which - the core extensions themselves - are opt-in),
4. **Extensions** = namespaced bundles of actions by subjects and/or objects (including contrib, as in the Drupal ecosystem),
5. **Overrides** = alterations of implementations provided by core and/or extensions,
6. **Specifics** = impementations with low or no potential for reuse outside the current projet ASC is used for.

#### Primordial

The **primordial** file just defines basic synonyms. They are interchangeable words used across all Yaml files.

#### Primitives

**Primitives** include :

- `entity.entity.yml` defining the structure of *entities* (i.e. it specifies, for instance, that every `*.entity.yml` can have the root props `entity`, `required`, `optional`) ;
- `able.able.yml` defining the structure of *contracts* (= *skills* or *capabilities*) ;
- and perhaps other use cases may warrant interventions on that level in other projects using ASC (the door remains open).

#### Core

**Core** implementations include :

- Whatever ASC needs to work the way it does (low-level implementations like globals, shell scripts auto includes, hooks implementations discovery and conflicts resolution, instance and host-related implementations, etc.),
- Wrappers around common shell utilities (threads, logs, cronjobs, etc.),
- Minimal shell-based tests (using `asc/vendor/shunit2`),
- Generic utilities (a few basic shell scripting utilities - arrays, strings, filesystem-related, ssh-related, templating-related, git-related, yml-related - see `asc/vendor/bash-yaml`, etc.),
- A few opt-in extensions :
    - `asc/extensions/agent` : wraps and chains LLMs prompts (with pre- and post- process hooks), and provides generic abstractions to manage things like `SKILL.md` (see [pi](https://github.com/earendil-works/pi)) / `CLAUDE.md` / Cursor rules
    - `asc/extensions/apt` : default Debian-based Linux host-level dependencies operations
    - `asc/extensions/builder` : minimalist ASC "clean" code generator
    - `asc/extensions/compose` : default Docker compose - related implementations
    - `asc/extensions/crontab` : default crontab-related implementations
    - `asc/extensions/db` : generic abstract placeholders (hooks) for database-related operations
    - `asc/extensions/entity` : things like remote instances, databases, etc. all share some amount of expectations in terms of operations, prerequisites, etc. That's what the "entity" extension attempts to provide : a standard way to specify such things (in Yaml) in all projects using ASC.
    - `asc/extensions/file_registry` : minimalist local file-based key/value store (supports host-level and instance-level scopes)
    - `asc/extensions/interaction` : generic abstract placeholders (hooks) for interaction-related operations (like triggering input devices actions - e.g. mouse, keyboard, touch events, etc.)
    - `asc/extensions/memory` : generic abstract placeholders (hooks) for memory-related operations (like : find out if and where something is stored, using which storage, etc.)
    - `asc/extensions/nested_git`, `nested_host`, `nested_instance` : default implementations related to sub-git work trees (nested git clones), virtual machines (nested hosts), or even nested ASC project instances
    - `asc/extensions/remote` : default implementations related to remote communication (ssh, etc)
    - `asc/extensions/remote_instance` : implementations related to remote ASC project instances
    - `asc/extensions/rules` : generic abstract placeholders (hooks) for implementing conditionally executed actions based on occurring events (known as reactive or ECA rules)
    - `asc/extensions/software` : default implementations for managing software - usually dependencies, i.e. : updates, configuration, (un)installation, etc.
    - `asc/extensions/workflow` : default implementations for streamlining work processes, kinda like a minimalist and simpler implementation of [superpowers](https://github.com/obra/superpowers) for projects using ASC (complements the `rules` extension)

#### Extension

An **extension** is any folder in the following list (from **most generic** to **most specific**) :

1. `./asc/extensions`
1. `./scripts/asc/contrib/asc`
1. `./scripts/asc/contrib/$vendor`

The default extensions provided by the main ASC repo are all *disabled* by default, except for `asc/extensions/file_registry`.

##### Enabling and disabling extensions

> Create or edit `scripts/asc/override/.asc_extensions_ignore`.

Like the `.asc_subjects_ignore` files, it essentially acts like `.gitignore` files for the ASC discovery mechanism. See :

- `asc/extensions/.asc_extensions_ignore` for the ASC core extensions disabled by default,
- and `scripts/asc/contrib/.asc_extensions_ignore` for the ASC contrib extensions disabled by default.

#### Overrides

In ASC, during *bootstrap* (see below), any Bash shell script include can be swapped by your own altered copy if needed.

If the "counterpart" of a given script exists in the folder `scripts/asc/override`, it will be used instead of the original file.

This allows to replace any includes or hook implementations.

Example : if we want to override `asc/git/init.hook.sh` - effectively *bypassing* the existing default implementation provided by the ASC main repo, we'll create the following file : `scripts/asc/override/git/init.hook.sh`.

The matching is done by by replacing the leading `asc/` or `scripts/asc/contrib/` in filepaths with `scripts/asc/override/`. It works on extensions too.

Here's another example to illustrate overriding a Bash shell script include :

- `asc/extensions/docker-compose/docker-compose.inc.sh` → `scripts/asc/override/extensions/docker-compose/docker-compose.inc.sh`

#### Project-specific implementations

They are custom *active dirs* placed in `./scripts/asc/extend` to be implemented per project. This is where anything that isn't generic and/or isn't meant for public release must live.

### Bootstrap (ASC-bootstrapped context)

A *bootstrapped* context is any shell context that has sourced `asc/bootstrap.sh`.

Sourcing the ASC bootstrap file loads *env vars* and Bash functions in the current *shell scope*, depending on "auto" (= "eager" = files using the `*.inc.sh` double extension), or "lazy" (= files using the `*.opt-inc.sh` double extension) loading of Bash shell script includes *corresponding to the entry point used*.

There are 2 kinds of bootstrapped contexts :

1. when a project instance is not initialized yet (i.e. before `make init` = `asc/instance/init.sh`, also called during `reinit` and/or `setup` has run),
1. and after initialization has run (usually once in a local project instance).

See *Usage / Getting started* for *(re)init* and/or *setup* details.

### Extension Point

An **extension point** (noted "ext.point" in the *File structure* section) designates folders containing *active dir(s)* (see below). It's possible to exclude some sub-folders from the detection mechanism (during *(re)init*) using `.asc_subjects_ignore` files, which are essentially `.gitignore` files for ASC discovery.

**List of extension points** (containing implementations from **most generic** to **most specific**) :

1. `./asc`
1. `./asc/extensions/$extension` (ex: `asc/extensions/compose`)
1. `./scripts/asc/contrib/asc/$extension` (ex: `scripts/asc/contrib/asc/tesseract`)
1. `./scripts/asc/contrib/$vendor/$extension`
1. `./scripts/asc/extend`

### Active Dir

An *active dir* is a folder where files following specific naming conventions allow things like :

- auto (= eager = files using the `*.inc.sh` double extension), or lazy (= files using the `*.opt-inc.sh` double extension) loading of bash shell script includes in ASC-bootstrapped contexts,
- global env vars definitions,
- hook implementations (with variants), including yaml files, python scripts, etc.

These folders are automatically discovered during instance init (and setup). The implementations they contain depend on things like :

- which **extensions** are enabled (using `.gitignore`-like declarations, see `.asc_subjects_ignore` files),
- which **env vars values** are set,
- which **level of genericity** the contained implementations have (this determines conflicted "winners"),
- and wether they relate to a `$subject` or an `$object` (by subject) given the **entry point** (= `$action`) used.

**List of active dirs** (containing implementations from **most generic** to **most specific**) :

1. `./asc/$subject` (ex: `asc/host`)
1. `./asc/extensions/$extension/$subject` (ex: `asc/extensions/compose/service`)
1. `./scripts/asc/contrib/asc/$extension/$subject` (ex: `scripts/asc/contrib/asc/tesseract/recognize`)
1. `./scripts/asc/contrib/$vendor/$extension/$subject`
1. `./scripts/asc/extend/$subject`

So :

> an *active dir* is any `$subject` dir (either in ASC core or in **enabled** extensions).

NB : an additional `$object` subdir may be used for regrouping actions (see _actions_).

### Specificity and collisions handling

The bottom of this list wins when implementing the same `hook_ms()` (i.e. the "most-specific" variant of a hook call that only matches a single file instead of potentially many files), or even in case of a `make $subject-$action` entry point pivot that could potentially have more than one corresponding script :

1. `asc/$subject/*.hook.sh` / `asc/$subject/$action.sh`
1. `asc/$subject/$object/$action.sh`
1. `asc/extensions/$extension/$subject/*.hook.sh` / `asc/extensions/$extension/$subject/$action.sh`
1. `asc/extensions/$extension/$subject/$object/$action.sh`
1. `scripts/asc/contrib/asc/$extension/$subject/*.hook.sh` / `scripts/asc/contrib/asc/$extension/$subject/$action.sh`
1. `scripts/asc/contrib/asc/$extension/$subject/$object/$action.sh`
1. `scripts/asc/contrib/$vendor/$extension/$subject/*.hook.sh` / `scripts/asc/contrib/$vendor/$extension/$subject/$action.sh`
1. `scripts/asc/contrib/$vendor/$extension/$subject/$object/$action.sh`
1. `scripts/asc/extend/$subject/*.hook.sh` / `scripts/asc/extend/$subject/$action.sh`
1. `scripts/asc/extend/$subject/$object/$action.sh`

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

1. **readonly globals** declared using the `global` bash function that ASC provides, see `asc/asc/global.inc.sh` (generated readonly *constants*) ;
1. or **calling-scope mutables** - as in any "normal" shell script.

They aren't the same thing as variables only used inside the scope of a bash function. In these cases, they must be declared as `local` variables, and they must follow the naming conventions detailed below.

On init, *globals* are written to:

- `.env` — Makefile and other tools (like Docker compose)
- `data/asc/global.vars.sh` — sourced every bootstrap

Mutables (`DB_*`, `REMOTE_INSTANCE_*`, …) are **not** written by `u_global_write`; hooks/loaders set them mid-run.

#### Declaring _env vars_

There are 2 ways to customize or add globals :

1. by editing `env.yml` configuration files. Various names can be used to allow overrides between different project instances, and the YAML syntax is then transformed into globals declarations (and/or `f_instance_init()` arguments override). You can see an example file in this repo's docroot : `SPECIMEN.env.yml`, which you can rename to `env.yml` (or `.env-local.yml`) to quickly get started.
1. by providing `global.vars.sh` file(s) in active dirs.

The `env.yml` method is meant for simple declarations, while `global.vars.sh` allow things like deferred and/or conditional assignments, dynamic values, and plain bash scripting.

Here's the list of `env.yml` variants lookup paths available for specifying overrides if needed :

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

Result : any "local dev" project instance gets the `foobar-2026` stack. The rest (e.g. `remote` instances, or `prod` local instances, etc.) still stay on the `foobar-2025` stack 😎.

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

See `asc/utilities/global.sh` for details about the `global()` function, but we'll mention here one of its most commonly useful feature : the ability to append values on each call with the same var name, which will be separated by a space (and can be placed in different files because they will share the same namespace during *instance init*), e.g. :

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
asc/env/global_lookup_paths.make.sh
```

Note that if the above helper is run **after** *instance init*, more variants will appear for `env.yml` files, as the lookup paths themselves may depend on things like enabled extensions and env vars values.

The declarations found in `env.yml` take precedence over `global.vars.sh`, as they get loaded last during the aggregation process.

#### Git-ignored, "private" _globals_

If you need local, "private" *readonly* values that must NOT be checked out in any git repo, the following file can be used : `.env-local.yml` (same as `env.yml` but with a single dot prefix).

If needed, additional lookup paths are available in order to override values in the same way as for the `env.yml` file :

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
... will source all of the following bash script files (any that exists) in any active dir, noted `*` :

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

Yields (from least to most specific) :

- `*/stack/service_add.hook.sh`
- `*/stack/service_add.foobar.hook.sh`
- `*/stack/service_add.foobar-1.hook.sh`
- `*/stack/service_add.foobar-1.2.hook.sh`
- `*/stack/service_add.foobar-1.2.3.hook.sh`

### Wrappers

TODO examples / decide what asc core provides :

1. logged-*
1. thread ("asc-monitored" generic command execution ?)
1. batch (synonym : parallel)
1. chain (synonym : sequence)
1. pipe
1. nested (e.g. remote, ssh tunnel, vpn, p2p ?)
1. stream ?

### Entities

In the context of ASC projects, entities are *manipulable representations of objects* that are *structured* and *combinable*. Because the whole point of ASC is to provide minimalist, thin wrappers around virtually any CLI via entry points (= actions = named pivots), entities can essentially be seen as **specifications** meant to express in a *generic* and *standardized* way :

- **tools calls** (skills - see section *"Contracts (= capabilities = abilities = skills ~= SKILL.md blueprints)"*),
- **discovery** (declaration, detection - see section *"Instanciation ("concrete" entity instances)"*),
- and **targeting** (identity - see section *"Linking, adressing (relationships, references)"*).

In order to explicitly describe how they work and how to use them, we'll take the following objects as examples throughout the explanations below :

- **Host** : represents a local or remote device where a human or agent works (i.e. a laptop, a server, any device usually - but not obligatorily - connected to a network),
- *(project)* **Instance** : represents a single application, workspace, or any bundle of one or more softwares ; usually an ASC project instance (with or without a stack composed by one or more services).

#### Custom Yaml syntax (with collisions)

Same as the `env.yml` files used to define env vars (see  the [environment variables (*env vars*)](#environment-variables-env-vars) section). Those are equivalent notations having the same result :

```yaml
foo:
  bar:
    value: the value
```

```yaml
foo_bar:
  value: the value
```

```yaml
# We could spot and hard fail potentially unintended collisions, but for now :
# No warning - all is merged and potentially lost (in reading order).
foo:
  bar_value: the value
```

```yaml
foo_bar_value: the value
```

##### Reserved root-level keys

For ASC entities and abilities Yaml files (`*.entity.yml` and `*.able.yml`), there are **reserved root-level keys** :

- `include` : loads (= merges) other `*.yml` files into the current file
- `includes` : defines blocks of Yaml that can be reused elsewhere in the same Yaml file
- `synonym` : defines equivalent props and/or fields names
- `required` : this exists to ensure expectations are met (e.g. for entities, this allows to spot incorrect declarations or outdated instances in case of contract or specification changes)
- `optional` : for entities, this allows to list what fields and/or props may optionally be used
- `append` / `alter` / `override` : only applies to entity declarations that include other *contracts* and/or *entity declarations* - i.e. instead of *replacing* a whole root-level property, it either *appends* more values to its inherited parent(s) declaration(s) on the given prop(s) (listed in this `append` root prop), or *alters* (= merges) its sub-props, or only *overrides* (= selectively replaces) one or more targeted sub-props. See the *"Combination (= inclusion), Overriding (= replacement), Alteration (= merging), Appending (= incrementing)"* section below.
- `map` : for entities, defines where specific field value(s) come from - e.g. for for `host` and `remote_host` entities (both sidecar.able entities), it allows to define that the concrete entity file name is the `hostname` value

Aside from those, (almost) anything goes, really. Bear in mind the limitations of the simplified (but sufficient for our use cases here) Bash Yaml parser in use : [`asc/vendor/bash-yaml`](https://github.com/jasperes/bash-yaml)

##### Special notations

For convenience, the following notations are complementing the DSL syntax (see the *"ASC domain-specific language : DSL syntax"* section). These special notations are supported in any ASC entities and abilities Yaml files (`*.entity.yml` and `*.able.yml`), and also in concrete entity instances files (= sidecars) :

| Notation | Example | Result |
|----------|---------|--------|
| `entity.type` | `path/to/foobar.entity.yml` | `foobar` |
| `file.name` | `path/to/foo.bar-baz_123.yml` | `foo.bar-baz_123.yml` |
| `file.path` | `path/to/foo.bar-baz_123.yml` | `path/to` |
| `file.dir` | `path/to/foo.bar-baz_123.yml` | `to` |

Also : `d0`, `d1`, `d2`, etc. = the prop name in current Yaml file at depth 0, 1, 2, etc. of the current branch. Example :

```yml
foo:
  bar:
    tools:
      run: service-run(d1,a)
```

Here, the `run` tool DSL would be pre-processed as `service-run(bar,a)`, and would utlimately yield the following call :

```sh
make service-run 'bar' "$@"
# Equivalent to :
asc/extensions/compose/service/run.sh 'bar' "$@"
```

#### Definition and storage

Entities are defined using a single Yaml file named like `$type.entity.yml` (e.g. the file `host.entity.yml` declares the `host` entity *type*). These declarations can reside in any ASC active dir following the double extension naming convention `*.entity.yml`. Their instances can be stored in file sidecars (placed in `data/entities`) or even use other storage types, like databases (sqlite, postgres, arcadedb, etc.)

Some implementations can dynamically assign an appropriate storage (e.g. file sidecars or database entries) given expected volume (= size) of entity instances.

The file sidecar is one of the many storage method that can be used : see `asc/extensions/memory/store/store.able.yml` for criterias of assignation to different kinds of storage.

#### Field vs Prop

**field** = *values* stored by entity *instances* (*concrete* entities)

--vs--

**prop** = Yaml *keys* shared by all those *instances* + inherited by all (*abstract*) entity *definitions* that include other entities definitions.

- Example of property : `*.entity.yml` all have `required` and `optional` root-level keys ;
- Example of field : the `host` entity has a `hostname` field to store its address (string), defaulting to "localhost".

`field` declarations are either placed inside `required` or `optional` props, and follow a common structure :

- `is` : string (= `str`), integer (= `int`), float, entity (for referencing other entities)
- `unit` (optional) : either a measurable *quantity* like number of characters / words / tokens, weight, size (kg, ko, mb, g, cm, mm, km...), contenance (l), consumption or rate (w/h, tok/s), or a *number of items* (or proportion) for enumerable content (in this case, *unitless*)
- `size` : expected *volume* of field data (and/or *number of items*) to store ; either a range (`$min - $max`), or a single *min* or *max* **limit** (`> $max`, `>= $max`, `< $max`, `<= $max`), or an exact size (the actual unitless value provided)
- `allowed` : optionally defines a fixed list of allowed values
- `validate` : optional DSL string that defines the validation mechanism to run when testing the local project instance
- `default` : the default (fallback) value - for `optional` fields only
- `storage` : references a specific store (sidecar, database...)

Example :

```yml
required:
  field:
    hostname:
      is: string
      size: 1 - 999
      default: localhost
      validate: test-hostname(p1)
```

#### Contracts (= capabilities = abilities = skills ~= SKILL.md blueprints)

Their job is to express how to use the **tools** that are *wrapped* (or "pivoted") in ASC *project instances*. It structures in a standardized way **how to implement** and/or how to *do* things (**tasks**). Those Yaml files essentially point at ASC entry points, DSL, etc.

Let's take the `host` entity as an example. It uses (= loads = includes) the following capabilities :

| Label (designation) | Description | Path |
|---------------------|-------------|------|
| sidecar.able | Means that a local Yaml file can be used to represent a single "concrete" host - e.g. the local host, a dedicated server, a (Docker) container, etc. with any number of custom, specific fields like name, state, OS, etc. | `asc/sidecar/sidecar.able.yml` |
| provision.able | Means that the entity can have installed softwares, drivers, etc. It can be tracked against a manifest to know its state (e.g. : provisionned, missing dependencies, etc.) | `asc/host/provision.able.yml` |
| synchronize.able | This capability definition allows to specify things like : how is this host receiving updates from its upstream git repo (e.g. `post-merge` git hook), etc. | `asc/host/synchronize.able.yml` |
| ssh.able | Means that the entity being represented can be connected to using SSH (details may include : address, port, ssh key, ssh user, etc.) | `asc/host/ssh.able.yml` |
| nest.able | Means that the entity can contain other instances of itself, like : one or more VMs, (Docker) containers, etc. | `asc/host/nest.able.yml` |

The capabilities can include other capabilities, so it is possible to create inheritance chains of contracts - like : shell.able → ssh.able (i.e. `ssh.able.yml` has the `shell.able.yml` item in its `include` root prop list).

Any entity using any of these contracts would inherit the whole chain, e.g. for the `remote_host` entity, the default inclusion chain as implemented in "ASC core" is :

1. *entity.entity* (the primitive entity specification inherited - or shared by - every entities : cf. `asc/extensions/entity/entity/entity.entity.yml`)
1. *able.able* (the primitive ability spec inherited - or shared by - every skill : cf. `asc/extensions/entity/asc/able.able.yml`)
1. **sidecar.able** (the "concrete" *instances* of the *remote_host* entities may be stored locally as Yaml files in `data/entities` : cf. `asc/sidecar/sidecar.able.yml`)
1. **shell.able** (expresses a skill e.g. where a specific tool (here, a terminal) is used to interact with the shell : cf. `asc/host/shell.able.yml`)
1. **ssh.able** (this contract further specifies that the shell of a remote host can be reached using the ssh program : cf. `asc/host/ssh.able.yml`)
1. **host** entity (because a *remote host* is a specific kind of *host* : cf. `asc/host/host.entity.yml`)
1. Then finally, the **remote_host** entity ("self" : cf. `asc/extensions/remote/host/remote_host.entity.yml`)

#### Combination (= inclusion), Overriding (= replacement), Alteration (= merging), Appending (= incrementing)

Nothing forbids the inclusion of any Yaml file. So it is theoretically possible (but not necessarily a good idea) to do things like including concrete entity instances definitions. See the *builder* extension :

- `asc/extensions/builder/template/core/[subject]/[able].able.yml`
- `asc/extensions/builder/template/core/[subject]/[entity].entity.yml`

This system even allows to produce Yaml files that match other specs, such as valid Docker compose files :

- `scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml`
- `scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.override.local.dev.yml`

In fact, the hooks used in the entity instanciation process (= agregation ~= compilation) even make it possible to output other file formats, so the same mechanism makes theoretically possible to produce specs in Toml, Json, JsonL, XML, Html, or even Markdown.

The inclusion is declared like this, e.g. in any `*.entity.yml` or `*.able.yml` :

```yml
include:
  - foo.entity
  - bar.able
```

When a Yaml specification is included, all its props are copied into the current (self) spec. Collisions occur when the same *root* prop(s) is/are present both in the included declaration(s) and in the current definition. There are 3 ways collisions are handled :

1. Any identical root-level prop **gets entirely replaced**, *discarding* whatever was included on that root-level prop ;
1. Specific "per Yaml depth level" sub-props may be targeted :
    1. inside the `override` root-level prop, the *entire* declaration *at that depth level only* get **replaced** ;
    1. inside the `append` root-level prop, those entries get **added** ;
    1. and inside the `merge` root-level prop, they get selectively **altered**.

Here is how the mechanism works  :

1. Define from which entity it is based on, e.g. :
    ```yml
    include:
      - remote_host.entity
    ```
1. Identify the prop you want to inherit only partially or differently, e.g. take the following included declaration :
    ```yml
    required:
      field:
        uuid:
          is: string
          size: 64
        hostname:
          is: string
          size: 1 - 999
          default: localhost
          validate: test-hostname(p1)
    ```
1. Now, either :
    - **Replace** the whole contents of `required` - in the following example : only keep 1 `field` in `required`, effectively **discarding** anything inherited inside the `required` prop *from all of the inclusion chain* :
        ```yml
        required:
          field:
            hostname:
              is: foobar
              size: 3
              default: toto
              validate: test-foobar(p1)
        ```
        Here, the result is : no more `uuid` field at all.
    - Or only **replace** a specific sub-prop on a specific level - in the following example : only override the **level 1** `field` sub-prop (level 0 being the `required` prop) in `required`, meaning **all** the fields are *entirely replaced* by a single `foo` field :
        ```yml
        override:
          d1:
            required:
              field:
                foo:
                  is: bar
        ```
    - Only **replace** the **level 2** `field` sub-prop in `required`, meaning : the `hostname` field declaration is *replaced* (any other inherited `field` items in `required` are *preserved*) :
        ```yml
        override:
          d2:
            required:
              field:
                hostname:
                  is: foobar
                  size: 3
                  default: toto
                  validate: test-foobar(p1)
        ```
        So here, the `uuid` field is left untouched.
    - Now, in this next example, there is no difference between **replacing** and **altering** a single **level 3** property - i.e. those are strictly equivalent declarations :
        ```yml
        override:
          d3:
            required:
              field:
                hostname:
                  size: 1
        ```
        And :
        ```yml
        alter:
          required:
            field:
              hostname:
                size: 1
        ```
        Because the **level 3** `size` sub-prop is targeted, there is no difference between overriding and altering (both change the resulting value at this specific leaf in the Yaml tree).
    - When only **modifications** are needed instead of replacing entire trees, the `alter` root-level prop allows to do many alterations at once without losing any other part of the trees. Unlike `override`, it only overrides specific inherited values in the exact target leaves only - e.g. :
        ```yml
        alter:
          required:
            field:
              hostname:
                default: foobar
                validate: test-hostname-foobar-alternative(p1)
              uuid:
                size: 128
        ```
        Here, both fields inherit all the other sub-props values, and only change those explicitly defined inside the `alter` roo-level prop.
    - Finally, if any list needs incrementing, like adding a new `required` field, we can use the `append` root-level prop :
        ```yml
        append:
          required:
            field:
              foo:
                is: bar
        ```
        Here, the result would have 3 `required` fields : `uuid`, `hostname`, and `foo`.

**Appending** (= *incrementing*) works on the first missing prop on the deepest level of the inherited tree. So, starting from the same previous included Yaml example :

```yml
required:
  field:
    uuid:
      is: string
      size: 64
    hostname:
      is: string
      size: 1 - 999
      default: localhost
      validate: test-hostname(p1)
```

1. If you have :
    ```yml
    append:
      optional:
        field:
          foo:
            is: bar
    ```
    Then the result would be :
    ```yml
      required:
        field:
          uuid:
            is: string
            size: 64
          hostname:
            is: string
            size: 1 - 999
            default: localhost
            validate: test-hostname(p1)
      optional:
        field:
          foo:
            is: bar
      ```
1. But if you have :
    ```yml
    append:
      required:
        field:
          uuid:
            validate: test-uuid(p1)
    ```
    Then the result would be :
    ```yml
      required:
        field:
          uuid:
            is: string
            size: 64
            validate: test-uuid(p1)
          hostname:
            is: string
            size: 1 - 999
            default: localhost
            validate: test-hostname(p1)
      ```
    Here, the result is equivalent to `alter` (which will fill the gap just like `append` adds the new sub-prop at that level in the tree).

Finally, `append` works on lists like :

```yml
foobar:
  - item 1
  - item 2
```

If you do :

```yml
append:
  foobar:
    - item 3
```

The result would be :

```yml
foobar:
  - item 1
  - item 2
  - item 3
```

#### Reusable Yaml blocks (`includes` : plural)

- `include` is about loading other Yaml files with the mechanism explained above
- `includes` make possible to reuse blocks of Yaml in the same file like this :

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

#### Instanciation ("concrete" entity instances)

Entities are discovered using the following lookup mechanism. It runs for all (enabled) entity declarations, per entity *type* :

1. All `*.entity.yml` in all *active dirs* are discovered and cached during *instance (re)init* in the "normal" (file-based) ASC cache, i.e. in `data/asc/cache`.
1. Once all active entity types are discovered, the *instance (re)init* post-processing *discovers* all the **concrete entity instances**.
1. For *sidecar.able* entities, all manually created or generated instances are to be placed in paths like (for ex. for the `host` entity *type*) : `data/entities/host/foobar.home.arpa.yml`.
1. The discovered concrete entity instances may either be written to the "normal" (file-based) ASC cache (in `data/asc/cache/entities/$type/...`), or - depending on the entity spec itself which may define a specific storage type like databse - in any other available storage mechanism (whose read / write / etc. operations are wrapped in ASC entry points or pivots), like databases.

Once the local ASC project instance is initialized, any operation that interacts with one or more concrete entities can have their field values loaded in the shell scope of the entry point used using `f_entity_load()`.

TODO replace the existing `f_remote_instance_load()` implementation with this system.

TODO detailed example using a "concrete" host entity *instance* : `data/entities/host/foobar.home.arpa.yml`

#### Linking, adressing (relationships, references)

TODO

### Tests

TODO rewrite / adapt this :

#### Organization

ASC tests are integrated in levels :

- entry point (level 0)
- test batch (level 1)
- test suite (level 2)
- test case (level 3)
- assertions (level 4)

For example, the "integration" tests would have :
- entry point (asc action = level 0) : `make test-integration` Or : @scripts/asc/extend/test/integration.sh
- @scripts/asc/extend/test/integration.sh includes 1 batch (level 1) = 1 call to `u_test_batch_exec()`
- with 3 suites (level 2) from the @scripts/asc/extend/test/integration dir

At the suite level, for example : @scripts/asc/extend/test/integration/site_api.test.sh , each test case (level 3) is a function whose name starts with "test_", so in our example : `test_site_api_connectivity()`.

The assertions (assertEquals, assertTrue, etc. = level 4) are functions provided by @asc/vendor/shunit2/shunit2

#### Pre and post test suite execution (shunit2) functions

Test suites can implement the following special functions picked up by shunit2 :

```sh
oneTimeSetUp() {
  # This runs ONCE before any test starts.
}

oneTimeTearDown() {
  # Only when teardown is needed (purge, cleanup). Omit if empty.
}
```

### ASC domain-specific language : *DSL* syntax

This is more of a convenience shortcut to simplified ASC implementations. It allows things like :

- Custom LLMs "harness" (see `asc/extensions/agent`)
- One-liner entity field values validation
- Basic pre-processing tests
- Faster prototypes to evaluate, compare, measure implementation ideas

#### Entry points

As in `make`. Ex :

- `start` = `make start` = `asc/instance/start.sh`
- `service-rebuild` = `make service-rebuild` = `asc/extensions/compose/service/rebuild.sh`
- etc.

#### Arguments

Arguments are specified using `()` and are separated by `,` :

- `test-in(foobar,bar,baz)` -> `asc/utils/test/in.sh 'foobar' 'bar' 'baz'`

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

**Boolean options :** (shrink all `--` to `-` in prefixed syntax)

- `b-y` = `-y` = any boolean option prefixed by a single `-`
- `bb-oneline` = `--oneline` = any boolean option prefixed by a double `--`
- `ba` = all boolean options prefixed by a single `-` are forwarded - and ONLY those boolean options
- `bba` = all boolean options prefixed by a double `--` are forwarded - and ONLY those boolean options

**Named options :**

- `o-m-4` = `-m 4` = any named option prefixed by a single `-`
- `oo-max-4` = `--max 4` = any named option prefixed by a double `--`
- `oe-max-4` = `-max=4` = any named option prefixed by a single `-` with an `=` sign before the value
- `ooe-max-4` = `--max=4` = any named option prefixed by a double `--` with an `=` sign before the value
- `oa` = all named options prefixed by a single `-` are forwarded - and ONLY those named options
- `ooa` = all named options prefixed by a double `--` are forwarded - and ONLY those named options

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

#### Chaining

- `[echo(v-baz)];echo(foobar)` = calls `echo "$baz" ; echo 'foobar'`
- `[echo(v-baz)];;echo(foobar)` = calls `echo "$baz" && echo 'foobar'`

#### Parallel

- `[echo(v-baz)]-;-echo(foobar)` = calls `echo "$baz" & echo 'foobar' ; wait`

#### Piping

- `[echo(v-baz)]+grep(foobar)` = calls `echo "$baz" | grep 'foobar'`

#### Conditional execution

- `[echo(v-baz)]++[exit(1)]` = calls `echo "$baz" || exit 1`

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

#### "Normal" DSL example

```text
transcribe-file(path/to/file.mp4)
```

triggers the following call :

```sh
asc/extensions/transcription/transcribe/file.sh path/to/file.mp4
```

#### DSL in Yaml

In a Yaml file `foobar.entity.yml` specifying a `foobar` entity definition with a `toto` field, the "validate" entry specifies that the `toto` field value must respect either URL slug or snake case formats :

```yml
required:
  field:
    toto:
      validate: test-in(p1,slug(p1),snake(p1))
```

That DSL syntax example translates to :

```sh
[[ asc/utils/test/in.sh 'foo-bar' "$(asc/instance/slug.sh 'foo-bar')" "$(asc/instance/snake.sh 'foo-bar')" ]] || exit 1
# ... where 'foo-bar' would be the entity "toto" field value declared in its "*.entity.yml" specification file.
```

This is used during basic validations, such as tiny automated tests automatically executed upon initializing newly added entity declarations in a local project instance.

NB : any DSL starting with `test-*` translates to e.g. `[[ */test/*.sh ]] || exit 1` for convenience.

DSL syntax must remain filename-safe (Linux, Windows, IOS), so we could have files implementing hooks like :

```text
*/$subject/transcribe-file(v-input_file_path).pre-index.hook.sh
```

### Data dirs

Files placed in `data/*` are usually writeable and specific to a single ASC project instance. They are meant for ASC core, contrib and/or custom implementations.

#### ASC cache : `data/asc/cache`

TODO

#### Default file-based entity storage : `data/entities`

TODO

##### Queue entities : `data/entities/queue`

TODO

##### Thread entities : `data/entities/thread`

TODO

#### Logs : `data/logs`

TODO

- `logged-*` prefix ? (logged-thread, logged-batch...)
- stdout / stderr / both ?

#### Private files : `data/private`

TODO

#### Prompts local archive : `data/prompts`

TODO

#### Test results : `data/test-results`

TODO

#### Temporary files : `data/tmp`

TODO

#### Default file-based agent skills storage : `data/skills`

TODO

## Workflow

ASC provides a minimal, customizable and extensible workflow meant to be implementable by either humans or agents.

### (re)Search

TODO

### Ideas

TODO

### Change(log)s

TODO

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
  │   ├── test/               ← shunit2 low-level tests suite
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
  │       │   ├── asc/             ← asc ships its own "vendor" contrib "namespace"
  │       │   │   └── ...          ← ... as well as some vendor-specific default implementations
  │       │   ├── $provider/       ← yields : $provider.$ext exclusions patterns in .asc_extensions_ignore
  │       │   │   ├── $ext/            ← [$subject/$action ext.point] contrib asc extension
  │       │   │   │   ├── .asc_subjects_ignore  ← [nested $ext] submodule(s) (recursive)
  │       │   │   │   └── ...
  │       │   │   ├── .asc_extensions_ignore  ← blacklisted contrib asc extensions
  │       │   │   └── ...
  │       │   └── ...
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
  ├── env.foobar.yml          ← [optional] conditional (hook-based) global env vars declaration
  ├── SPECIMEN.env.yml        ← copy to env.yml
  ├── SPECIMEN.remote_instances.yml  ← [optional] copy to remote_instances.yml
  └── ...
```

TODO 2026/07/23 the .asc_extensions_ignore must be modified to accept dot prefix for new $provider/$ext paths.

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

Generated (do not hand-edit):

- `.env`
- `data/asc/global.vars.sh`
- `data/asc/generated.mk`
- `data/asc/cache/*`

## Contributors

Project name, ideas & "rock'n'rôle" : [arhkaos](https://github.com/arhkaos)

## License

Apache License 2.0 (see [LICENSE](LICENSE)).
