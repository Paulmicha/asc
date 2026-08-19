# Agnostic Shell Controller (ASC) 🔤🔠🔡🔢🔣🆒🆓

ASC is not a program; it is the “glue” between programs. It is a generic, customizable, extensible toolbox for a wide range of **local development** tasks, with the ambition to serve humans and agentic systems alike.

It allows to set a common, shared vocabulary for anything interacting with the shell somehow. It provides mechanisms allowing to establish "pivots" that represent actions with varying implementations.

The only "job" of ASC is to serve as a thin layer that :

- **wraps** calls to other CLIs and/or OS-level operations ;
- **sets** a naming convention that persists despite implementation changes, i.e. the *action* `make transcribe-file -- path/to/file.mp4` will remain identical, even when the program(s) used to do the actual transcribing in a project using ASC do ;
- allows to provide **adaptations** to a variety of contextual *specificities* such as host types (local, remote), OS (debian, apline, windows, ios), or any other *variants*.

## Overarching goal

Like the Go game, but with (make) entry points, (global) env vars, hooks (variants), wrappers (scripts), metadata (yml), and some generic implementations (opt-in).

### Scope

- Thin layer to organize generic (pivot) shell entry points, enforcing a common implementation blueprint for (self-)building by humans and agents alike
- Simple, minimal, self-explanatory
- Delegate as much as possible, but still provide usual, optional (opt-in), generic needs as (overridable) "exemplar" implementation blueprints
- Define things and (implementation) contracts
- Generate simple ASC code from $slot.able file / folder templates or strings.

### Non-goals ("out of scope"s)

- code refactoring
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

## Example project (demo / case study)

Here is what I am currently building with it (when I have some free time) :

["_Projet Complexe_", a "second brain" project incorporating agentic task-oriented and knowledge-oriented implementations](data/ideas/2026/08/Projet%20Complexe%202026%20Revival%20(v2)%20-%20ASC,%20Projet%20Complexe%20and%20Projet%20Complexe%20ASC.pdf)

