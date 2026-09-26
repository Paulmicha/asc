# Retire the app-repo clone switch

| Field | Value |
|-------|--------|
| **Date** | 2026-09-26 |
| **Status** | Plan. No runtime change until `gates.core.yml` has `go: yes` for this file. |
| **Scope** | The initial application-repo clone during instance init, and which repo `ASC_GIT_HOOKS_WIRED` writes into. |
| **Not this change** | `APP_DOCROOT` and `APP_DOCROOT_C` outside the hook writer, Drupal, Apache, Moodle, and the known-hosts read of `APP_GIT_ORIGIN`. Those stay in the appendix. |

`$` in this file is the ASC docs placeholder (`$subject`, `$action`), except shell variables inside code blocks.

Do not commit unless asked. Do not implement from this note alone.

## Decision

Instance init calls `hook_ms` once per subject in the app portion of the subject list, action `clone`. That portion is `ASC_APPS` when set, otherwise `app`. `ensure_dirs_exist` uses the same names plus `instance`. This call does not.

Core ships no hook implementation. An instance clones by adding `clone.hook.sh` under an active dir whose name is that subject. One file wins per subject: the most specific match, so a variant file wins over the plain file, and an instance active dir wins over a generic one.

On clone failure the hook implementation `return`s non-zero. `hook_ms` writes its lookup cache in the `hook -t` pass, then sources the chosen file as its last command, so that `return` becomes the status of `hook_ms`. Init uses `hook_ms … || return $?`. A later subject does not run. `f_instance_init` is the last command of `asc/instance/init.sh`, and setup already stops when init's status is non-zero. `exit 1` inside the implementation also aborts the process. It is not required for this call.

`APP_GIT_INIT_CLONE` goes away. The clone block in `asc/git/init.hook.sh` goes with it. `ASC_GIT_HOOKS_WIRED` writing stays in that file.

## Why

Today `f_instance_init` in `asc/instance/instance.inc.sh` calls `hook -a 'init'`. That sources `asc/git/init.hook.sh`. The file clones when `APP_GIT_INIT_CLONE` matches `[Yy]*`, `APP_GIT_ORIGIN` and `APP_DOCROOT` are set, and `$APP_DOCROOT/.git` is missing. A missing directory runs `git clone`. A directory that already exists runs `git init`, adds `origin`, fetches, and checks out `origin/master` with `-f`. No `global` declaration for those three names remains in `asc/core/global.vars.sh`.

The opt-in is a global the mother still executes. The replacement opt-in is a file the instance adds when that instance wants a clone.

## Cold init, before the clone

`asc/instance/init.sh` sets `ASC_BS_SKIP_GLOBALS=1` and sources `asc/bootstrap.sh` before `f_instance_init`. On a cold tree (or a stamp miss) that bootstrap already runs `f_asc_extend`, writes `data/asc/cache/core/active.sh` and the stamp, and wipes `data/asc/cache/hook/`. `extend` is discovered when `scripts/asc/extend` exists, and it is never ignore-listed. Subject names are the directories on disk at that moment.

`f_instance_init` then assigns `ASC_APPS`, `INSTANCE_TYPE`, `HOST_TYPE`, `STACK_VERSION`, and `PROVISION_USING` from arguments and `env.yml`, aggregates globals into the current shell, writes `globals.sh` and `.env`, and generates `pivots.mk`. The order below is after that, and after `hook -p 'pre' -a 'init'`.

By then a `hook_ms` call can resolve a subject directory that existed before this process started, and the hook implementation can read the shell globals just aggregated. It does not need `globals.sh` to have been sourced (this process skipped that), the post-init hook-cache warmup, make's generated pivots, or running services. The first lookup is live: the hook cache for this call is empty on cold init.

A clone file added later inside a subject directory that already existed does not change the discovery stamp (stamp v1). A warm hook cache can keep hiding it until `make cc` or a stamp miss. The first cold init does not have that cache.

## Hook call

In `f_instance_init`, after `hook -p 'pre' -a 'init'`, before `hook -a 'init'`:

```sh
for subject in $subjects; do
  hook_ms -s "$subject" \
    -a 'clone' \
    -v 'STACK_VERSION PROVISION_USING HOST_TYPE INSTANCE_TYPE' || return $?
done
```

The dry-run branch (`p_ascii_dry_run`) does not call `hook_ms`. It calls `hook -s "$subjects" -a 'clone' -p 'dry_run'`, which looks up `dry_run_clone.hook.sh` and does not source `clone.hook.sh`.

A namespace that does not list the subject is skipped (`f_asc_namespace_has_subject`). A stock tree has no `app` active dir and no `clone.hook.sh`, so each call sources nothing.

An instance that wants the clone adds an active dir named for that subject before init, for example `scripts/asc/extend/app/clone.hook.sh` when the subject is `app`, or `scripts/asc/extend/site/clone.hook.sh` when `ASC_APPS` is `site`. The mother does not add this file, a sample, or a make pivot.

The hook implementation owns the remote, the destination path, and the branch. When the destination already has `.git`, it returns without cloning. On failure it `return`s non-zero. Core does not read `APP_GIT_INIT_CLONE`, `APP_GIT_ORIGIN`, or `APP_DOCROOT` to decide. The forced `origin/master` checkout is not reimplemented in core.

