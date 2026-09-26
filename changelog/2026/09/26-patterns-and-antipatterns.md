# Design patterns and anti-patterns

| Field | Value |
|-------|--------|
| **Date** | 2026-09-26 |
| **Status** | **plan / review**. The split is chosen. Stubs are on disk. Bodies are not filled. Not an implementation go-ahead. |
| **Scope** | `builder` repeats a shape. `checker` names a shape a git diff must not repeat. A later git hook and the Cursor contrib extension call that checker. This note says how, and what that wiring must not do. |
| **Out of this plan** | Filling the three checker entry points. Writing `checker/git/pre-commit.hook.sh`. Setting `ASC_GIT_HOOKS_WIRED`. Filling `make generate`. Moving builder to `asc/builder/`. A gates row. Enabling `agent`, `workflow`, or `asc/cursor`. Copying Cursor rules or skills. Generating `.mdc` files. Importing a host shell template tree. Reordering [25-concert-order.md](./25-concert-order.md). |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), except `$HOME`, `$GIT_DIR`, `$APP_DOCROOT`, `$PROJECT_DOCROOT`, and `$1`.

`gates.core.yml` is a later agent approval surface. Do not add a row for this note.

This note was written on branch `to-review`. The work tree was already dirty, so the mother was not pulled.

Home-directory notes from 2026-09-24 and 2026-09-25 stay in that instance. They are not copied here.

---

## What was chosen

Two opt-in core extensions. The negative list does not live inside `builder`.

| List | Extension | What an agent does |
|------|-----------|--------------------|
| Design pattern | `asc/extensions/builder` | Generate the shape from a template. Do not hand-write a second copy. |
| Anti-pattern | `asc/extensions/checker` | After a diff exists, compare it to the catalog. A hit stops the edit. |

That stop is the agent's job while editing. A git hook exits non-zero only for a record marked `block`. Those are different duties. Both are spelled out below. Neither is implemented.

README scope already names both. The concepts section states the pivots. The core-extensions list names `checker` next to `builder`.

---

## Builder

Unchanged by the checker work. Templates under `asc/extensions/builder/template/`. `make generate` is still the empty substituter in [22-make-generate.md](./22-make-generate.md). `template.entity.yml` and `prototype.entity.yml` stay 0 bytes. The kernel move in [20-builder-kernel-subject.md](./20-builder-kernel-subject.md) stays later.

`file/pattern.able.yml` is a file-subject stub. It is not this catalog.

A host shell that copies a `templates/` directory and rewrites `{{ NAME }}` tokens is the same job as `make generate` directory mode. It stays out of the mother until a human promotes a generic template.

---

## Checker, as stubbed

`checker` is not in `.asc_extensions_ignore`, same as `builder`. It is enabled on this mother.

| Path | Role now |
|------|----------|
| `asc/extensions/checker/global.vars.sh` | Live. `ASC_ANTI_PATTERN_TYPES` appends `asc`. `ASC_SYNONYMS` appends `anti-pattern/code-smell`. The next init that aggregates globals will bake both. |
| `anti/pattern.sh` | Comment only. No shebang, no bootstrap. Intended pivot `anti-pattern` (short name `code-smell`): record one anti-pattern. |
| `anti/pattern/list.sh` | Comment only. Intended pivot `anti-pattern-list`. The synonym replaces the substring, so the short name is `code-smell-list`. Loads the list for a git diff. |
| `diff/inspect.sh` | Comment only. Intended pivot `diff-inspect`. Compares the diff to the loaded list. |

The core group `asc` is the list for an ASC project instance. The list stub names `data/entities/anti-pattern/asc`. README now says that path. The entity plan's instance file is `data/entities/<type>/<id>.yml`, so the spelling to settle is `asc.yml` versus a directory of one file per anti-pattern. The stub has no `.yml`.

`pattern.sh` says "registry entry or entity instance". `inspect.sh` says it reads "the registry". The only concrete path in the stubs is the entity one. Use that. `file_registry` stays one string per key (a flag, a docroot list). An anti-pattern record is not that string. In this note, registry means the checker catalog.

