# Agnostic Shell Controller (ASC) 🔤🔠🔡🔢🔣🆒🆓

**Origin:** Forked from [Paulmicha/common-web-tools](https://github.com/Paulmicha/common-web-tools) branch `v2.0.0`, which is this repo’s **`main`**. That line diverged enough to warrant a dedicated project. Git history was rewritten to **ASC** identity (toolkit `asc/`, symbols `ASC_*` / `asc_*`), and the project is licensed under Apache-2.0; sensitive traces were removed.

This project attempts to tackle the hard problem of naming things. Its ambition is to set a common, shared vocabulary for anything interacting with the shell somehow, including linux kernel (or OS-level) interactions and beyond.

***Let's make words matter*** 📚

## Overarching goal

Like the Go (game) but with entry points, env vars, scripts (wrappers, nesters, "regular"), namespaces and hooks.

If you name things right, projects practically write themselves.

## Current status

*Massive rewrite* ☢️ to shrink it to bare essentials, rethink things through.

**Here's the current raw TODO / current status :**

Potential collisions in filesystem :

- `$subject` / `$action`
- `$subject` / `$object` / `$action`

Resolution :
Agnostic stance.

In terms of ASC entity representation, `$subject` may or may not choose to implement that extra level.

Implications :
Change ASC core current files discovery mechanisms to support both.

1. Stabilize Naming convention in doc
2. Stabilize workflow + git flow in doc
3. Stabilize hooks in doc
4. Stabilize DSL in doc
5. Stabilize Yml in doc
6. Refactor Bootstrap
7. Refactor core + core extensions
8. Refactor tests (switch to nestable entity)
9. Complete the Builder
10. Complete the baseline implementations
11. Implement agents (for now Cursor to test MVP, then planned : Hermes + ollama + kimi k3 ?)

Also TODO : drop submodules declarations via `.asc_extensions` because of objects.

--

`$subject` / `$object` / `$action` examples :

- Remote instance restart
- Remote host ssh
- Entity relation list
- Entity field list
- Entity prop list

--

Field vs prop :

field = store.able instance values (edit.able)
--vs--
prop = yml "constants" shared by all those entities (inherit.able)

--

Concrete "prop" example :

*.entity.yml all have 'required' and 'optional' root-level keys (in yml key:value nest.able syntax)

--

Concrete "field" example :

TODO use remote_host.entity.yml and remote_instance.entity.yml as examples.

Fields must be stabilized first.
They must allow to do things like :

a remote instance entity has a parent remote host entity,
they both have a 'hostname' field,
which stores (in sidecars or globals or cache or scripts) the value for ASC implementations to use.

--

DSL to refactor :

- Invert `(` and `[`
- (positional) Argmuments = `a`
- Options (named arguments) = `o`
- Boolean options (named options) = `bo`

`test-is[either](slot.slug[-],slot.slug[_]])`

Becomes

`test-in(a1,[slug(a-1,-),slug(a-1,_)])`

Must be filename-safe.

-> DSL args auto convert :

(shrink all `--` to `-` in prefixed syntax)

`a` = `$@`
`a-1` = `$1` (`a-$n`)

`a-1s` = rest of params after 1 shift
`a-2s` = up to param 2 shift etc.

`bo-oneline` = `--oneline`
`bo-y` = `-y` = any boolean option

`o-max-4` = `--max=4` or `--max 4` or `-m 4`

--

Parsable `stdout` to catch things for prompt ?

Ex :

```html
Error message, any stdout output... With at the end :

<asc-dsl>
Dsl ?
</asc-dsl>
```

And / or :

```html
<asc-yml>
required:
  foobar: <slot/> ?
optional:
  foobar: <slot/> ?
</asc-yml>
```

Those could be templates :

- **string** templates : `u_str_convert_tokens()` (asc utility) TODO rename to just `tpl()` !
- **file** templates : `*.tpl.html` (hook)
- or even entire **dir** templates

--

Blueprint can be DSL or string template or file template or dir template.

--

Rules (TODO asc core extension in progress, like the drupal contrib module) :

example : solidjs ui file tree in "projet complexe" : need to represent "root" vs user file ownership

any "infra" action must be properly configured as sudoers entries first (or other mecanisms)

-> some kind of sync pattern could be integrated in ASC core ?

like a type.able entity where the "patterns presets" could be selected, e.g. :

> make a hook for that, make a sidecar for this, prototype, test, recap as a new "change" entry.

All expressable in DSL.

--

Sidecar :

Entity = represents something virtual
Yml = concrete (actual) file sidecar

Compose.yml = concrete (actual) file sidecar of a (nestable) project stack

Any script can be concrete (actual) file sidecar of any action.

--

Workflow :

- Centered around change
- Changelogs are change sidecars
- Changes must be entities

The `change.entity.yml` is nest.able (up to files and folders granularity)

TODO We must delegate as mush as possible to git.
TODO Change entities could be pieces of changelogs in prose (*.md), or something more formal ?
TODO Provide MVP use cases for now.

--

Relations :

- `$subject`--`$object`
- `$subject`--`$predicate`--`$object`

ASC notation examples :

remote-host--foobar
remote-host--reverse-proxy--state

(presence of "--" means **we are not talking about an entry point** here)

Useful in docs and blueprints only ?

Mapping to complex memory stores (relational db) is out of scope.

--

workflow.able idea :

slot.able
nest.able -> plan

builder = can use temporary asc overrides in tests to test ideas as prototypes !!!!!!

hard rule : all include of entities must be namespaced (not "contract" but "asc.contract" able ...)

--

The yml file format used in ASC is a definition of something being
represented and named (= file name and path).

**"Genericity" scale :**

1. Primordial = akin to the very first living cell that existed on earth.
2. Primitive = yml files defining the yml file name suffix. Ex: `able.able.yml`
3. ASC core extensions
4. ASC contrib extensions
5. Third-party contrib extensions
6. Project-specific impementations

--

task-oriented VS knowledge-oriented :
mutual killswitch to implement

--

Make vars and functions (synonym : f) sidecar.able entities (so we can get stats, etc) ?

The "data_dir.store.able" sidecar of each shell variable and function written in current project instance is a nest.able structure reproducing its relative location (from project docroot).

Instead of distinct entities, we could just have a common representation for any "atomic" piece of code. We should just **use the blueprint entity** from the "builder" core extension. It expresses the *same* thing.

I think the *Atomic Design Methodology* from Brad Frost makes sense here.

> Atomic design is a methodology composed of five distinct stages working together to create interface design systems in a more deliberate and hierarchical manner. The five stages of atomic design are :
> 
> - Atoms
> - Molecules
> - Organisms
> - Templates
> - Pages

But here in ASC we could just make a single "atomic.able" blueprint entity. The blueprint entity equivalent (nest.able + use.able) objects would be :

- vars (global, scoped, positional_arg, named_arg, local, readonly, exported - NB : vars are nest.able because they can be string templates or make use of other vars or functions - TODO or dsl ?)
- functions
- files
- dirs
- asc instance

Examples of potential DSL usage in entry points :

- `dsl entity-field-val(type,a-1)` in `asc/extensions/builder/code/var/is.sh.sh`
- `dsl file-sidecar(a)` in `asc/extensions/builder/blueprint/var/sidecar.sh`
- `dsl file-sidecar(used-by,a-1)` in `asc/extensions/builder/code/function/used_by.sh.sh`
- etc.

TODO `dsl()` could be like the `hook()` function, but it likely will need to prepare some variables in calling scope - i.e. :

```sh
# Positional (unnamed) arguments would be simple :
a="$@"
a_1="$1"
a_2="$2"
a_3="$3"
a_4="$4"
a_5="$5"
a_6="$6"
a_7="$7"
a_8="$8"
a_9="$9"

# TODO Shifted values like a_1s, a_2s (rest of params after 1 shift).

# Named arguments would require some manual work (it depends on scripts,
# programs used, etc.) - for instance :
o_s=''
o_h=''
bo_y=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    # With value = "normal" options :
    -h|--hook) export o_h="$2" ; shift 2 ;;
    -s|--scope) export o_s="$2" ; shift 2 ;;

    # Without value = boolean options :
    -y|-yes) export bo_y=1   ; shift 1 ;;
  esac
done
```

--

Files and folders (synonym : dir) :

They can be entities.
No need to store unnecessary sidecars.

They could be used to simply target specific paths which may be git-ignored or inside generated (data) dirs, etc.

Real, "concrete" dirs are nest.able themselves, so it is naturally fitting that the dir.entity be nest.able so relative paths - of any subject/action, or any file - are easier to match (by swapping prefixes), e.g. :

- `data/cache/foo/bar` -> "data_dir.store.able" prefixed `foo/bar`
- `scripts/asc/override/foo/bar` -> overridden `foo/bar`

--

Rename "seed" to just "command" (synonym : cmd).

The fundamental idea is this :
entry points are fixed pivots, and are sidecar.able as pre-compiled commands (cmd).

when you run `make gpu-driver-install` on linux or windows, the command(s) will differ (because implemented as hook variants).

--

Seed :

Copy tmp cache dir backup copy

Path-based entry points get "frozen"

TODO freeze.able = data/* sidecar(s) ? E.g. `*.assembled.sh` or `*.compiled.sh`
TODO cache by path ?
TODO cache rebuild, reinit, can be incremental ?

--

Incremental cache rebuild

Could look like, per entry point :

- get last file modified datetime in e . $subject (or $subject - $object) containing dir
- compare with current cache rebuild datetime
- if last file modified datetime is more recent, rebuild that cache path
- also check var + f use -> TODO perhaps use a relation field on (builder.)blueprint_var.used_by ?

Basically, any impacted "dir branches" must be rebuilt (from the deepest possible "branch" level)

Concrete examples :

- Take the following entry point : `asc/extensions/builder/code/function/used_by.sh.sh`
- file-sidecar(used-by,a-1)
- `data/cache/code/function/used-by`

- 

--

New hook entry points :

- `hook` (like call_wrap.make.sh)
- `hook-most-specific` = `hook-ms` (TODO new function to integrate in ASC core)
- `hook-dry-run` = `hook-dr` (TODO new function to integrate in ASC core)

--

It's not what you need.
It's how you formulate it.

Every problem becomes a (re)formulation problem.

Descriptions of changes must boil down to DSL, up to the file and folder atomic changes (builder can generate files and dirs from blueprints, but code refactoring is delegated to third-party implementations).

--

Finally, refactor make so it understands DSL

--

Make the entry points "mamespaced" notation facultative (e.g. in yml).

Because it defaults to the implementations automatically resolved based on local asc instance variants.

Prefixing could be a way to specifically inherit something not active in local asc instance.

--

Graphical representation metaphor:
Files are cells (inner parts), "membrane", etc.

Nest.able = zoom.able (TODO graphical bridge for pagination, tree + nest "fractal" navigation)

--

Entry points are pointers 
Sidecar ? Ex symlink
Freeze.able as cache or seed ?

Slugified args collisions if we use dsl as frozen entrypoints : piling up with integer suffix, with yml to store raw command ?

Frozen entry points of dsl syntax.
Cache / frozen / entry-points ? Dsl ? Both ?

We could have file paths, like either :

- `entity-field-val(type,a-1).dsl.hook` (no extension because it's not a script : it's just an empty file that needs to exist at this exact path ; a bit like the ".gitkeep" files sometimes used for having git-ignored folders exist in git repos), or :
- `entity-field-val(type,a-1).dsl.hook.yml` : defines a/o validations

Yml examples of a/o = arg(s) and option(s) validation definitions :

```yml
a:
  validation: test-is(a,slug(a))
```

```yml
a1:
  validation: test-in(a-1,[slug(a-1,-),slug(a-1,_)])
```

--

TODO Make some kind of general guideline for all ASC code like *"max 1000 lines per file everywhere"* to try and encourage splitting complex things into smaller pieces ?

--

TODO rename "thread" to "process" (synonym : "proc" ?) to better match the reality of the shell mechanisms at play ?

In the context of the Linux shell, the primary difference is that every standard command you run in the shell executes as a separate process, whereas threads are internal execution units within those processes that the shell cannot directly manipulate or pipe together. 

When you type a command like ls or grep, the shell clones itself to create an isolated environment with its own memory. Threads, on the other hand, exist strictly inside a single process to handle lightweight multitasking while sharing that process's memory space.

Latin : procurare (procureur) ?
// avec concept de délégation ?

Mais en fait non, gardons "thread" car du point de vue d'ASC, on est sur des pivots, et thread ce serait comme des process "owned" + custom managed by ASC, donc l'entité asc "thread" sera une représentation relativement accurate des "process" en shell (asc thread = process managés par, internes et propres à ASC, différents des autres process que d'autres scripts pourraient gérer - une chose n'empêche pas l'autre).

--

Blueprint entity is not enough in builder ext.

We need a code entity so blueprints are clearer.

- code/var/$object/$action -> objects = global, local, readonly, exported, etc. ?
- code/f/$action

All code entities (var + f) have :

- scope
- used-by
- complexity ?
- performance measures sidecars ? (stats ?)
- implementations ? (log.able, thread.able...)
- patterns ?

--

Template filename syntax

Subfolder name (same structure as tests) = "tpl"

- `$subject` or `$object` / `[action].sh` : repeatable template file (can generate as many files as necessary using the same template)
- `$subject` / `{subject}.inc.sh`  : results in a single file generated

Ex :
- `asc/extensions/builder/template/core/subject/[action].sh`
- `asc/extensions/builder/template/core/subject/{subject}.inc.sh`
- `asc/extensions/builder/template/core/subject/{subject}.opt-inc.sh`
- `asc/extensions/builder/template/core/subject/[object]/[action].sh`
- `asc/extensions/builder/template/core/subject/[object]/{subject}.inc.sh`
- `asc/extensions/builder/template/core/subject/[object]/{subject}.opt-inc.sh`
- `asc/extensions/builder/template/core/test/[test_suite]/[test_case].test.sh`
- etc.

--

Multi-line template files syntax

Ex : `asc/extensions/builder/template/core/subject/[action].sh`

```txt
#!/usr/bin/env bash

##
# {{ docblock }}
#
# @example
#   {{ docblock_examples }}
#

{{ slot }}
```

We could have conditions like in : `asc/extensions/builder/template/core/test/[test_suite]/[test_case].test.sh`

```html
<asc-if not-empty="one_time_setup">
  The contents here are processed and generated in place, or remove whitespace from opening tag position until first character of the next non-empty line.
</asc-if>
```

--

General ASC guidelines

- max 1000 lines per script file (split inc and opti-inc files in sub-includes if necessary)
- In meta-related work, never describe the containing thing - only what it it about. E.g. if you write a note, no need to say : "this is a note" in whatever note metadata there is. It's an unnecessary repitition of something (like a script) that is already provided in the file path itself - all files in ASC being conceptualized as "sidecars" (entity = virtual, file = actual)...

--

About `$subject` / `$object` / `$action` path structure :

- `$subject` / `*.hook.*` files are currently supported
- but not `$subject` / `$object` / `*.hook.*` (by design, for now)

Only `$subject`'s dirs can implement hooks (**not** their `$object`'s sub-dirs).

To recap what `$object` dirs can currently provide :

- `[action].sh` = entry points
- `{subject}.inc.sh` = functions loaded in every asc-bootstrapped scripts
- `{subject}.opt-inc.sh` = functions "leazy-loaded" in asc-bootstrapped scripts
- `{entity}.entity.yml` = asc entity definitions
- `{contract}.able.yml` = asc entity contract definitions

Basically everything any `$subject` dir can declare, except hooks (only declarable in `$subject`) :
- `[hook].{file_ext}` = hook implementation template
- `[hook].{variants}.{file_ext}` = hook variant implementation template

--

DSL updates :

TODO Slugs must have entry points so DSL can do things like :

- `slug-url(a)`
- `slug-snake(a)`
- `slug-camel(a)`

TODO On top of entry points, also support both `f_foobar` and `f-foobar` notations for function names in DSL.

--

TODO Make some kind of general guideline for ASC code like "max 1000 lines per file everywhere" to try and encourage splitting complex things into smaller pieces ?

--

Original README below, to be completely rewritten :

---

## End goal

- Capabilities first, entities second
- Sibling UI project in Tauri + SolidJS : a "second-brain" based on [projet-complexe](https://github.com/Paulmicha/projet-complexe) in order to implement a "code refactorer" agent role
- Offload more tasks to third-party projects where sensible ? Criterias ?

## TL;DR

Clone or copy this repo into your project docroot, then:

```sh
cp SPECIMEN.env.yml env.yml   # edit as needed
make setup                    # or: make   → instance init
```

Deep dives live under [`docs/asc/`](docs/asc/). Extension notes: [`asc/extensions/README.md`](asc/extensions/README.md).

## WHAT

ASC is a scaffolding bash shell CLI for usual (web or general) project tasks — a generic, customizable, extensible toolbox for **local (internal) development**.

ASC is not a program; it is the “glue” between programs. Third-party integration is provided by **extensions** (bundled under `asc/extensions/`, often disabled by default). Core contains utilities for global environment variables, minimal host operations, optional git hooks, log/thread/loop wrappers, and low-level automated tests (`make test-core`).

ASC is **not** meant for production. It helps individual developers or teams keep a common CLI across older and newer projects.

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
| *test asc* | `asc/test/core.sh` | `make test-core` |

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

| Name | Default on? | Submodules | Description |
|------|:-----------:|:-----------|-------------|
| `agent` | | | Plan subject stubs (`plan-iterate`, `plan-review`) |
| `apache` | | | Apache VHost helpers (classic LAMP, non-compose) |
| `apt` | ✔ | | Host apt `dependency-*` hooks (stubs) |
| `arangodb` | | | Alias / image tag defaults |
| `builder` | | | Templates / blueprints / prototypes stubs ([docs/asc/builder.md](docs/asc/builder.md)) |
| `cognition` | | | `observe-*` / `recognize-*` / `categorize-*` / `compare-*` stubs |
| `compose` | | | Docker Compose start/stop/build/destroy (`DC_MODE`, stack helpers) |
| `crontab` | | | Host crontab sync helpers |
| `db` | | | Abstract DB hooks |
| `docker` | | `nested_docker` | Nested docker list/connect/exec stubs |
| `drupalwt` | | | Drupal tasks ([extension README](asc/extensions/drupalwt/README.md)) |
| `drupalwt_d4d` | | | Drupal + compose / docker4drupal-oriented stack |
| `drush` | | | Drush aliases / hooks |
| `entity` | | | Entity model stubs (`has-*`, `is-*`, field) |
| `file_registry` | ✔ | | Default file-based registry (instance / host) |
| `git_crypt` | | | Opt-in encryption hooks (stub) |
| `gpt` | | | LLM abstracts (`gpt-start`, …) |
| `hardware` | | `nested_hardware` | Hardware entity stubs |
| `hosts_file` | | | `/etc/hosts` helpers |
| `interaction` | | | Interactive prompt helpers |
| `link` | ✔ | | `linkable` entity type |
| `memory` | | | Storage / store stubs |
| `moodle_d4php` | | | Moodle + docker4php-oriented stack |
| `mysql` | | | MySQL implementations of `db` |
| `nested_asc` | | | Nested instance list/exec ([docs/asc/nested-asc.md](docs/asc/nested-asc.md)) |
| `nested_git` | | | Nested git / `subgit` wrap (`nested-git` synonym) |
| `nested_host` | | | Nested host list/connect/exec stubs |
| `node` | | | Aliases / default port |
| `ollama` | | | Default hooks for `gpt-*` via Ollama |
| `pgsql` | | | Postgres implementations of `db` |
| `remote` | | | SSH sync utilities |
| `remote_asc` | | | Remote ASC helpers |
| `remote_db` | | | DB dump sync via `db` + `remote` |
| `remote_traefik` | | | Traefik / Let’s Encrypt defaults |
| `rules` | | | Rule stubs |
| `software` | | `nested_software` | Host package / provision hooks |
| `taxonomy` | | | Term / vocabulary entity stubs |
| `transcription` | | | `transcribe` / `transcribe-all` |
| `views` | | | View stubs |

Default-on assumes the stock core ignore list (everything listed there is off; `apt`, `file_registry`, and `link` are usually the exceptions). Nested subjects under an extension (Submodules column) can also be ignored via that extension’s `.asc_subjects_ignore`. Project overrides win. More: [docs/asc/extensions.md](docs/asc/extensions.md), [`asc/extensions/README.md`](asc/extensions/README.md).

## Automated tests

```sh
make test-core
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
    1. [field vs prop](docs/asc/entities.md#field-vs-prop)
    1. [sidecar](docs/asc/entities.md#sidecar)
    1. [relationships](docs/asc/entities.md#relationships)
    1. [compatibility, applicability ? (protocols, etc)](docs/asc/entities.md#compatibility-applicability-protocols-etc)
    1. [yml includes (synonym : inheritance)](docs/asc/entities.md#yml-includes)
    1. [change / workflow](docs/asc/entities.md#change--workflow)
1. [yml structure](docs/asc/yml-structure.md)
    1. [scope vs filename-DSL](docs/asc/yml-structure.md#scope-vs-filename-dsl)
    1. [file kinds](docs/asc/yml-structure.md#file-kinds)
    1. [props vs fields in bodies](docs/asc/yml-structure.md#props-vs-fields-in-bodies)
    1. [state able (git draft)](docs/asc/yml-structure.md#state-able-git-draft)
    1. [subject inventory](docs/asc/yml-structure.md#subject-inventory)
    1. [repo entity (git draft)](docs/asc/yml-structure.md#repo-entity-git-draft)
    1. [primordial meta (Wave B draft)](docs/asc/yml-structure.md#primordial-meta-wave-b-draft)
    1. [open / living](docs/asc/yml-structure.md#open--living)
1. [builder](docs/asc/builder.md)
    1. [documenting (~ minimal OKF ? dedicated core extension ?)](docs/asc/builder.md#documenting-minimal-okf-dedicated-core-extension)
    1. [blueprints](docs/asc/builder.md#blueprints)
    1. [atomic blueprint objects](docs/asc/builder.md#atomic-blueprint-objects)
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
1. [shell usage](docs/asc/shell-usage.md)
    1. [stdin / stdout / stderr](docs/asc/shell-usage.md#stdin--stdout--stderr)
    1. [sourcing](docs/asc/shell-usage.md#sourcing)
    1. [argument forwarding](docs/asc/shell-usage.md#argument-forwarding)
    1. [shell options](docs/asc/shell-usage.md#shell-options)
    1. [scope](docs/asc/shell-usage.md#scope)
    1. [walk arrays](docs/asc/shell-usage.md#walk-arrays)
    1. [step by step](docs/asc/shell-usage.md#step-by-step)
    1. [symbol prefixes (f_ / e_ / o_ / p_ / b_ / hookms)](docs/asc/shell-usage.md#symbol-prefixes-f_--e_--o_--p_--b_--hookms)
    1. [filename-DSL examples](docs/asc/shell-usage.md#filename-dsl-examples)
    1. [proposed DSL redesign (README)](docs/asc/shell-usage.md#proposed-dsl-redesign-readme)
    1. [parsable stdout (asc-dsl / asc-yml)](docs/asc/shell-usage.md#parsable-stdout-asc-dsl--asc-yml)

Deep-dive index: [`docs/asc/README.md`](docs/asc/README.md).

## Roadmap

- Bash strict mode for all ASC (once refactored)
- Reduce bashisms / improve POSIX compatibility where practical ~ less reliant on bash (support any posix shell ?), make the shell scripts themselves "variant.able" via hooks...
- Windows support via tests in (nested) vm ?
- macOS-specific errors ?

## Contributors

Project name, ideas & "rock n rôle" : [arhkaos](https://github.com/arhkaos)

## License

Apache License 2.0 (see [LICENSE](LICENSE)).