## What stays in the git init hook implementation

`asc/git/init.hook.sh` still writes the git hooks named in `ASC_GIT_HOOKS_WIRED` (empty writes none). Its header comment stops saying that core clones the application repo. The destination of that write changes as in the next section. `APP_GIT_ORIGIN` in `asc/extensions/remote_instance/remote/init.sh` stays a known-hosts read. `APP_GIT_INIT_HOOK` stays a historical name.

## Wired hooks, several repos

`f_git_write_hooks` today takes an optional hooks directory. With that argument empty it sets the directory to `$PROJECT_DOCROOT/.git/hooks`, then replaces it with `$APP_DOCROOT/.git/hooks` whenever `APP_DOCROOT` is non-empty, then `exit 1`s if that directory is missing. The header comment describes a fallback the function does not do. The generated script always `cd`s to `$PROJECT_DOCROOT` and calls `hook -s 'git' -a "$git_hook"`. Listeners cannot tell the instance repo from a sub-repo.

`ASC_GIT_HOOKS_WIRED` stays the only list. Empty still writes none. There is no `wire` action and no second global. A token is either a bare git hook name or `context:name`.

| Token | Writes | `git_hook_context` |
| --- | --- | --- |
| `pre-commit` | `$PROJECT_DOCROOT/.git/hooks/pre-commit`. Today, with `APP_DOCROOT` set, this token writes the app repo instead. | empty |
| `asc:pre-commit` | the instance-repo file | `asc` |
| `site:pre-commit` | `$SITE_DOCROOT/.git/hooks/pre-commit` | `site` |

`asc` is the dev stack repo (`$PROJECT_DOCROOT`). Any other context is an app subject: the work tree is the global whose name is that subject in uppercase plus `_DOCROOT`, the sketch already next to `ASC_APPS` in `asc/core/global.vars.sh` (`SITE_DOCROOT`, and the same shape for another subject). A focused test suite uses its own subject the same way (`suite:pre-commit` reads `SUITE_DOCROOT`).

A context matches `^[A-Za-z_][A-Za-z0-9_]*$`, so the `_DOCROOT` name is a valid shell variable. `my-site` is rejected. `asc` is reserved and does not read `ASC_DOCROOT`. The name after the colon stays on the existing whitelist. One colon. A bad token `exit 2`s, the same as an unknown hook name, and writes nothing.

A bare name and `asc:` for the same hook name are one file. Either order (`pre-commit asc:pre-commit` or the reverse) sets `git_hook_context=asc`. Two contexts whose directories are the same path, including a subject whose `_DOCROOT` is `$PROJECT_DOCROOT`, `exit 1` before any write. Different contexts with different directories are different files.

Argument 2 of `f_git_write_hooks` stays the explicit hooks directory for bare names. `f_git_write_hooks 'pre-commit' "$dir"` in `asc/test/core/git_readme_toc.test.sh` keeps that meaning, and `git_hook_context` in that file is empty. A non-empty argument 2 together with any `context:name` token `exit 2`s before a write. Init calls the function with the list only.

The writer drops `APP_DOCROOT` as a destination. After a successful write of a hook name, it deletes `$APP_DOCROOT/.git/hooks/<name>` when that path is set, is not one of the destinations just written for that name, and the file contains the generated-file marker `automatically generated during "instance init"`. Other files in that directory stay. An old generated hook whose directory is no longer `APP_DOCROOT` is not found by this pass. The instance removes that file itself before reinit.

Every generated script still starts with `cd "$PROJECT_DOCROOT"` and the bootstrap, including a script installed in a sub-repo. Git may start the script in that sub-repo. ASC still runs from the instance docroot. Next to `git_hook_args_nb` and `git_hook_args`, the script sets `git_hook_context` to the context token, or to empty for a bare name. The hook call stays `hook -s 'git' -a "$git_hook"`.

`hook` sources every match, then writes its cache. A `return` in one listener leaves that file only. Later listeners still run, and the cache write leaves `hook` with status 0. A listener that must reject the git command `exit`s, which `asc/git/pre-commit.hook.sh` already does when the contents update fails. A listener that does not apply to this context `return 0`s.

`asc/git/pre-commit.hook.sh` updates the instance README. When `git_hook_args_nb` is set and `git_hook_context` is neither empty nor `asc`, it `return 0`s before that update. An app commit then leaves the instance README and its index untouched. Empty and `asc` keep today's update.

A listed context whose `.git/hooks` directory is missing, or whose `_DOCROOT` global is empty, is `exit 1`. The clone loop runs first, so a sub-repo declared in the list can exist before the writer runs. Dry-run does not write hook files.

## Pros and cons

Pros: the mother stops cloning on a `Y`/`y` global. Several subjects in `ASC_APPS` can each implement `clone`. A tree with no such file clones nothing.

Cons: an instance that relies on `APP_GIT_INIT_CLONE` today gets no clone until it adds the hook implementation. A bare name moves from `APP_DOCROOT` to the instance repo; the writer deletes only a generated hook left at the old `APP_DOCROOT` path. `site:pre-commit` `exit 1`s when `SITE_DOCROOT/.git/hooks` is missing. A subject that is not discovered yet is skipped by the clone call.