### Name clash

`anti/pattern.sh` and the directory `anti/pattern/` use the same name. Discovery allows `$subject/$action` and `$subject/$object/$action` as two shapes. A file and a directory that share `pattern` is a bad pair. Before the bodies are filled, keep one object directory: `anti/pattern/add.sh` and `anti/pattern/list.sh`. Drop `anti/pattern.sh`. Pivots become `anti-pattern-add` and `anti-pattern-list`. The synonym still shortens both to `code-smell-add` and `code-smell-list`.

Do not fill the scripts in this step. Do not add the house shebang until that rename is accepted, or the empty `anti-pattern` pivot gets published beside `anti-pattern-list`.

### Not these records

| Nearby name | Why it stays separate |
|-------------|------------------------|
| `skill` | A task sidecar, rendered to `.cursor/skills/<id>/SKILL.md`. |
| `gap` | [20-gap-entity-not-core.md](./20-gap-entity-not-core.md). A known bad shape is not an open question. |
| `workflow-next` | Prints a gates row. The concertation set that printer aside. |
| A Cursor rule or skill file | A pointer. The catalog is the record it names. |

Suggested fields, still not accepted: `id`, `detect`, `instead`, and a group (`asc` is the first, via `ASC_ANTI_PATTERN_TYPES`). The hook section adds `block` (default `no`), `audience` (`agent`, `hook`, or both), and `globs`. An instance-only group stays in that instance. No shell in the file. Secrets stay out.

First records are not written. Candidates already decided in [25-concert-order.md](./25-concert-order.md): a long-lived `develop` branch, the home buffer imposed on another repo, a gates row used as the design queue, `file_registry` turned into entities, a blind copy of every Cursor rule.

---

## Git hooks

Design only. No listener file. No change to `ASC_GIT_HOOKS_WIRED`. The hook is a later caller of `diff-inspect`. Wiring it first, while the three checker scripts are comments, either does nothing or rejects every commit the moment someone adds `exit 1`.

### The writer that already exists

[25-wired-init-lists.md](./25-wired-init-lists.md) is in force. `ASC_GIT_HOOKS_WIRED` defaults to empty in `asc/core/global.vars.sh`. `asc/git/init.hook.sh` calls `f_git_write_hooks` only when that variable is non-empty, and it passes that list only. The six names inside `f_git_write_hooks` are what the function uses when its first argument is absent or empty. Instance init never takes that path while the default stays empty. Putting `pre-commit` into the core default undoes that decision.

`asc/git/write_hooks.sh` writes one executable per requested git hook name, into `$APP_DOCROOT/.git/hooks` when `APP_DOCROOT` is non-empty, otherwise into `$PROJECT_DOCROOT/.git/hooks`. The header comment says the app directory is used when it exists, and the project directory otherwise. The function does not check existence before the switch. A non-empty `APP_DOCROOT` whose `.git/hooks` is missing aborts. It does not fall back.

The generated file is this shape (`<name>` is the git hook name):

```bash
cd "$PROJECT_DOCROOT" && \
  . asc/bootstrap.sh && \
  asc_git_hook_args=("$@") && \
  hook -s 'git' -a "<name>" -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE'
```

Consequences for a checker:

- The script saves git's arguments in `asc_git_hook_args` and does not pass them to `hook`. A listener reads that array. `pre-commit` has no useful arguments. `pre-push` puts the remote name and the remote URL in `$1` and `$2`, and the ref list on stdin. Stdin is not copied into the array. Two listeners that both read stdin leave the second at EOF.
- The script has no `set -e`. A listener that `return`s non-zero does not reject the git operation. A listener that `exit`s non-zero does.
- `hook` sources every matching file. `hook_ms` picks one winner. The generated script calls `hook`. A checker file does not replace another `pre-commit` listener. An `exit` inside one of them does skip the rest, because they share the process.
- The comment in the generated file says the file is overwritten every time it is executed. Execution does not rewrite it. `f_git_write_hooks` overwrites it on the next init that lists that hook name.
- `core.hooksPath` is a TODO in `write_hooks.sh`. Checker does not add a second installer.
- The whitelist lists `post-update` twice. Copy the git documentation's names, not that array, if a later change extends the whitelist.

