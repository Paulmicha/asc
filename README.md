# Agnostic Shell Controller (ASC)

## TL;DR

Clone or download / copy / paste the files from this repo, open terminal in chosen dir and :

```sh
make
```

## WHAT

Scaffolding bash shell CLI for usual web project tasks. Customizable, extensible toolbox for local (internal) development tasks.

ASC is not a program; it's a generic, customizable "glue" between programs. [Third-party tools](https://paulmicha.github.io/asc/about/tools-considerations.html) integration is provided by extensions having their own separate Git repository. ASC includes by default (for now) a predefined list of extensions - like in the [DrupalVM](https://www.drupalvm.com/) project.

ASC "core" - this repo - contains common utilities related to managing global environment variables, local and remote hosts, project instance self-tests, and the building blocks of the conventions facilitating the implementation of recurrent web project tasks (see *HOW* below).

Important note : ASC is *not* a production hosting tool.

## PURPOSE

ASC helps individual developers or teams to streamline a similar workflow across older and newer projects. It allows to **maintain a common CLI** while easily swapping out [implementations](https://paulmicha.github.io/asc/about/tools-considerations.html) (i.e. "not marrying them").

ASC core provides some generic bash shell functions and scripts. It can generate a `Makefile` for chosen tasks. Most importantly, it organizes scripts around a set of conventions to implement in a **modular** way e.g. :

- host-level dependencies installation / setup (provisioning required packets/apps/services)
- get / generate services credentials
- building / running / stopping / destroying project instances with variants per env. type - e.g. dev, test, live... (i.e. allowing each to have different services or settings)
- generate / (re)write local app settings
- continuous (or on-demand) linting / watching / compiling of some project sources
- host-level setup / removal of periodic task(s) execution (cron jobs)
- automated tests
- deployment
- create / import / backup database
- remote 2-way sync
- etc.

## HOW

Provide some abstractions to complement, combine, replace or add specific operations.

ASC heavily relies on **file structure**, **naming conventions**, and a few concepts :

- **Globals** are the environment variables related to current project instance. They may be declared using the `global` function in files named `env.vars.sh` aggregated during initialization.
- **Bootstrap** is the entry point of any task's execution. It deals with the inclusion of all the relevant scripts and loads global variables (e.g. host type, instance type, etc). Relies on sourcing shell scripts and the fact that *all* commands run from the folder $PROJECT_DOCROOT.
- **Hooks** are function calls mimicking events where "listening" or implementing entails creating some specific file(s) in certain path(s) corresponding to its arguments.

## File structure

```txt
/path/to/project.instance/  ← Project root dir ($PROJECT_DOCROOT)
  ├── asc/                  ← ASC "core" source files. Update = delete + replace entire folder
  │   ├── app/              ← App-level tasks (e.g. watch, compile, deploy, etc.)
  │   ├── env/              ← Default generic global env. vars
  │   ├── extensions/       ← Bundled generic ASC extensions (opt-in : see .asc_extensions_ignore)
  │   ├── git/              ← Integration of Git hooks with ASC hooks + Git-related utilities
  │   │   └── samples/      ← [doc] Examples of git hooks implementations
  │   ├── host/             ← Host-level metadata / crontab / network utils + "abstract" provision action
  │   ├── instance/         ← Actions related to the entire project instance (init, destroy, start, stop)
  │   ├── test/             ← Self-test entry point / automated tests actions
  │   │   └── asc/          ← ASC 'core' internal tests (uses shunit2 - see 'vendor' dir)
  │   ├── utilities/        ← ASC internal functions (hides complexity)
  │   └── vendor/           ← Bundled third-party dependencies (only shunit2 by default)
  ├── scripts/              ← [configurable] default path to current project's scripts ($PROJECT_SCRIPTS)
  │   └── asc/              ← [configurable] ASC-related alterations and/or extensions ($PROJECT_ASC_SCRIPTS)
  │       ├── extend/       ← [optional] Custom, project-specific ASC extension
  │       ├── local/        ← [git-ignored] Generated global env. vars and Makefile specific to this instance
  │       └── override/     ← [optional] Allows to replace virtually any bash file used by ASC
  ├── web/                  ← [optional+configurable] Application dir ($APP_DOCROOT or $APP_GIT_WORK_TREE*)
  │   └── dist/             ← [optional+configurable] Publicly accessible application dir ($APP_DOCROOT*)
  └── .gitignore            ← Replace with your own and/or edit
```

`*` : if using the multi-repo pattern, which is the default assumption.

## WHY

To facilitate tools testing / throwing away what doesn't work *with minimal impact to other parts of the project*. To be more productive.

"*[...] There are core parts of the technology that deliver most of the value / differentiator, and these are important to get right. There’s usually then a bunch of other software and services which is more like scaffolding; **you have it around in order to get stuff done**.*
*[...] “Mash-up” shouldn’t be a dirty hackfest concept.*"

-- From Alex Hudson's article (2017/10/14) : [Software architecture is failing](https://www.alexhudson.com/2017/10/14/software-architecture-failing/)

See also RDX's article (2016/07/20) : [Modern Software Over-Engineering Mistakes](https://medium.com/@rdsubhas/10-modern-software-engineering-mistakes-bc67fbef4fc8).

## High-level Goals

ASC only cares about testing and making [different tools](https://paulmicha.github.io/asc/about/tools-considerations.html) work together as painlessly as possible. The success (or failure) of this tool would be measured in **cognitive ressource** - i.e. how quickly / cheaply can I try other tools together to see if they fit my needs ?

Regading how best to achieve this "economical" objective, my current intuition is to apply focus on [meaning](https://pierrelevyblog.com/2017/12/08/what-is-meaning/) and communication (i.e. naming things as transparently as possible, information design, terse documentation and code comments, etc).

Among secondary goals are :

- [modularity](https://www.youtube.com/watch?v=vypCsVm5z28) - to **hide complexity** by fragmentation (*"people got mad when I put it all in one file"*). "*[Start] with a list of difficult design decisions or design decisions that are likely to change. Each module is then designed to hide such a decision from the others*" -- David Parnas, *on the criteria to be used in decomposing systems into modules* (1971)
- Code generation (WIP)

## Targeted audience

Developers with or without much knowledge on using a terminal (CLI) working under Linux, MacOS, or Windows (using [Git Bash](https://git-for-windows.github.io/) or [Windows Subsystem for Linux ("bash on Ubuntu on Windows")](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux)).

## Preprequisites

- Local host or VM with **Bash shell version 4+** (e.g. MacOS : `brew update && brew install bash && sudo bash -c 'echo /usr/local/bin/bash >> /etc/shells' && chsh -s /usr/local/bin/bash`)
- Git
- Existing project (new or old)
- [optional] Remote host accessible via SSH with Bash 4+
- [optional] *GNU make* in local / remote host(s)

Disclaimer : ASC is currently only tested on Debian and/or Ubuntu Linux hosts.

## Usage / Getting started

There are 2 ways to use ASC in existing or new projects :

1. Use a single, "monolothic" repo for the whole project
1. Keep application code in a separate Git repo (this is the default assumption in the `.gitignore` config featured in this repo)

The files contained in ASC core - this repo - may be placed either inside the application code (in this case `APP_DOCROOT` = `PROJECT_DOCROOT`), inside its parent folder (this is the default assumption and usually has its own separate "dev stack" Git repo), or even anywhere else on the host (see `APP_DOCROOT`, `PROJECT_SCRIPTS` and `APP_GIT_WORK_TREE` global env vars).

So the first step will always be to clone or download / copy / paste the files from this repo to desired location (in relation to your choice for this project instance source files organization described above), then :

1. Review the `.gitignore` file and adapt it to suit your needs.
1. Launch *instance init* action (e.g. run `make` or `make init`) - this will generate `readonly` global env vars and optional Makefile by default. See `asc/instance/instance.inc.sh` and `asc/utilities/global.sh` for details.
1. [optional] launch *host provision* action (e.g. run `make-host-provision`) - this is not implemented in ASC, but this "entry point" exists to streamline host-level software installation in extensions.
1. [optional] launch *instance start* action (e.g. run `make-instance-start`) - this is meant to run any service required to use or work on current project instance.

See *Frequent tasks (howtos / FAQ)* below for other tasks and details.

## Alter / Extend ASC

Altering or extending ASC involves either :

- creating bash shell scripts in the `scripts` dir (this path may be overridden using the `PROJECT_SCRIPTS` global)
- creating your own extension(s) in `asc/extensions` (1 folder = 1 extension)

Here are the different ways to adapt ASC to current project needs :

### Globals

Since every entry point sources `asc/bootstrap.sh` to load ASC functions and globals, these (`readonly`) variables are available everywhere. Their values are assigned during *instance init* which generates a single, git-ignored script : `$INSTANCE_LOCAL_FILES/global.vars.sh` (`scripts/asc/local/global.vars.sh` by default).

One of the most straightforward ways to customize or add globals is by providing your own `global.vars.sh` file in current project instance's `scripts` folder, however any extension can provide its own - be it in the folder of the extension directly, or inside any of its subfolder (called *subjects*).

ASC core provides the followig globals by default (see `asc/env/global.vars.sh`, and `asc/utilities/global.sh` for details about the `global()` function) :

```sh
global PROJECT_DOCROOT "[default]='$PWD' [help]='Absolute path to project instance. All scripts using ASC *must* be run from this dir. No trailing slash.'"
global APP_DOCROOT "[default]='$PROJECT_DOCROOT/web' [help]='The path usually publicly exposed by web servers. Useful if it differs from the rest of current project sources.'"

# [optional] Set these values for applications having their own separate repo.
# @see asc/git/init.hook.sh
global APP_GIT_ORIGIN "[help]='Optional. Ex: git@my-git-origin.org:my-git-account/asc.git. Allows projects to have their own separate repo.'"
global APP_GIT_WORK_TREE "[ifnot-APP_GIT_ORIGIN]='' [default]='$APP_DOCROOT' [help]='Some applications might contain APP_DOCROOT in their versionned sources. This global is the path of the git work tree (if different).'"
global APP_GIT_INIT_CLONE "[ifnot-APP_GIT_ORIGIN]='' [default]=yes [help]='(y/n) Specify if the APP_GIT_ORIGIN repo should automatically be cloned (once) during \"instance init\".'"
global APP_GIT_INIT_HOOK "[ifnot-APP_GIT_ORIGIN]='' [default]=yes [help]='(y/n) Specify a default selection of Git hooks should automatically trigger corresponding ASC hooks. WARNING : will override any git hook script if previously created.'"

global INSTANCE_TYPE "[default]=dev [help]='E.g. dev, stage, prod... It is used as the default variant for hook calls that do not pass any in args.'"
global INSTANCE_DOMAIN "[default]='$(u_instance_domain)' [help]='This value is used to identify different project instances and MUST be unique per host.'"
global PROVISION_USING "[default]=docker-compose [help]='Generic differenciator used by many hooks. It does not have to be explicitly named after the host provisioning tool used. It could be any distinction used as variants in hook implementations.'"
global HOST_TYPE "[default]=local [help]='Idem. E.g. local, remote...'"
global HOST_OS "$(u_host_os)"

global PROJECT_SCRIPTS "[default]=scripts [help]='Path to custom scripts folder. ASC will also use this path to look for extensions, and also overrides and complements (alteration mecanisms).'"
global INSTANCE_LOCAL_FILES "[default]='$PROJECT_SCRIPTS/asc/local' [help]='Path to local, git-ignored files. Contains generated files specific to current project instance, such as global env. vars and Makefile includes.'"

# [optional] Provide additional custom makefile includes, and short subjects
# or actions replacements used for generating Makefile task names.
# @see u_instance_write_mk()
# @see u_instance_task_name()
# @see Makefile
global ASC_MAKE_INC "[append]='$PROJECT_SCRIPTS/asc/extend/make.mk'"
global ASC_MAKE_TASKS_SHORTER "[append]='registry/reg lookup-path/lp'"
```

The syntax can be simpler if all you need is a constant :

```sh
global MY_CONSTANT_VALUE "the value"
```

And if you need to prompt for input during *instance init* (when the `-y` flag is not set), use only the 1st argument :

```sh
global MUST_INPUT_ON_INIT
```

### Hooks

ASC provides basic functions most projects usually need such as instance-specific settings setup and preset commands designed to trigger common tasks (compilation, git hooks, etc).

Some of these tasks expose entry points for extensions to react and implement their own operations. The convention used allows to predict filepaths to use for reacting to given hooks.

It follows the logic behind ASC folder structure, consisting in organizing `actions` by `subject` :

- **folders** represent **subjects**,
- and their **files** represent **actions**.

Excepted files using double extensions (e.g. `my_file.inc.sh`) or beginning with a dot (e.g. `.asc_actions_ignore`), this pattern generates the following default pairs - also called *entry points* by default, here shown with their corresponding *make* shortcut :

```txt
asc/app/compile.sh            - shortcut    $ make app-compile
asc/app/git.sh                - shortcut    $ make app-git
asc/app/install.sh            - shortcut    $ make app-install
asc/app/lint.sh               - shortcut    $ make app-lint
asc/app/watch.sh              - shortcut    $ make app-watch
asc/app/watch_stop.sh         - shortcut    $ make app-watch_stop
asc/git/write_hooks.sh        - shortcut    $ make git-write_hooks
asc/host/provision.sh         - shortcut    $ make host-provision
asc/host/registry_del.sh      - shortcut*   $ make host-reg-del
asc/host/registry_get.sh      - shortcut*   $ make host-reg-get
asc/host/registry_set.sh      - shortcut*   $ make host-reg-set
asc/instance/build.sh         - shortcut**  $ make build
asc/instance/destroy.sh       - shortcut**  $ make destroy
asc/instance/fix_ownership.sh - shortcut**  $ make fix-ownership
asc/instance/fix_perms.sh     - shortcut**  $ make fix-perms
asc/instance/init.sh          - shortcut*** $ make init # (or just "make")
asc/instance/rebuild.sh       - shortcut**  $ make rebuild
asc/instance/registry_del.sh  - shortcut**  $ make reg-del
asc/instance/registry_get.sh  - shortcut**  $ make reg-get
asc/instance/registry_set.sh  - shortcut**  $ make reg-set
asc/instance/start.sh         - shortcut**  $ make start
asc/instance/stop.sh          - shortcut**  $ make stop
asc/test/self_test.sh         - shortcut*** $ make self-test
```

- `*` : Shortening rules can be defined using the `ASC_MAKE_TASKS_SHORTER` global. Ex : `global ASC_MAKE_TASKS_SHORTER "[append]='something_too_long_for_make_shortcut/stlfms'"`
- `**` : The `instance` is implicit by default. It is omitted in ASC core actions for this subject.
- `***` : Some exceptions are hardcoded in this repo's `./Makefile`. Others can be added using the `ASC_MAKE_INC` global. Ex : `global ASC_MAKE_INC "[append]='$PROJECT_SCRIPTS/asc/extend/make.mk'"`

Additional rules :

- Dirnames starting with a dot in `asc/extensions` are excluded from extensions list
- Manual exclusion is possible for either subjects or actions using gitignore-like files (`.asc_subjects_ignore` inside an extension folder, and `.asc_actions_ignore` inside a subject dir).

A

### Extensions

ASC Extensions can provide additional entry points and react to any hook. Any folder present in the `asc/extensions` dir is considered a ASC extension. Their structure and functions follows that of the `asc` dir (see *Hooks*).

TODO [WIP] Provide ability to declare dependencies (i.e. other extensions required to use the current one) by providing a dotfile named `.asc_requires` at the root of the extension dir.

I.e. for `asc/extensions/docker4drupal/.asc_requires` :

```sh
docker-compose:https://github.com/Paulmicha/asc.docker-compose.git
mysql:https://github.com/Paulmicha/asc.mysql.git
```

### Overrides

If the "counterpart" of a given script exists in the folder `$PROJECT_SCRIPTS/asc/override` (`scripts/asc/override` by default), it will be used *instead* of the original file.

This allows to replace any includes or hook implementations.

Example : if we want to override `asc/git/init.hook.sh` - effectively bypassing the existing implementation, we'll create the following file :

```txt
scripts/asc/override/git/init.hook.sh
```

The matching is done by by replacing the leading `asc/` in filepaths with `scripts/asc/override/`. It works for extensions too. Here's an example using an include instead of a hook implementation for a change :

```txt
asc/extensions/docker-compose/docker-compose.inc.sh
-> scripts/asc/override/extensions/docker-compose/docker-compose.inc.sh
```

## Frequent tasks (howtos / FAQ)

TODO