Recommendation: make the hook call and delete the clone block. Do not leave a core `clone.hook.sh` that still reads the old globals.

## When `go` is yes

1. In `f_instance_init` (`asc/instance/instance.inc.sh`), after `hook -p 'pre' -a 'init'` and before `hook -a 'init'`, loop the app subject list and call `hook_ms` once per subject as above, with `|| return $?`. On the dry-run path, call `hook` with `-p 'dry_run'` and do not call `hook_ms`.
2. Delete the `case "$APP_GIT_INIT_CLONE"` block from `asc/git/init.hook.sh` (the clone and the non-empty-directory `git init` / `fetch` / `checkout -t origin/master -f`). Keep the call to `f_git_write_hooks` with `ASC_GIT_HOOKS_WIRED`. Rewrite the header so it describes hook writing only.
3. In `f_git_write_hooks`, parse each token as a bare hook name or `context:name`. Drop the `APP_DOCROOT` write destination. Argument 2 applies only to bare names. A context token with argument 2 set `exit 2`s. Write bare names and `asc:` into `$PROJECT_DOCROOT/.git/hooks` unless argument 2 set a directory for the bare names. Write any other context into `$SUBJECT_DOCROOT/.git/hooks`. Reject a context that is not `^[A-Za-z_][A-Za-z0-9_]*$`, and reject two contexts that share one directory. Set `git_hook_context` in the generated script. Keep `cd "$PROJECT_DOCROOT"` and `hook -s 'git'`. `exit 1` when a listed context has no hooks directory. After the write, delete a generated hook at `$APP_DOCROOT/.git/hooks/<name>` when that path is not a destination for that name.
4. In `asc/git/pre-commit.hook.sh`, when `git_hook_args_nb` is set and `git_hook_context` is neither empty nor `asc`, `return 0` before updating the instance README.
5. Rewrite the two comments in `scripts/asc/contrib/asc/drupalwt/new/project.sh` that still say instance init clones when `APP_GIT_INIT_CLONE` is `yes`. Leave that script's directory handling as it is.
6. Add `asc/test/core/clone_hook.test.sh`. `make test-core` already runs `asc/test/core/*.test.sh`. Run the behavior in a subshell, with fixtures (temporary active dirs and `clone.hook.sh` files, hook cache cleared). Assert:
   - with no `clone.hook.sh`, the call sources nothing
   - two app subjects each run their own `hook_ms` winner
   - the dry-run path does not source an ordinary `clone.hook.sh`
   - a fixture that `return 7`s makes `hook_ms` status `7`, and `|| return` stops before the next subject
   - a second call leaves an existing `.git` directory in place
7. Extend `asc/test/core/git_readme_toc.test.sh`. Keep `f_git_write_hooks 'pre-commit' "$dir"` writing that directory with `git_hook_context` empty. Assert, in a subshell, with two git repositories:
   - `my-site:pre-commit` exits 2 and writes nothing
   - `pre-commit` plus a non-empty argument 2 with `site:pre-commit` in the same list exits 2 and writes nothing
   - `site:pre-commit` and `app:pre-commit` with both `_DOCROOT` values equal exits 1 and writes nothing
   - `pre-commit asc:pre-commit` and `asc:pre-commit pre-commit` each write one instance file with `git_hook_context=asc`
   - executing the generated `site` hook leaves the instance README and its index unchanged
   - a generated file under `APP_DOCROOT` that contains `automatically generated during "instance init"` is removed when that path is no longer a destination
8. Run `make test-core`. The new tests pass. Unrun stays unverified.

No new global, no new include. The cold-order note is the README proposal beside the warming list. Implementation leaves the human lines as they are.

## Appendix: APP_ inventory

Snapshot: 2026-09-26, current ASC working tree. Survey for the names this plan does not retire. No runtime behavior has been changed.

Scope: recursive text search including hidden and git-ignored files, excluding `.git/`. Includes core, extensions, contrib, templates, examples, comments, changelogs and local generated data. Git history and the old CWT repository are outside the inventory. Counts are matching source lines per variable, not token counts; a line can contain more than one variable. This report is excluded from subsequent inventory scans.

Four names have executable/configuration uses; a fifth occurs only in historical documentation. No `APP_` variable appears in `asc/core/global.vars.sh`. No exact `APP_` references were found in the current `.env` or `data/asc/globals.sh`.

| Variable | Matching lines | Files | Status |
| --- | ---: | ---: | --- |
| `APP_DOCROOT` | 65 | 18 | Executable/configuration uses remain |
| `APP_DOCROOT_C` | 20 | 6 | Executable/configuration uses remain |
| `APP_GIT_INIT_CLONE` | 3 | 2 | Executable/configuration uses remain |
| `APP_GIT_INIT_HOOK` | 2 | 1 | Historical documentation only |
| `APP_GIT_ORIGIN` | 6 | 2 | Executable/configuration uses remain |

## Planning context

