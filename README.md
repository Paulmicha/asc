# Agnostic Shell Controller (ASC) 🔤🔠🔡🔢🔣🆒🆓

ASC is not a program; it is the “glue” between programs. It is a generic, customizable, extensible toolbox for a wide range of **local development** tasks, with the ambition to serve humans and agentic systems alike.

It allows to set a common, shared vocabulary for anything interacting with the shell somehow. It provides mechanisms allowing to establish "pivots" that represent actions with varying implementations.

The only "job" of ASC is to serve as a thin layer that :

- **wraps** calls to other CLIs and/or OS-level operations ;
- **sets** a naming convention that persists despite implementation changes, i.e. the *action* `make transcribe-file -- path/to/file.mp4` will remain identical, even when the program(s) used to do the actual transcribing in a project using ASC do ;
- allows to provide **adaptations** to a variety of contextual *specificities* such as host types (local, remote), OS (debian, apline, windows, ios), or any other *variants*.

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

Here's a few words to tease this representative ASC use case :

### ASC demo : "_Projet Complexe_" as an attempt at reinterpreting Mihaly Csikszentmihalyi's concept of _Flow_ for agents

For humans:

> challenge ≈ skill

For an agent:

> task complexity ≈ effective cognitive capacity

The important point is that *effective* capacity is not simply model size.

It depends on things such as:

* available context  
* retrieval quality  
* tool availability  
* memory organization  
* planning depth  
* decomposition strategy  
* uncertainty estimation  
* time/token budget

A 7B model with excellent retrieval may outperform a 70B model with poor context.

So "skill" is actually an emergent property of the entire cognitive architecture.

### An agent is under-challenged when it has excessive unused capacity relative to the problem

Symptoms include:

* overthinking  
* hallucinated complexity  
* unnecessary abstractions  
* verbosity  
* recursive planning  
* inventing distinctions that do not exist

You can observe this in many LLMs.

Ask:

> "Rename this file."

The model writes five paragraphs explaining naming conventions.

The task provided almost no cognitive load.

The excess capacity gets filled with plausible but unnecessary generation.

Humans get bored.

LLMs ramble.

### The opposite regime is far more interesting

The effective complexity exceeds the available cognitive resources.

Examples:

* context window saturated  
* contradictory instructions  
* missing ontology  
* too many objectives  
* hidden assumptions  
* missing world model  
* excessive branching factor

The symptoms become familiar.

The model begins to:

* forget constraints  
* contradict itself  
* latch onto superficial cues  
* ignore part of the prompt  
* randomly prioritize objectives  
* oscillate between incompatible interpretations

Humans experience anxiety.

Agents experience instability.

### Prompt engineering is really challenge regulation

This may be one of the most useful reinterpretations.

Good prompting is often described as "being clear."

I think a better formulation is:

> A good prompt keeps the agent inside its optimal cognitive operating region.

That means regulating:

* complexity  
* ambiguity  
* branching factor  
* uncertainty  
* objective count

instead of merely reducing token count.

Enough teasing "_Projet Complexe_", back to ASC - the generic base upon which all of this work rests :

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

### Extension

An **extension** is any folder in the following list (from **most generic** to **most specific**) :

1. `./asc/extensions`
1. `./scripts/asc/contrib/asc`
1. `./scripts/asc/contrib/$vendor`

The default extensions provided by the main ASC repo are all *disabled* by default, except for `asc/extensions/file_registry`.

#### Enabling and disabling extensions

> Create or edit `scripts/asc/override/.asc_extensions_ignore`.

Like the `.asc_subjects_ignore` files, it are essentially acts like a `.gitignore` files for the ASC discovery mechanism. See :

- `scripts/asc/contrib/.asc_extensions_ignore` for the ASC core extensions disabled by default,
- and `scripts/asc/contrib/.asc_extensions_ignore` for the ASC contrib extensions disabled by default.

### Overrides

In ASC, during *bootstrap* (see below), any Bash shell script include can be swapped by your own altered copy if needed.

If the "counterpart" of a given script exists in the folder `scripts/asc/override`, it will be used instead of the original file.

This allows to replace any includes or hook implementations.

Example : if we want to override `asc/git/init.hook.sh` - effectively *bypassing* the existing default implementation provided by the ASC main repo, we'll create the following file :

`scripts/asc/override/git/init.hook.sh`

The matching is done by by replacing the leading `asc/` in filepaths with `scripts/asc/override/`. It works for extensions too.