The inactive sample is `asc/git/samples/pre-commit.hook.sh`. It is not discovered: discovery wants `git/pre-commit.hook.sh` on a real subject path, and the sample's own header says so. The sample resets ownership and permissions, then re-adds staged paths. It is the existing picture of a pre-commit listener. A checker that `exit`s first would skip that work on any instance that later enables both.

A checker listener, when one is written, lives at `asc/extensions/checker/git/pre-commit.hook.sh`. Subject `git`, action `pre-commit`, inside the checker extension. The generated call `hook -s git -a pre-commit` matches that path. The Cursor contrib extension does not own this file.

### Which git hook

The comment on `f_git_write_hooks` swaps two hooks. It describes `pre-applypatch` as the check that inspects the tree and refuses a commit. That hook runs for `git am`, after the patch is applied and before that command commits. It does not run for `git commit`.

The commit gate is `pre-commit`. Git invokes it for `git commit`. A non-zero status aborts the commit. `git commit --no-verify` skips it. The same comment already says the bypass exists, and then attaches the refuse-the-commit job to the wrong name.

| Git hook | When git runs it | Can it refuse? | Checker use |
|----------|------------------|----------------|-------------|
| `pre-commit` | `git commit`, on the index about to be committed | Yes. Non-zero aborts. `--no-verify` skips it. | The gate. Calls `diff-inspect` on the index. |
| `pre-applypatch` | `git am` only | Yes, for that am session | Do not wire the catalog here. A normal commit never enters it. |
| `prepare-commit-msg`, `commit-msg` | After the message file exists, before the commit object | Yes | Message text. A diff smell is not a message smell. Leave them unwired. |
| `post-commit` | After the commit object exists | No | Too late to refuse. |
| `pre-push` | Before refs are sent. Remote name and URL in `$1` and `$2`. Refs on stdin. | Yes. `--no-verify` skips it. | Same inspect, for commits that skipped `pre-commit`. Still opt-in. Still not the core default. |
| `post-checkout`, `post-merge` | After the worktree already changed | No | A printout of what now applies. A poor gate. |
| `post-receive` | On the remote, after refs are updated, cwd is `$GIT_DIR` | No. The update already happened. | Do not bootstrap ASC on the server from this hook. |

`post-commit`, `post-merge`, and `post-checkout` are the wrong place to start. They cannot reject the operation that just finished. `post-receive` would run the catalog on a machine that is not the instance that owns `data/entities/anti-pattern/`.

### The diff the hook must read

`diff/inspect.sh` says "a git diff" and does not say which one. A pre-commit listener that runs plain `git diff` reads the worktree against the index. Unstaged lines are not the commit. A smell that exists only in the staged hunk is invisible. A smell that exists only in an unstaged edit is reported for a commit that does not contain it.

The index is `git diff --cached`. A detector that then opens the worktree file still sees the wrong bytes: the worktree can differ from the staged blob. The bytes of the commit are `git show :path` (the index stage). Detectors read that blob, or the cached diff, and not the worktree file.

Partial staging makes this sharper. A hunk can be staged while the rest of the file is not. A whole-file read flags lines the commit does not include.

### Which repository

Two directories are in play.

| Directory | What it is |
|-----------|------------|
| `$PROJECT_DOCROOT` | The ASC instance. Bootstrap runs here. The catalog path `data/entities/anti-pattern/asc` is relative to here. |
| `$APP_DOCROOT` | The application repository, when the instance keeps application source in a second git dir. |