See the corresponding [project-specific ASC (stack) repo](https://github.com/Paulmicha/projet-complexe-asc) + [the UI (Tauri app) repo](https://github.com/Paulmicha/projet-complexe).

### An attempt at reinterpreting Mihaly Csikszentmihalyi's concept of _Flow_ for agents

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

## Current status of the ASC project

*Massive rewrite* ☢️ to shrink it to bare essentials, rethink things through.

Potential collisions in filesystem :

- `$subject` / `$action`
- `$subject` / `$object` / `$action`

Resolution : agnostic stance. In terms of ASC entity representation, `$subject` may or may not choose to implement that extra level.

Implications : change ASC core current files discovery mechanisms to support both.

1. Finish describing ASC "core" concepts explicitly
1. ~~Stabilize Naming convention~~
1. Stabilize hooks
1. Stabilize DSL
1. Stabilize Yml
1. Refactor Bootstrap
1. Stabilize workflow + git flow
1. Refactor core + core extensions
1. Refactor tests (switch to nestable entity)
1. Complete the Builder
1. Complete the baseline implementations
1. Implement agents (for now Cursor to test MVP, then planned : Hermes + ollama + kimi k3 ?)

## Core ASC concepts

### Genericity (scale)

1. Primordial = the unique Yaml file at the top of the Yaml inclusion chain : `yml.yml` (akin to the very first living cell that existed on earth),
2. Primitives = Yaml files defining "low-level" structural things (like : which root properties the including Yaml files can declare),
3. Core = "generic" implementations that are systematically relevant across all projects using ASC,
4. Extensions = namespaced bundles of actions by subjects and/or objects,
5. Overrides = alterations of implementations provided by core and/or extensions,
6. Specifics = impementations with low or no potential for reuse outside the current projet ASC is used for.

The **primordial** file just defines basic synonyms. They are interchangeable words used across all Yaml files.

**Primitives** include :

- `entity.entity.yml` defining the structure of *entities* (it specifies that every `*.entity.yml` can have the root props `entity`, `required`, `optional`) ;
- `able.able.yml` defining the structure of *contracts* (*skills* or *capabilities*) ;
- and perhaps other use cases may warrant interventions on that level in other projects using ASC (the door remains open).

**Core** implementations include :

- low-level
- opt-in extensions, notably : the entity system

### ASC-bootstrapped context, or just _bootstrap_

This means any shell context that has sourced `asc/bootstrap.sh`. It loads global env vars and bash functions, depending on "auto" - and optionally "leazy" - loaded includes corresponding to the entry point used.

There are 2 kinds of ASC bootstrap contexts :

1. when a project instance is not initialized yet
1. after initialization has run (usually once in a local project instance), see setup.

### ASC-active dir, or just _active dir_

An "ASC-active dir" is a folder where files following specific naming conventions allow things like :

- auto or lazy loading of bash shell script includes (in ASC-bootstrapped contexts),
- global env vars definitions,
- hook implementations (with variants), including yaml files, python scripts, etc.

These folders are automatically discovered during instance init (and setup). They depend on things like :

- which extensions are enabled (using `.gitignore`-like declarations, see `.asc_subjects_ignore` files),
- which level of genericity the contained implementations have,
- wether they relate to a `$subject` or an `$object` (by subject)

**List of active dirs** (containing implementations from **most generic** to **most specific**)

1. `./asc`
1. `./asc/extensions/$extension` (ex: `asc/extensions/compose`)
1. `./scripts/asc/contrib/asc/$extension` (ex: `scripts/asc/contrib/asc/tesseract`)
1. `./scripts/asc/contrib/$vendor/$extension` (ex: `scripts/asc/contrib/foobar/baz`)
1. `./scripts/asc/extend`

### Specificity and Collisions handling

The bottom of this list wins when implementing the same `u_hook_most_specific()`, or even in case of the same `make $subject-$action` entry point pivot :

1. `asc/$subject/$action`
1. `asc/$subject/$object/$action`
1. `asc/extensions/$extension/$subject/$action`
1. `asc/extensions/$extension/$subject/$object/$action`
1. `scripts/asc/contrib/asc/$extension/$subject/$action`
1. `scripts/asc/contrib/asc/$extension/$subject/$object/$action`
1. `scripts/asc/contrib/$vendor/$extension/$subject/$action`
1. `scripts/asc/contrib/$vendor/$extension/$subject/$object/$action`
1. `scripts/asc/extend/$subject/$action`
1. `scripts/asc/extend/$subject/$object/$action`

### (make) _Entry points_ : ASC `$action` script, or just _action_

ASC actions are any shell scripts placed in *active dirs* with a file name :

- using the `*.sh` extension
- not beginning with a dot
- not using any double extension

In *active dirs*, there are 2 nesting levels supported for *entry points* (or *actions*) :

- `$subject` / `$action` (ex: `service-start` → `asc/extensions/compose/service/start.sh`)
- `$subject` / `$object` / `$action` (ex: `host-dependency-install` → `asc/host/dependency/install.sh`)

### (global) _Env vars_ : generated Bash shell readonly constants

TODO

### hooks (variants)

TODO [wip] rewrite properly this :

Triggers an "event" optionally filtered by primitives.

Arguments are all optional, but this function requires at least either
1 action (-a) OR 1 extension (-e). See explanations below.

In order to "listen" to events, some specific file(s) must use the exact path
and name corresponding to its arguments. For a detailed list of expected
output given various inputs :

@see asc/test/asc/hook.test.sh

Primitives are fundamental values dynamically generated during bootstrap :

@see asc/bootstrap.sh

@see f_asc_extend()

Calling this function will source all file includes matched by subject,
action, prefix, variant, and extension. Every extension defines a base path from
which additional lookup paths are derived (as well as a corresponding namespace
for glabals containing their primitives).

Important notes about the 'variants' (-v) argument :

If this function gets called without any 'variant' filter(s), it will
automatically look for suggestions using INSTANCE_TYPE.

Variants are combinatory. Each variant value must be an existing glabal var
which will generate the following lookup paths given the call :

$ hook -a 'my_action' -s 'my_subject' -v 'PROVISION_USING INSTANCE_TYPE'
+ the values PROVISION_USING='compose' and INSTANCE_TYPE='dev' :

- asc/my_subject/my_action.hook.sh
- asc/my_subject/my_action.compose.hook.sh
- asc/my_subject/my_action.compose.dev.hook.sh
- asc/my_subject/my_action.dev.hook.sh

@requires the following global variables in calling scope :

- ASC_ACTIONS
- ASC_SUBJECTS
- ASC_EXTENSIONS

@uses the following global variables in calling scope if they exist :

- ${EXTENSION_NAMESPACE}_ACTIONS
- ${EXTENSION_NAMESPACE}_SUBJECTS

NB : the default separator used to concatenate parts in file names is
the underscore '_', except for variants which use dot '.'.

Dashes '-' are reserved for folder names and to separate "semver" suffixes.
Semver suffixes can be used in extension folder names and variant values.

Also note that each argument accepts several values by using a space to
separate them. E.g. :

$ hook -a 'start' -s 'stack service instance app'

TODO Document cache warmup.

@examples

```sh
# 1. When providing a single action :
hook -a 'bootstrap'
# Yields the following lookup paths (ALL includes found are sourced) :
# (given INSTANCE_TYPE='prod')
# - asc/<ASC_SUBJECTS>/bootstrap.hook.sh
# - asc/<ASC_SUBJECTS>/bootstrap.prod.hook.sh
# - asc/extensions/<ASC_EXTENSIONS>/<EXT_SUBJECTS>/bootstrap.hook.sh
# - asc/extensions/<ASC_EXTENSIONS>/<EXT_SUBJECTS>/bootstrap.prod.hook.sh

# 2. When providing an action + a filter by subject :
hook -a 'init' -s 'stack'
# Yields the following lookup paths (ALL includes found are sourced) :
# (given INSTANCE_TYPE='prod')
# - asc/stack/init.hook.sh
# - asc/stack/init.prod.hook.sh
# - asc/extensions/<ASC_EXTENSIONS>/stack/init.hook.sh
# - asc/extensions/<ASC_EXTENSIONS>/stack/init.prod.hook.sh

# 3. When providing an action + a filter by 1 or several subjects + 1 or
#   several variants filter :
hook -a 'init' -s 'stack' -v 'HOST_TYPE INSTANCE_TYPE'
# Yields the following lookup paths (ALL includes found are sourced) :
# (given INSTANCE_TYPE='dev' and HOST_TYPE='local')
# - asc/stack/init.hook.sh
# - asc/stack/init.local.hook.sh
# - asc/stack/init.local.dev.hook.sh
# - asc/stack/init.dev.hook.sh
# - asc/extensions/<ASC_EXTENSIONS>/stack/init.hook.sh
# - asc/extensions/<ASC_EXTENSIONS>/stack/init.local.hook.sh
# - asc/extensions/<ASC_EXTENSIONS>/stack/init.local.dev.hook.sh
# - asc/extensions/<ASC_EXTENSIONS>/stack/init.dev.hook.sh

# 4. Extensions filter :
hook -e 'nodejs'
# Yields the following lookup paths (ALL includes found are sourced) :
# (given INSTANCE_TYPE='prod')
# - scripts/extensions/nodejs/<EXT_SUBJECTS>/<SUBJECT_ACTIONS>.prod.hook.sh

# 5. Prefixes filter are exclusive by default, which means pure actions are
#   not included. Ex :
hook -a 'bootstrap' -p 'pre'
# Yields the following lookup paths (ALL includes found are sourced) :
# (given INSTANCE_TYPE='prod')
# - asc/<ASC_SUBJECTS>/pre_bootstrap.hook.sh
# - asc/<ASC_SUBJECTS>/pre_bootstrap.prod.hook.sh
# - asc/extensions/<ASC_EXTENSIONS>/<EXT_SUBJECTS>/pre_bootstrap.hook.sh
# - asc/extensions/<ASC_EXTENSIONS>/<EXT_SUBJECTS>/pre_bootstrap.prod.hook.sh

# 6. Project root dir additional lookup :
hook -s 'instance' -a 'env' -c 'yml' -v 'HOST_TYPE INSTANCE_TYPE' -t -r
# Yields the following lookup paths (not sourcing matches because -t flag) :
# (given HOST_TYPE='local' and INSTANCE_TYPE='dev')
# - asc/instance/env.yml
# - asc/instance/asc.local.yml
# - asc/instance/asc.local.dev.yml
# - asc/instance/asc.dev.yml
# - asc/extensions/<ASC_EXTENSIONS>/instance/env.yml
# - asc/extensions/<ASC_EXTENSIONS>/instance/asc.local.yml
# - asc/extensions/<ASC_EXTENSIONS>/instance/asc.local.dev.yml
# - asc/extensions/<ASC_EXTENSIONS>/instance/asc.dev.yml
# - env.yml
# - asc.local.yml
# - asc.local.dev.yml
# - asc.dev.yml
```

### wrappers (scripts), metadata (yml), and some generic implementations (opt-in)

TODO

### Field vs Prop

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

**Positional arguments**

- `a` = `$@` (all arguments are forwarded "as is")
- `p1` = `$1`
- `p2` = `$2`
- etc.

**Boolean options** (shrink all `--` to `-` in prefixed syntax)

- `b-oneline` = `--oneline`
- `bo-y` = `-y` = any boolean option
- etc.

**Named options**

- `o-max-4` = `--max=4` or `--max 4` or `-m 4`

**Example**

In a Yaml file `foobar.entity.yml` specifying a `foobar` entity definition with a `toto` field, the "validate" entry specifies that the `toto` field value must respect either URL slug or snake case formats :

```yml
# This allows to enforce which things are mandatory.
required:
  field:
    toto:
      validate: test-in(p1,[slug(p1),slug(p1,_)])
```

That DSL syntax example translates to bash :

```sh
f_str_slug 'foobar'
f_str_snake 'foobar'
[[ asc/utils/test/in.sh 'foobar' "$slug_val" "$snake_val" ]] || exit 1
```

DSL syntax must remain filename-safe (Linux, Windows, IOS).

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