Here's another example to illustrate overriding a Bash shell script include :

- `asc/extensions/docker-compose/docker-compose.inc.sh` → `scripts/asc/override/extensions/docker-compose/docker-compose.inc.sh`

### Project-specific implementations

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

NB : and an additional `$object` subdir may be used for regrouping actions (see _actions_).

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

Result : any "local dev" project instance gets the `foobar-2026` stack. The rest (e.g. remote instances, or prod local instances, etc.) still stay on the `foobar-2025` stack.

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

#### Git-ignored, "private" _env vars_

If you need local, "private" values that must NOT be checked out in any git repo, the following file can be used : `.env-local.yml`

If needed, the available lookup paths are the same as for the `env.yml` file :

```txt
.env-local.$HOST_TYPE.yml
.env-local.$INSTANCE_TYPE.yml
.env-local.$STACK_VERSION.yml
.env-local.$HOST_TYPE.$INSTANCE_TYPE.yml
.env-local.$STACK_VERSION.$HOST_TYPE.yml
.env-local.$STACK_VERSION.$INSTANCE_TYPE.yml
.env-local.$STACK_VERSION.$HOST_TYPE.$INSTANCE_TYPE.yml
```

### Hooks (variants)

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

**Semver** suffixes can be used in extension folder names and variant values.

TODO [wip] example here for that.

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

# 6. Project root dir additional lookup (-r) :
# (given HOST_TYPE='local' and INSTANCE_TYPE='dev')
hook -s 'instance' -a 'env' -c 'yml' -v 'HOST_TYPE INSTANCE_TYPE' -t -r
# Yields the following lookup paths (not sourcing matches because -t flag) :
# - */instance/env.yml
# - */instance/asc.local.yml
# - */instance/asc.local.dev.yml
# - */instance/asc.dev.yml
# - env.yml
# - asc.local.yml
# - asc.local.dev.yml
# - asc.dev.yml
```

### Tests

TODO

### Wrappers

TODO

### Yaml entity declaration

TODO

#### Field vs Prop

field = store.able instance values (edit.able)

--vs--

prop = yml "constants" shared by all those entities (inherit.able)

*Concrete "prop" example* :

`*.entity.yml` all have `required` and `optional` root-level keys (in yml key:value nestable syntax)

*Concrete "field" example* :

TODO use remote_host.entity.yml and remote_instance.entity.yml as examples.

Fields must be stabilized first.
They must allow to do things like :

a remote instance entity has a parent remote host entity,
they both have a 'hostname' field,
which stores (in sidecars or globals or cache or scripts) the value for ASC implementations to use.

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

- `@` = `$@` (all arguments are forwarded "as is")
- `p1` = `$1`
- `p2` = `$2`
- etc.

**Boolean options :** (shrink all `--` to `-` in prefixed syntax)

- `b-oneline` = `--oneline`
- `b-y` = `-y` = any boolean option
- `b-@` = all boolean options are forwarded - and ONLY boolean options

**Named options :**

- `o-max-4` = `--max=4` or `--max 4` or `-m 4` (TODO [wip] How to distinguish ?)
- `o-@` = all named options are forwarded - and ONLY named options

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

### ASC data types

- globals (`readonly` or mutable, may be secret + TODO encrypted ?)
- cache or sidecars (ex: logs) or media or test artifacts in `data/*` dirs
- other `*.yml` (ex: remote instances or any entity)
- encrypted (git) versionned files (cf. `data/crypted`)

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

- `scripts/cwt/extend/stack/compose.foobar-2026.yml`
- `scripts/cwt/extend/stack/compose.override.foobar-2026.local.dev.yml`

... then we have to :

```sh
# Shortcut for Reinit + Restart :
make rere
# Or :
cwt/instance/rere.sh
```

If we did **not** touch any *env var* value, this will suffice :

```sh
make compose-update
# Or :
cwt/extensions/docker-compose/compose/update.sh
```

In both cases, this will re-generate the (git-ignored) files in PROJECT_DOCROOT that `docker compose` will use :

- `compose.yml`
- `compose.override.yml`

... and restart the whole stack immediately.

Finally, if on or more custom `Dockerfile` was modified, then the `rebuild` action is required for those changes to take effect (to be run *after* `reinit` if some env var(s) were modified as well) :

```sh
make rebuild
# Or :
cwt/instance/rebuild.sh
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