The generated script `cd`s to `$PROJECT_DOCROOT` before `hook` runs. Git's own hook starts at the root of the work tree whose `.git/hooks` fired, and git sets `GIT_DIR` for the hook. After the `cd`, a bare `git diff` follows `GIT_DIR` if it is still set, and follows the new cwd if it is not. Whether bootstrap preserves `GIT_DIR` is unverified. A listener that does not record `GIT_DIR` and the starting work tree will inspect whichever repository the shell happens to be in.

The catalog and the diff are allowed to come from different places only on purpose:

- The diff is the repository whose hook fired.
- The group `asc` (`ASC_ANTI_PATTERN_TYPES`) loads only when that repository is the ASC instance. The list stub already says this: the `asc` list applies to an ASC project instance repo.
- An application repository does not load `asc`. "No long-lived `develop`" and "do not copy every Cursor rule" are core-catalog detects. [25-concert-order.md](./25-concert-order.md) leaves each project's branches to that project. Firing the `asc` group on an application commit applies the instance's branch contract to a repository the concert note kept separate.
- An application repository may load an instance-only group. That group stays in the instance. It is not promoted with the core catalog.

The listener saves the firing repository before any `cd`, passes that path to `diff-inspect`, and selects groups from it. It does not assume cwd and `GIT_DIR` still name the same tree.

### `exit`, siblings, and the `block` flag

`hook` will source every `pre-commit.hook.sh` it finds. The permission sample, if it is ever moved onto a live path, shares that process with the checker. `exit 1` from the checker skips the permission reset and the re-add. `return 1` leaves the commit in place.

An instance that wants both jobs uses one listener that calls them in order, or it wires `pre-commit` with the checker as the only listener. The core checker file does not `exit` on its own if other listeners must still run. The instance's single listener calls `diff-inspect` and then `exit`s when a blocking hit was printed.

Every record grows a `block` field. Suggested, not accepted:

| `block` | Hook behavior |
|---------|----------------|
| unset or `no` | Print the hit and the `instead` pointer. Exit 0. |
| `yes` | Print the hit. The listener exits non-zero. |

The default is `no`. A human sets `yes` only after that detect has matched a real diff on purpose. The first records in this note (branch names, a gates row, a blind rule copy) are not blocking until that trial exists. A vague detect with `block: yes` freezes commits.

The agent's duty stays stricter than the hook's. While editing, any hit stops the edit. The hook refuses only `block: yes`. An unblocked hit is still a hit. The agent does not treat exit 0 as a clean bill.

### What the hook must not do

- Apply a builder template, `git add` the result, or amend. A pre-commit that rewrites the index loops, restages hunks the human left unstaged, and can launder a diff past a review. The hook prints `instead`. `make generate` stays the command a human runs. It is still empty.
- Start a Cursor agent. `scripts/asc/contrib/asc/cursor/agent/wrap.sh` is empty, and `asc/cursor` is in `.asc_extensions_ignore` on this mother. A hook that invokes an agent is a network call on every commit, with no stable exit code.
- Embed an instance's mother-guard search. That search stays in the instance. The `asc` group and any generated rule that syncs must not contain it.
- Set the core default of `ASC_GIT_HOOKS_WIRED` to `pre-commit`.
- Treat `--no-verify` as solved. Agents and humans both skip hooks. `pre-push` catches some of those commits and is skipped by the same flag. This mother has no merge queue ([25-concert-order.md](./25-concert-order.md)). The hook is a local courtesy. It is not the guarantee.
- Read `make git-acp` as a hook. `git-acp` adds the work tree and pushes the current branch. It does not read the catalog. Do not wrap it.

### Branch policy is not a hunk

`long-lived-develop` and the home-directory buffer imposed on another repository are branch facts. `git rev-parse --abbrev-ref HEAD` sees them. `git diff --cached` does not. `diff-inspect` either grows a branch check beside the diff check, or a sibling entry point does, and the same pre-commit listener calls both. A diff-only scanner will miss the records this note already listed, or it will false-positive on the word `develop` inside a file.

Checker does not generate branch names. The branch contract stays the concert note.