- `asc/core/global.vars.sh:72` declares `ASC_APPS` with default `site`; nearby comments sketch `SITE_DOCROOT`, `SITE_DOCROOT_C`, domains and services. These comments are design context, not implemented replacements for the legacy consumers.
- `asc/instance/instance.inc.sh` already loops over `ASC_APPS` for hook subjects (for example lines 231–236 and 500–505). Its app-specific YAML Git/path handling at lines 160–170 is commented out.
- The clone switch uses the subject list above (`ASC_APPS`, or `app`). A `context:name` token in `ASC_GIT_HOOKS_WIRED` uses that same subject as the context, and the work tree global `SUBJECT_DOCROOT`.
- Container paths, host paths and web-server document roots must remain distinct. Updating the path globals also affects derived globals, generated configuration, mounts and cron commands.
- The current `.asc_extensions_ignore` lists `remote`, `remote_instance`, `asc/apache`, `asc/drupalwt`, `asc/drupalwt_d4d` and `asc/moodle_d4php`. Their references are still included because they remain in the project and may be enabled in other instances.
- `ASC_GIT_HOOKS_WIRED` is the hook-list setting. A bare name writes the instance repo. `asc:pre-commit` sets `git_hook_context=asc` there. `site:pre-commit` writes `SITE_DOCROOT`. The writer still uses `APP_DOCROOT` until this plan lands.

## Every exact APP_ location

Each entry links to its source line and reproduces the matching text. “Comment” identifies a source comment; “documentation” identifies Markdown prose. Other entries are code/configuration, including templates and samples.

### APP_DOCROOT

Host application directory. Used by core Git cloning, hook placement and Git helper defaults; Drupal creation, permissions, ownership and config paths; Apache templates; Drupal/Moodle bind mounts. No literal global declaration remains. The Drupal alias still assigns a fallback of `app` using `${APP_DOCROOT:=app}`.

- [asc/core/global.manual-inc.sh:630](/home/paul/Documents/asc/asc/core/global.manual-inc.sh:630) — comment

  ```text
  # global SERVER_DOCROOT_C "[if-SERVER_DOCROOT]='$APP_DOCROOT/docroot' [true]=/var/www/html/docroot [false]=/var/www/html/web [index]=1"
  ```

- [asc/extensions/remote/remote.inc.sh:258](/home/paul/Documents/asc/asc/extensions/remote/remote.inc.sh:258) — comment

  ```text
  #       local: '{{ APP_DOCROOT }}/path/to/public-files_arr
  ```

- [asc/extensions/remote/remote.inc.sh:263](/home/paul/Documents/asc/asc/extensions/remote/remote.inc.sh:263) — comment

  ```text
  # - Any global (env) var, e.g. {{ APP_DOCROOT }}, will be replaced by their
  ```

- [asc/extensions/remote/remote.inc.sh:455](/home/paul/Documents/asc/asc/extensions/remote/remote.inc.sh:455) — comment

  ```text
  #           local: '{{ APP_DOCROOT }}/private'
  ```

- [asc/extensions/remote/remote.inc.sh:531](/home/paul/Documents/asc/asc/extensions/remote/remote.inc.sh:531) — comment

  ```text
  #   export REMOTE_INSTANCE_FILES_PRIVATE_LOCAL='{{ APP_DOCROOT }}/private'
  ```

- [asc/git/git.opt-inc.sh:740](/home/paul/Documents/asc/asc/git/git.opt-inc.sh:740) — comment

  ```text
  # @param 1 [optional] String : the git "working dir". Defaults to $APP_DOCROOT.
  ```

- [asc/git/git.opt-inc.sh:764](/home/paul/Documents/asc/asc/git/git.opt-inc.sh:764) — code/configuration

  ```text
  p_git_work_tree="$APP_DOCROOT"
  ```

- [asc/git/git.opt-inc.sh:778](/home/paul/Documents/asc/asc/git/git.opt-inc.sh:778) — comment

  ```text
  # @param 1 [optional] String : the git "working dir". Defaults to $APP_DOCROOT.
  ```

- [asc/git/git.opt-inc.sh:802](/home/paul/Documents/asc/asc/git/git.opt-inc.sh:802) — code/configuration

  ```text
  p_git_work_tree="$APP_DOCROOT"
  ```

- [asc/git/git.opt-inc.sh:827](/home/paul/Documents/asc/asc/git/git.opt-inc.sh:827) — code/configuration

  ```text
  if [[ -z "$work_tree" ]] && [[ -n "$APP_DOCROOT" ]]; then
  ```

- [asc/git/git.opt-inc.sh:828](/home/paul/Documents/asc/asc/git/git.opt-inc.sh:828) — code/configuration

  ```text
  p_git_work_tree="$APP_DOCROOT"
  ```

- [asc/git/init.hook.sh:24](/home/paul/Documents/asc/asc/git/init.hook.sh:24) — code/configuration

  ```text
  && [[ -n "$APP_DOCROOT" ]] \
  ```

- [asc/git/init.hook.sh:25](/home/paul/Documents/asc/asc/git/init.hook.sh:25) — code/configuration

  ```text
  && [[ ! -d "$APP_DOCROOT/.git" ]]
  ```

- [asc/git/init.hook.sh:28](/home/paul/Documents/asc/asc/git/init.hook.sh:28) — code/configuration

  ```text
  if [[ ! -d "$APP_DOCROOT" ]]; then
  ```

- [asc/git/init.hook.sh:29](/home/paul/Documents/asc/asc/git/init.hook.sh:29) — code/configuration

  ```text
  git clone "$APP_GIT_ORIGIN" "$APP_DOCROOT"
  ```

- [asc/git/init.hook.sh:41](/home/paul/Documents/asc/asc/git/init.hook.sh:41) — code/configuration

  ```text
  git init "$APP_DOCROOT"
  ```

- [asc/git/samples/pre-commit.hook.sh:26](/home/paul/Documents/asc/asc/git/samples/pre-commit.hook.sh:26) — code/configuration

  ```text
  f_git_get_staged_files "$APP_DOCROOT" '' 'staged'
  ```

- [asc/git/write_hooks.sh:25](/home/paul/Documents/asc/asc/git/write_hooks.sh:25) — comment

  ```text
  # Applies to folder "$APP_DOCROOT/.git/hooks" if it exists, otherwise to
  ```

- [asc/git/write_hooks.sh:68](/home/paul/Documents/asc/asc/git/write_hooks.sh:68) — comment

  ```text
  #   "$APP_DOCROOT/.git/hooks" if it exists, otherwise to
  ```

- [asc/git/write_hooks.sh:87](/home/paul/Documents/asc/asc/git/write_hooks.sh:87) — code/configuration

  ```text
  if [[ -n "$APP_DOCROOT" ]]; then
  ```

- [asc/git/write_hooks.sh:88](/home/paul/Documents/asc/asc/git/write_hooks.sh:88) — code/configuration

  ```text
  p_git_hook_dir="$APP_DOCROOT/.git/hooks"
  ```

- [asc/git/write_hooks.sh:138](/home/paul/Documents/asc/asc/git/write_hooks.sh:138) — comment

  ```text
  # APP_DOCROOT or PROJECT_DOCROOT.
  ```

- [changelog/2026/09/26-patterns-and-antipatterns.md:10](/home/paul/Documents/asc/changelog/2026/09/26-patterns-and-antipatterns.md:10) — documentation

  ```text
  `$` in this file is the ASC docs placeholder (`$subject` / `$action`), except `$HOME`, `$GIT_DIR`, `$APP_DOCROOT`, `$PROJECT_DOCROOT`, and `$1`.
  ```

- [changelog/2026/09/26-patterns-and-antipatterns.md:91](/home/paul/Documents/asc/changelog/2026/09/26-patterns-and-antipatterns.md:91) — documentation

  ```text
  `asc/git/write_hooks.sh` writes one executable per requested git hook name, into `$APP_DOCROOT/.git/hooks` when `APP_DOCROOT` is non-empty, otherwise into `$PROJECT_DOCROOT/.git/hooks`. The header comment says the app directory is used when it exists, and the project directory otherwise. The function does not check existence before the switch. A non-empty `APP_DOCROOT` whose `.git/hooks` is missing aborts. It does not fall back.
  ```

- [changelog/2026/09/26-patterns-and-antipatterns.md:156](/home/paul/Documents/asc/changelog/2026/09/26-patterns-and-antipatterns.md:156) — documentation

  ```text
  | `$APP_DOCROOT` | The application repository, when the instance keeps application source in a second git dir. |
  ```

- [changelog/2026/09/26-patterns-and-antipatterns.md:302](/home/paul/Documents/asc/changelog/2026/09/26-patterns-and-antipatterns.md:302) — documentation

  ```text
  - [ ] Load the `asc` group only for the ASC instance repository. An application repository under `APP_DOCROOT` does not inherit it.
  ```

- [scripts/asc/contrib/asc/apache/config/apache_vhost.tpl.conf:4](/home/paul/Documents/asc/scripts/asc/contrib/asc/apache/config/apache_vhost.tpl.conf:4) — code/configuration

  ```text
  DocumentRoot {{ PROJECT_DOCROOT }}/{{ APP_DOCROOT }}
  ```

- [scripts/asc/contrib/asc/apache/config/apache_vhost.tpl.conf:6](/home/paul/Documents/asc/scripts/asc/contrib/asc/apache/config/apache_vhost.tpl.conf:6) — code/configuration

  ```text
  <Directory {{ PROJECT_DOCROOT }}/{{ APP_DOCROOT }}>
  ```

- [scripts/asc/contrib/asc/drupalwt/app/fs_ownership_pre_set.hook.sh:22](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/app/fs_ownership_pre_set.hook.sh:22) — code/configuration

  ```text
  if [[ -n "$APP_DOCROOT" ]]; then
  ```

- [scripts/asc/contrib/asc/drupalwt/app/fs_ownership_pre_set.hook.sh:25](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/app/fs_ownership_pre_set.hook.sh:25) — code/configuration

  ```text
  chown "$FS_OWNER:$FS_GROUP" "$APP_DOCROOT" -R
  ```

- [scripts/asc/contrib/asc/drupalwt/app/fs_perms_pre_set.hook.sh:22](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/app/fs_perms_pre_set.hook.sh:22) — code/configuration

  ```text
  if [[ -n "$APP_DOCROOT" ]]; then
  ```