### Order, when this leaves plan / review

1. `diff-inspect` reads `--cached` (and the branch name) and prints hits. Exit 0 until a record says `block: yes`. No hook yet. This is the command the hook and the agent both call.
2. Settle the `pattern.sh` / `pattern/` clash and the `.yml` spelling before that body exists.
3. An instance that wants the gate appends `pre-commit` to its own `ASC_GIT_HOOKS_WIRED` and adds the listener `asc/extensions/checker/git/pre-commit.hook.sh`. The listener passes the firing repository, loads `asc` only for the instance repo, and `exit`s only on `block: yes`.
4. `pre-push` repeats that call. Still opt-in. Still absent from the core default. Stdin is read at most once, so this listener is the only pre-push file, or it is the one that consumes stdin and then calls the others with the saved ref list.
5. Cursor projection, below, after the command exists, and only on an instance that enables `asc/cursor`.

---

## Cursor contrib extension

The hook is the backstop. The Cursor extension is the earlier hint, so the agent hears the detect before it commits and then retries blind when the hook fails. Neither replaces the catalog. The catalog stays the checker records.

### What is on disk

`scripts/asc/contrib/asc/cursor/` holds:

| Path | What it does now |
|------|------------------|
| `skill/render.hook.sh` | Writes `.cursor/skills/<id>/SKILL.md` from `SKILL_ID`, `SKILL_DESCRIPTION`, `SKILL_TASK`, and optional `SKILL_BODY`. That is the skill entity's projector. One task, one skill file. |
| `host/cursor_rules_sync.sh` | `make host-cursor-rules-sync`. Compares rule filenames. Copies nothing. |
| `agent/wrap.sh` | Empty. |
| `README.md` | Where Cursor rules load, and the frontmatter table. |

`.asc_extensions_ignore` lists `asc/cursor`. On this mother the contrib extension is off. A hook file added under that tree does not run until an instance removes that line. Enabling it is not this note. `agent` is also ignored, so `skill/render` is not a pivot here even though the projector script exists.

The Cursor README already constrains a projection:

- Project rules are `.mdc` files in the project's `.cursor/rules/`. A plain `.md` in that directory is ignored.
- `alwaysApply: true` loads the rule in every agent chat in that workspace, and the `description` is ignored.
- `alwaysApply: false` plus a `description` and no globs: the agent judges the description.
- `alwaysApply: false` plus `globs`: the rule is included when a matching file is in context.
- Rules apply to agent chat. They do not apply to tab completion or inline edit.
- `host-cursor-rules-sync` does not copy bytes. Shared how-tos stay concert item 4. Instance-only rules stay in the instance.

### Skill render is the wrong projector

An anti-pattern is not a skill. `skill.entity.yml` is one development task (synonyms `procedure`, `playbook`), stored as a sidecar and rendered into `SKILL.md`. Rendering one skill per ban produces a second catalog under `.cursor/skills/` and trips the record this note already rejects (`antipattern-as-skill`).

The projector to add later, on instances that enable `asc/cursor`, is a sibling of `skill/render.hook.sh`. It reads checker records and writes rules. It does not go through `f_skill_render`.

### What the projection contains

One `.mdc` per record whose audience is the agent. Suggested field, not accepted: `audience: agent` or `audience: hook` or both.

| Frontmatter | Value |
|-------------|--------|
| `alwaysApply` | `false` |
| `description` | The record's `detect`, short enough for the agent to judge relevance |
| `globs` | From the record, when the detect cares about paths. Omitted when it does not (a branch-name detect has no glob). |

The body is one pointer: the record id, and the command `diff-inspect`. It does not paste the full catalog, and it does not paste another record. A second copy drifts.

One additional rule, `alwaysApply: true`, one sentence: run `diff-inspect` on the diff before claiming it is done. No `description` on that file, because `alwaysApply: true` ignores `description`. That sentence is the shared how-to from the concert note. It is not a second list.