- [scripts/asc/contrib/asc/drupalwt/app/fs_perms_pre_set.hook.sh:28](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/app/fs_perms_pre_set.hook.sh:28) — code/configuration

  ```text
  (find "$APP_DOCROOT" -type f -exec chmod $FS_NW_FILES {} +) 2> /dev/null
  ```

- [scripts/asc/contrib/asc/drupalwt/app/fs_perms_pre_set.hook.sh:31](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/app/fs_perms_pre_set.hook.sh:31) — code/configuration

  ```text
  (find "$APP_DOCROOT" -type d -exec chmod $FS_NW_DIRS {} +) 2> /dev/null
  ```

- [scripts/asc/contrib/asc/drupalwt/app/global.vars.sh:23](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/app/global.vars.sh:23) — code/configuration

  ```text
  global DRUPAL_CONFIG_SYNC_DIR "[default]=$APP_DOCROOT/config/sync"
  ```

- [scripts/asc/contrib/asc/drupalwt/app/global.vars.sh:40](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/app/global.vars.sh:40) — code/configuration

  ```text
  global EXECUTABLE_DIRS "[ifnot-DRUPAL_VERSION]=7 [append]=$APP_DOCROOT/vendor"
  ```

- [scripts/asc/contrib/asc/drupalwt/asc/alias.lamp.hook.sh:13](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/asc/alias.lamp.hook.sh:13) — code/configuration

  ```text
  alias drupal="${APP_DOCROOT:=app}/vendor/drupal/console/bin/drupal --root=${SERVER_DOCROOT:=/var/www/html}"
  ```

- [scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:270](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:270) — comment

  ```text
  #   "$PROJECT_DOCROOT/$APP_DOCROOT/config/sync" => '../config/sync'
  ```

- [scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:874](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:874) — comment

  ```text
  # it contains the APP_DOCROOT (otherwise the ensure_dirs_exist.hook.sh
  ```

- [scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:879](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:879) — comment

  ```text
  # TODO limit this treatment to relative paths starting with APP_DOCROOT ?
  ```

- [scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:881](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:881) — code/configuration

  ```text
  local to_remove="$APP_DOCROOT/"
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:9](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:9) — comment

  ```text
  #   the folder $APP_DOCROOT be empty, the default behavior is to delete
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:25](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:25) — comment

  ```text
  #   # $APP_DOCROOT folder exists, by default, its content is deleted first. And
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:32](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:32) — comment

  ```text
  #   # Same, but if the $APP_DOCROOT folder exists and is not empty, in case of
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:40](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:40) — comment

  ```text
  #   # *disarding* any conflicting pre-existing files in $APP_DOCROOT folder :
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:78](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:78) — code/configuration

  ```text
  tmp_merge_dir="${APP_DOCROOT}.tmp.bak"
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:80](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:80) — code/configuration

  ```text
  if [[ -d "$APP_DOCROOT" ]]; then
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:81](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:81) — code/configuration

  ```text
  echo "  The command 'composer create-project' requires the folder '$APP_DOCROOT' to be empty."
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:86](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:86) — comment

  ```text
  # tree - meaning just the "$APP_DOCROOT/.git" folder, and nothing else.
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:89](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:89) — code/configuration

  ```text
  rm -rf $APP_DOCROOT/*
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:90](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:90) — code/configuration

  ```text
  rm -rf $APP_DOCROOT/.* 2>/dev/null
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:99](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:99) — code/configuration

  ```text
  echo "  -> Make a temporary copy of the '$APP_DOCROOT' dir."
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:106](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:106) — code/configuration

  ```text
  echo "  -> Make a temporary copy of the '$APP_DOCROOT' dir."
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:111](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:111) — comment

  ```text
  # Temporarily move the $APP_DOCROOT folder for both these cases :
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:113](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:113) — code/configuration

  ```text
  mv "$APP_DOCROOT" "$tmp_merge_dir"
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:117](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:117) — code/configuration

  ```text
  echo "Error in $BASH_SOURCE line $LINENO: unable to temporarily move the '$APP_DOCROOT' dir (to '$tmp_merge_dir')." >&2
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:127](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:127) — code/configuration

  ```text
  destination_dir="$APP_DOCROOT"
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:146](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:146) — code/configuration

  ```text
  f_fs_merge_dirs "$tmp_merge_dir" "$APP_DOCROOT" "$merge_overwrite"
  ```

- [scripts/asc/contrib/asc/drupalwt_d4d/app/global.compose.vars.sh:18](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt_d4d/app/global.compose.vars.sh:18) — code/configuration

  ```text
  global SERVER_DOCROOT_C "[if-SERVER_DOCROOT]='$APP_DOCROOT/docroot' [true]=/var/www/html/docroot [false]=/var/www/html/web"
  ```

- [scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:37](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:37) — code/configuration

  ```text
  - ./$APP_DOCROOT:$APP_DOCROOT_C
  ```

- [scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:90](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:90) — code/configuration

  ```text
  - ./$APP_DOCROOT:$APP_DOCROOT_C
  ```

- [scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:113](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:113) — code/configuration

  ```text
  - ./$APP_DOCROOT:$APP_DOCROOT_C
  ```

- [scripts/asc/contrib/asc/moodle_d4php/global.vars.sh:39](/home/paul/Documents/asc/scripts/asc/contrib/asc/moodle_d4php/global.vars.sh:39) — code/configuration

  ```text
  global MOODLE_CONFIG_FILE "[default]=$APP_DOCROOT/config.php"
  ```

- [scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:17](/home/paul/Documents/asc/scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:17) — code/configuration

  ```text
  - ./$APP_DOCROOT:$APP_DOCROOT_C
  ```

- [scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:41](/home/paul/Documents/asc/scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:41) — code/configuration

  ```text
  - ./$APP_DOCROOT:$APP_DOCROOT_C
  ```

- [scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:62](/home/paul/Documents/asc/scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:62) — code/configuration

  ```text
  - ./$APP_DOCROOT:$APP_DOCROOT_C
  ```


### APP_DOCROOT_C

Container application directory. Declared with default `/var/www/html` in Drupal Docker and Moodle contrib globals. Used for container path conversion, Drupal config, Composer destination, bind mounts and cron commands.

- [scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:293](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:293) — comment

  ```text
  # to APP_DOCROOT_C. It must be absolute for the conversion to work.
  ```

- [scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:294](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:294) — code/configuration

  ```text
  if [[ "${var_val:0:1}" != '/' ]] && [[ "${APP_DOCROOT_C:0:1}" == '/' ]]; then
  ```

- [scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:295](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:295) — code/configuration

  ```text
  var_val="$APP_DOCROOT_C/$var_val"
  ```

- [scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:417](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:417) — comment

  ```text
  # to APP_DOCROOT_C. It must be absolute for the conversion to work.
  ```

- [scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:418](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:418) — code/configuration

  ```text
  if [[ "${var_val:0:1}" != '/' ]] && [[ "${APP_DOCROOT_C:0:1}" == '/' ]]; then
  ```

- [scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:419](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:419) — code/configuration

  ```text
  var_val="$APP_DOCROOT_C/$var_val"
  ```

- [scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:878](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/drupalwt.inc.sh:878) — comment

  ```text
  # to APP_DOCROOT_C.
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:129](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:129) — code/configuration

  ```text
  if [[ -n "$APP_DOCROOT_C" ]]; then
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:130](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:130) — code/configuration

  ```text
  destination_dir="$APP_DOCROOT_C"
  ```

- [scripts/asc/contrib/asc/drupalwt_d4d/app/global.compose.vars.sh:17](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt_d4d/app/global.compose.vars.sh:17) — code/configuration

  ```text
  global APP_DOCROOT_C "[default]=/var/www/html"
  ```

- [scripts/asc/contrib/asc/drupalwt_d4d/app/global.compose.vars.sh:24](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt_d4d/app/global.compose.vars.sh:24) — code/configuration

  ```text
  global DRUPAL_CONFIG_SYNC_DIR_C "[default]=$APP_DOCROOT_C/config/sync"
  ```

- [scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:37](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:37) — code/configuration

  ```text
  - ./$APP_DOCROOT:$APP_DOCROOT_C
  ```

- [scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:90](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:90) — code/configuration

  ```text
  - ./$APP_DOCROOT:$APP_DOCROOT_C
  ```

- [scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:99](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:99) — code/configuration

  ```text
  CRONTAB: "${DWT_CRON_FREQ} drush -r ${APP_DOCROOT_C} cron"
  ```

- [scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:113](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt_d4d/stack/compose.yml:113) — code/configuration

  ```text
  - ./$APP_DOCROOT:$APP_DOCROOT_C
  ```

- [scripts/asc/contrib/asc/moodle_d4php/global.vars.sh:15](/home/paul/Documents/asc/scripts/asc/contrib/asc/moodle_d4php/global.vars.sh:15) — code/configuration

  ```text
  global APP_DOCROOT_C "[default]=/var/www/html"
  ```

- [scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:17](/home/paul/Documents/asc/scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:17) — code/configuration

  ```text
  - ./$APP_DOCROOT:$APP_DOCROOT_C
  ```

- [scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:41](/home/paul/Documents/asc/scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:41) — code/configuration

  ```text
  - ./$APP_DOCROOT:$APP_DOCROOT_C
  ```

- [scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:52](/home/paul/Documents/asc/scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:52) — code/configuration

  ```text
  CRONTAB: "${MOODLE_CRON_FREQ} php ${APP_DOCROOT_C} admin/cron.php"
  ```

- [scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:62](/home/paul/Documents/asc/scripts/asc/contrib/asc/moodle_d4php/stack/compose.yml:62) — code/configuration

  ```text
  - ./$APP_DOCROOT:$APP_DOCROOT_C
  ```


### APP_GIT_INIT_CLONE

Clone-on-init switch. The core Git init hook accepts values starting with `Y` or `y`. Also described in Drupal project creation comments. No literal global declaration remains.

- [asc/git/init.hook.sh:22](/home/paul/Documents/asc/asc/git/init.hook.sh:22) — code/configuration

  ```text
  case "$APP_GIT_INIT_CLONE" in [Yy]*)
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:12](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:12) — comment

  ```text
  #   instance init if $APP_GIT_INIT_CLONE is set to 'yes'), this then re-executes
  ```

- [scripts/asc/contrib/asc/drupalwt/new/project.sh:26](/home/paul/Documents/asc/scripts/asc/contrib/asc/drupalwt/new/project.sh:26) — comment

  ```text
  #   # if $APP_GIT_INIT_CLONE is set to 'yes', the git work tree will be
  ```


### APP_GIT_INIT_HOOK

Historical name only: two changelog mentions describe its replacement by `ASC_GIT_HOOKS_WIRED`. No executable use or declaration found.

- [changelog/2026/09/25-wired-init-lists.md:11](/home/paul/Documents/asc/changelog/2026/09/25-wired-init-lists.md:11) — documentation

  ```text
  `ASC_GIT_HOOKS_WIRED` is the git hooks init may pass to `f_git_write_hooks`. Empty: do not call the writer. Non-empty: call it with that list only. The writer's built-in six are not implied. `APP_GIT_INIT_HOOK` is not the name.
  ```

- [changelog/2026/09/25-wired-init-lists.md:15](/home/paul/Documents/asc/changelog/2026/09/25-wired-init-lists.md:15) — documentation

  ```text
  The skill sentence that names `APP_GIT_INIT_HOOK`, and the test that greps it, use `ASC_GIT_HOOKS_WIRED` when this lands.
  ```


### APP_GIT_ORIGIN

Application Git remote URL. Used by core cloning and remote-instance SSH host preparation. No literal global declaration remains.

- [asc/extensions/remote_instance/remote/init.sh:58](/home/paul/Documents/asc/asc/extensions/remote_instance/remote/init.sh:58) — code/configuration

  ```text
  if [[ -n "$APP_GIT_ORIGIN" ]]; then
  ```

- [asc/extensions/remote_instance/remote/init.sh:59](/home/paul/Documents/asc/asc/extensions/remote_instance/remote/init.sh:59) — code/configuration

  ```text
  if [[ "$APP_GIT_ORIGIN" =~ $regex ]]; then
  ```

- [asc/extensions/remote_instance/remote/init.sh:62](/home/paul/Documents/asc/asc/extensions/remote_instance/remote/init.sh:62) — code/configuration

  ```text
  if [[ "$APP_GIT_ORIGIN" =~ $regex_with_user ]]; then
  ```

- [asc/git/init.hook.sh:23](/home/paul/Documents/asc/asc/git/init.hook.sh:23) — code/configuration

  ```text
  if [[ -n "$APP_GIT_ORIGIN" ]] \
  ```

- [asc/git/init.hook.sh:29](/home/paul/Documents/asc/asc/git/init.hook.sh:29) — code/configuration

  ```text
  git clone "$APP_GIT_ORIGIN" "$APP_DOCROOT"
  ```

- [asc/git/init.hook.sh:42](/home/paul/Documents/asc/asc/git/init.hook.sh:42) — code/configuration

  ```text
  f_git_wrapper remote add origin "$APP_GIT_ORIGIN"
  ```

## Related names that do not start with APP_

These are excluded from the exact-name counts, but may need documentation cleanup. `YAML_APP_*` are parser-prefixed examples; `API_APP_*` are example names whose actual prefix is `API_`.

- [SPECIMEN.env.yml:9](/home/paul/Documents/asc/SPECIMEN.env.yml:9)

  ```text
  # API_APP_DOCROOT (on local machine) = API_APP_DOCROOT_C (in container).
  ```

- [asc/instance/instance.inc.sh:297](/home/paul/Documents/asc/asc/instance/instance.inc.sh:297)

  ```text
  #   echo "$YAML_APP_DOCROOT"
  ```

- [asc/instance/instance.inc.sh:298](/home/paul/Documents/asc/asc/instance/instance.inc.sh:298)

  ```text
  #   echo "$YAML_APP_GIT_ORIGIN"
  ```

- [asc/instance/instance.inc.sh:364](/home/paul/Documents/asc/asc/instance/instance.inc.sh:364)

  ```text
  #   echo "$YAML_APP_DOCROOT"
  ```

- [asc/instance/instance.inc.sh:365](/home/paul/Documents/asc/asc/instance/instance.inc.sh:365)

  ```text
  #   echo "$YAML_APP_GIT_ORIGIN"
  ```

## Reproduce the search

Run from the ASC project root:

```sh
rg -n --hidden --no-ignore -g '!.git/**' \
  -g '!changelog/2026/09/26-app-prefix-inventory.md' \
  '\bAPP_[A-Za-z0-9_]+\b' .

# Broader scan also catches YAML_APP_* and API_APP_*:
rg -n --hidden --no-ignore -g '!.git/**' \
  -g '!changelog/2026/09/26-app-prefix-inventory.md' 'APP_' .
```

This is a static inventory of literal references. Names assembled dynamically without a literal `APP_` string and configuration supplied by other project instances are not enumerated.