Generate these files on the instance, from the catalog that instance already has. Do not commit them as the source, and do not teach `host-cursor-rules-sync` to copy them. The sync command will show the filenames. Matching filenames across instances are fine when each instance generated them from the same core records. Instance-only records generate instance-only files and stay put.

A record with a glob uses the glob form. A record with no path (branch policy, a gates-file edit) uses the description form. One record does not set `alwaysApply: true`. That flag is the single sentence above, once.

### What the projection must not contain

- The instance mother-guard search, hostnames, ticket ids, or docroots. A generated rule is a file `host-cursor-rules-sync` will print. A stranger who reads a mother copy of it must not learn who an instance is.
- The instruction to apply a template automatically. The body names `instead` as a pointer. `make generate` remains a human command.
- A call to `agent/wrap.sh`. The file is empty. The hook must not call it either.

### How the two sides meet

1. The agent has the projected rule in context when the globs or the description match. It can avoid the smell before the commit.
2. The human or the agent runs `diff-inspect`. Hits print `id`, `detect`, and `instead`.
3. A human runs `make generate` when `instead` names a builder template that the generate plan can already render. Today that renderer is empty, so `instead` often names an existing plan (the concert note) rather than a template.
4. On commit, the opt-in pre-commit listener runs the same inspect. `block: yes` aborts. Everything else prints.
5. On push, the opt-in pre-push listener runs it again for commits that skipped the first hook.

Tab completion and inline edit never see the rules. The hook is the only check that does not depend on an agent reading them. That is why the hook stays mechanical and local, and why the projection stays a hint.

---

## Sync and concert order

The branch contract stays [25-concert-order.md](./25-concert-order.md). Checker does not generate branch names. `make git-acp` does not read the catalog.

Generic checker files under `asc/extensions/checker/` and generic instances that are committed with the mother move with the forward core mirror, once [23-host-asc-core-sync.md](./23-host-asc-core-sync.md) is allowed. This note does not allow `apply`. Upward copy of a generic anti-pattern is a human promotion after that instance's mother-guard search. Instance-only groups stay put. Generated `.cursor/rules` and `.cursor/skills` stay put with them. `make host-cursor-rules-sync` still compares rule filenames and copies nothing.

Concert order stands. Sidecar path template first, registry left as it is, discover later, shared how-tos as their own pass. This hook design does not jump that queue. The how-to it adds later is the one always-on sentence. That sentence is not a second copy of the records.

---

## Tasks

- [x] Human placed design patterns on `builder` and anti-patterns on `checker`.
- [x] README names both, including the core-group path `data/entities/anti-pattern/asc`.
- [x] Git-hook and Cursor wiring recorded as design. No listener, no wired-list change, no generated rule.
- [ ] Settle `asc.yml` versus a directory of one file per anti-pattern.
- [ ] Replace `anti/pattern.sh` with `anti/pattern/add.sh` before either script grows a body.
- [ ] Leave `file_registry` as one string per key. The checker catalog is the entity path.
- [ ] Accept `block`, `audience`, and `globs` before a listener or a rule projector exists. Default `block` is `no`.
- [ ] `diff-inspect` reads the index (`git diff --cached` or `git show :path`) and the branch name. Exit 0 until a record is marked `block: yes`. Prove `GIT_DIR` still names the repository whose hook fired.
- [ ] Do not set the core default of `ASC_GIT_HOOKS_WIRED`. An instance appends `pre-commit` itself. `pre-applypatch`, `post-receive`, and `make git-acp` stay unwired.
- [ ] Load the `asc` group only for the ASC instance repository. An application repository under `APP_DOCROOT` does not inherit it.
- [ ] Cursor projector, later, only where `asc/cursor` is enabled. One `.mdc` per agent-facing record, plus one always-on sentence. Not `skill/render`. Not a call to `agent/wrap.sh`.
- [ ] Do not fill `make generate`, and do not add a gates row, from this note.
- [ ] Leave [25-concert-order.md](./25-concert-order.md) as the queue.
