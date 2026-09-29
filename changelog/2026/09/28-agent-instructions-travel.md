# Shared agent instructions, and what stays in the instance

| Field | Value |
|-------|--------|
| **Date** | 2026-09-28. Revised 2026-09-29 after review, after two local trees were pulled, and after commit `7801625`. The 2026-09-28 counts stay as that earlier snapshot. |
| **Status** | **plan / review**. Nothing in this note is an implementation go-ahead. |
| **Scope** | Which agent-instruction files every ASC project instance should receive from the mother, which files stay in the instance, and how `make core-upgrade` delivers the shared set. |
| **Out of this plan** | Implementing [27-agent-guidance-from-antipatterns.md](./27-agent-guidance-from-antipatterns.md). Filling `guidance-render`. Adding `data/skills/`. Extending [23-host-asc-core-sync.md](./23-host-asc-core-sync.md) to copy `.cursor/` or `.agents/`. Editing the home-directory instance's user rules. A README edit. A `git commit` or `git push` from `core-upgrade`. Enabling `agent`, `asc/cursor`, `asc/codex`, or `asc/claude` on this mother's ignore list. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), except `$HOME`, `$tmp_dir`, `$1`, and `$2`.

[`gates.core.yml`](../../../gates.core.yml) says a task may go ahead only when `go` is `yes`, and that `go` may be set only when `approved` is `yes` and `lane` is `sequential` or `parallel`. `discuss` and `held` stay `no`. The row in `lane: discuss` records this plan. It cannot become `go: yes`, and it does not authorize file transport.

File transport has a second row, same changelog, `lane: parallel`, order 2. That is the only row for this note that can become `go: yes`, and only after a human sets `approved` to `yes`. Both rows stay `approved: no` and `go: no` until then. Setting `go` on the parallel row authorizes file transport only: the copy stays in `asc/core/upgrade.sh`, `AGENTS.md` is installed when the instance has none, the hook call returns, and the commented auto-push stays out. It does not mean an agent follows those files. It does not drop a rule, shrink the allowlist, or start `guidance-render`.

Mother `main` was already up to date with `origin/main` when this note was written (`git pull` reported already up to date).

This note revises one claim from the previous day. [27-agent-guidance-from-antipatterns.md](./27-agent-guidance-from-antipatterns.md) says this mother has no `AGENTS.md` and no `.agents/` directory, and it lists three handwritten Cursor rules. On 2026-09-28 the tree has `AGENTS.md`, three handwritten agent skills, and a fourth handwritten rule, `asc-builder-anti-pattern.mdc`. Those files are not generated. `guidance.render.yml`, `data/entities/skill/`, and `asc/extensions/agent/guidance/render.sh` are absent. The three product writers are still on disk: `scripts/asc/contrib/asc/cursor/skill/render.hook.sh`, `codex/skill/render.hook.sh`, and `claude/skill/render.hook.sh`.

---

## What this is for

An agent working in any ASC project instance should see the same ASC authoring procedure, the same hazard rule, and that instance's own rules. It should not see a second essay of the procedure, and it should not see another instance's rules.

Two channels exist today. They do different jobs, and they have been filled with the same prose.

| Channel | What it is | Who it is for |
|---------|------------|----------------|
| Agent skill | `.agents/skills/<id>/SKILL.md` plus the index `AGENTS.md` | Cursor, Codex, and any other tool that reads the Agent Skills layout. A procedure. Loaded when the task matches. |
| Cursor rule | `.cursor/rules/*.mdc` | Cursor only. A constraint attached to a workspace. `alwaysApply: true` injects it into every Agent chat and ignores `globs`. |

A third channel is accidental. Cursor user rules live in `$HOME/.cursor/rules/`. The home-directory ASC instance uses `$HOME` as its docroot, so that directory is also its project rules. Files placed there load in every workspace on that machine, including project instances that are not the home directory.

The spread mechanism is `asc/core/upgrade.sh` (`make core-upgrade`). It is an allowlist. Whole directories that are entirely upstream-owned are replaced. Named Cursor rules are copied as files, so any other file in `.cursor/rules/` survives. That split is the right one. On 2026-09-28 it had not reached the other trees checked on this host. On 2026-09-29 two of those trees had it, by a pull of their own repositories, and `AGENTS.md` was still absent there. The files on the allowlist repeat each other.

---

## What was compared

On 2026-09-28, after the mother pull above:

- The mother checkout.
- The home-directory instance (`asc/bootstrap.sh` present).
- Three other local trees that contain `asc/bootstrap.sh`.

Compared paths: `.agents/`, `.cursor/rules/`, `AGENTS.md`, `CLAUDE.md`, `.claude/`, and `asc/core/upgrade.sh`. Instance rule bodies were not copied into this note. One of those trees keeps a search list in its own `.cursor/rules/`. That list stays there.

Line counts below are `wc -l` on that date.

---

## What the mother has

| Path | Lines | How Cursor treats it |
|------|------:|----------------------|
| `.agents/skills/asc-author-code/SKILL.md` | 69 | Agent skill. Procedure for writing ASC code. Points at `README.md`, `data/entities/anti-pattern/`, and `asc/extensions/builder/subject/`. |
| `.agents/skills/asc-author-docs/SKILL.md` | 43 | Agent skill. Procedure for README proposals, changelogs, and ASC prose. |
| `.agents/skills/asc-mother-guard/SKILL.md` | 42 | Agent skill. Procedure before a mother write. |
| `AGENTS.md` | 36 | Project index. This mother loads it as an always-on workspace rule. It tells the agent to read the three skills. |
| `.cursor/rules/asc-lightweight.mdc` | 115 | `alwaysApply: true`. Size, tests, README proposals, gates, labels, synonyms. |
| `.cursor/rules/asc-builder-anti-pattern.mdc` | 47 | `alwaysApply: true`. Template table and anti-pattern records. |
| `.cursor/rules/asc-dollar-prefix.mdc` | 28 | `globs` set. `alwaysApply` removed in `7801625`. Attaches when a matching markdown file is in context. Not injected into every chat. |
| `.cursor/rules/asc-mother-guard.mdc` | 18 | `alwaysApply: true`. Short hazard rule. |

398 lines in that set. No other files under `.agents/` or `.cursor/`.

`asc/core/upgrade.sh` (171 lines) replaces these directories from the GitHub clone:

- `asc`
- `scripts/asc/contrib/asc`
- `.agents/skills/asc-author-code`
- `.agents/skills/asc-author-docs`
- `.agents/skills/asc-mother-guard`

It then copies these files, leaving every other file in `.cursor/rules/` in place:

- `.cursor/rules/asc-builder-anti-pattern.mdc`
- `.cursor/rules/asc-dollar-prefix.mdc`
- `.cursor/rules/asc-lightweight.mdc`
- `.cursor/rules/asc-mother-guard.mdc`

It then runs `cp -f "$tmp_dir/AGENTS.md" 'AGENTS.md'`. That copy is not in either array. It replaces an existing file. It does not check the status of `cp`, so a missing source does not exit 4 the way a missing Cursor rule does.

The hook call at the end of `upgrade.sh` is commented out (TODO 2026-09-27). `asc/core/post_upgrade.hook.sh` sources `asc/instance/reinit.sh`. The rest of that hook implementation is a commented `git add`, `git commit`, and `git push`.

---

## What the other trees had on 2026-09-28

None of the four local trees had `.agents/`, `AGENTS.md`, or any of the four shared Cursor rules.

| Tree | `upgrade.sh` | Hook call | Instruction files |
|------|--------------|-----------|-------------------|
| Home-directory instance | 156 lines. Swaps `asc/` and `scripts/asc/contrib/asc/` only. | Commented out. | Nine files in `$HOME/.cursor/rules/` (351 lines). Two of them are different bytes from the mother files of the same name: `asc-builder-anti-pattern.mdc` and `asc-mother-guard.mdc`. |
| Two other local trees | 156 lines. Same two-directory swap. | Live. `hook -s core -a post_upgrade`. | No shared ASC rules. One tree has eight local rules. The other has a single local rule, the search-list file. |
| One other local tree | `asc/core/upgrade.sh` is absent. `asc/bootstrap.sh` is present. | None. | `.cursor/rules/` exists and is empty. |

### Resurvey on 2026-09-29

Those two trees were pulled. `cmp` against the mother was clean for `asc/core/upgrade.sh`, `asc/core/post_upgrade.hook.sh`, the three agent skills, and the four shared Cursor rules. Each of those paths is tracked in the instance repository. `AGENTS.md` is still absent in both. The home-directory instance and the tree with no `upgrade.sh` were not part of that pull. Rechecked the same day, they still match the 2026-09-28 rows.

| Tree | After the pull |
|------|----------------|
| The two pulled trees | 168-line `upgrade.sh`, the same allowlist as the mother, hook call commented out. Three agent skills present. Four shared Cursor rules present. The eight local rules are still beside the shared four on one tree. The search-list file is still beside the shared four on the other. |
| Home-directory instance | Unchanged. 156-line script, hook call commented, no `.agents/`. |
| Tree with no `upgrade.sh` | Unchanged. No shared instruction files. |

The pull is not a run of `make core-upgrade` observed for this note. It does show that a tree can hold the shared files and its own rules in the same `.cursor/rules/` directory. No live `post_upgrade` hook call remained on the trees checked that day.

### Mother tip after that resurvey

Commit `7801625` changed the mother after the `cmp` above. `asc-dollar-prefix.mdc` lost `alwaysApply` and is 28 lines. `upgrade.sh` grew to 171 lines and copies `AGENTS.md` with `cp -f` on every run. The hook call is still commented. Rechecked against that tip, the two pulled trees differ on `upgrade.sh` and `asc-dollar-prefix.mdc`, and `AGENTS.md` is still absent. The home-directory instance is still the 156-line script.

Their next `make core-upgrade` still executes the 168-line script. It copies the new dollar-prefix bytes, because that path is on its allowlist, and it does not copy `AGENTS.md`. The run after that executes the 171-line script and replaces `AGENTS.md` every time.

Codex on this host has a trusted-project entry for the mother and only its own system skills under the user skill directory. No `.claude/` and no `CLAUDE.md` in the trees checked.

A Cursor session opened on the mother that same day loaded the four mother rules (209 lines), `AGENTS.md` (36), and the eight home-directory rules that set `alwaysApply: true` (316). That is 561 lines before the task. `asc-bash.mdc` in the home directory sets `alwaysApply: false` and globs, and it was not part of that sum. This is one session. It is not a claim that every Cursor build attaches files the same way. [27-agent-guidance-from-antipatterns.md](./27-agent-guidance-from-antipatterns.md) already separates generation, discovery, and application, and it does not claim application.

---

## What is duplicated

The same policy is written in more than one place.

| Policy | Cursor rule | Agent skill | `AGENTS.md` | Home-directory user rule |
|--------|-------------|-------------|-------------|--------------------------|
| Mother-guard | 18 lines, always on | `asc-mother-guard`, 42 lines | One paragraph | 20 lines, different bytes |
| Templates and anti-patterns | `asc-builder-anti-pattern.mdc`, 47 lines, always on | `asc-author-code`, 69 lines | One paragraph | 38 lines, different bytes. The home copy points template paths at `$HOME/Documents/asc`. The mother copy uses the docroot being edited, then `f_host_registry_get asc_mother_repo_path`. |
| README, size, labels | `asc-lightweight.mdc`, 115 lines, always on | `asc-author-docs` covers the README proposal and the vocabulary. It does not cover labels or gates. | One paragraph | `asc.mdc`, 41 lines, different policy (below) |
| `$` placeholder | `asc-dollar-prefix.mdc` | A vocabulary note inside `asc-author-docs` | Absent | Absent |

`asc-author-code` is the copy that stays honest: it tells the agent to read the templates and the anti-pattern records from disk. The template table inside `asc-builder-anti-pattern.mdc` is a second inventory. It will drift the next time a template is added. The 2026-09-27 note already chose that shape for generated rules: the rule points at the record, and the record stays the text.

---

## Conflicts on disk

These are current sentences, not proposals.

**Approval.** `asc-lightweight.mdc` says to ask before adding a loader, a hook implementation, a wrapper, or a global. `AGENTS.md` says that inside a task the user already authorized, those need no second approval. The home-directory `asc.mdc` repeats the ask-before sentence.

**README edits.** `asc-lightweight.mdc` allows an edit inside an escaped dated proposal, beside the human line. The home-directory `asc.mdc` says agents do not write `README.md` unless explicitly asked.

**Frontmatter.** The 2026-09-27 note records Cursor's modes: `alwaysApply: true` ignores `description` and `globs`. Until `7801625`, `asc-dollar-prefix.mdc` set both, so the rule was injected while editing shell. That line is gone. The file now has `globs` and no `alwaysApply`. `asc-lightweight.mdc` and `asc-builder-anti-pattern.mdc` still set `alwaysApply: true`. The generator in that note does not emit that mode.

**`post_upgrade`.** On 2026-09-28 two local trees still called the hook. The mother script and the home-directory script commented the call out. Those two trees matched the mother script, commented call included, until `7801625`. After that commit the mother script is the 171-line file and those trees are still on the 168-line file. The home-directory script still comments the call. The hook implementation that a new `asc/` would run does not commit, because that body is commented. A tree that still has an older `post_upgrade.hook.sh` is replaced when `asc/` is swapped, so the hook that runs after that swap is the commented one. The auto-push must stay commented. An upgrade that publishes the instance is the wrong default.

---

## README collisions

README remains the source of truth. This note does not edit it. These passages disagree with the tree, or with each other. A later proposal can shorten them. This file does not.

- [Non-goals](../../../README.md) says complex agent work belongs in a dedicated project instance. The [Workflow](../../../README.md) section then specifies `make agent-loop`, provider hook implementations for `make llm-call`, and a core rules extension. The handwritten skills and rules are a third telling of that work, already in this repository.
- [Contracts (= capabilities = abilities = skills ~= SKILL.md blueprints)](../../../README.md) uses one word for `*.able.yml` contracts and for `SKILL.md`. They are different objects. An ability is a YAML contract an entity includes (`sidecar.able`, `ssh.able`). An agent skill is a procedure a coding tool loads from `.agents/skills/<id>/SKILL.md`.
- [Default file-based agent skills storage : `data/skills`](../../../README.md) is `TODO`. Nothing reads that path. `data/skills/` is absent. The files tools load today are `.agents/skills/*/SKILL.md`. The 2026-09-27 note stores the unrendered procedure at `data/entities/skill/<id>.yml`, which is also absent. Do not create `data/skills/` to make the heading true.

Vocabulary for the rest of this note: **ability** for `*.able.yml`, **agent skill** for `SKILL.md`.

---

## What should travel

Shared means: every ASC project instance that runs `make core-upgrade` receives the same bytes, and an instance edit to those bytes is replaced on the next upgrade.

| Path | Why it travels |
|------|----------------|
| `.agents/skills/asc-author-code/` | The procedure for ASC code. Whole directory, because the skill is upstream-owned. An instance skill uses a different directory name and survives. |
| `.agents/skills/asc-author-docs/` | The procedure for ASC prose. |
| `.agents/skills/asc-mother-guard/` | The procedure before a mother write. |
| `.cursor/rules/asc-mother-guard.mdc` | The hazard rule. A skipped agent skill is how a client fact reaches a mother diff. This one stays `alwaysApply: true`, which is the exception the 2026-09-27 generator refuses to emit. Handwritten on purpose. |

`AGENTS.md` is the always-on index. Skills without it do not tell Cursor or Codex to read them. Commit `7801625` copies it with `cp -f` on every upgrade. That replaces an existing file, so instance paragraphs go away, and so does a span `guidance-render` would have appended. The file-transport slice changes that line: copy when the destination is absent, leave an existing file untouched. It does not write the markers from the 2026-09-27 note. A hand-written span would stick: that note's ownership table says a populated span with no matching manifest hash is a conflict, and `guidance-render` must preserve the file.

The handoff is the renderer's own initial install. When the file exists, the manifest has no section entry, and the file has no marker, the first successful `guidance-render` appends the span and leaves the surrounding bytes. Transport is what puts those surrounding bytes there, and only on a tree that does not already have the file. If `guidance-render` runs first on an empty path, it creates a span-only file, and a later transport will not overwrite it. Run transport first on a tree that should keep this handwritten index.

Copying the files is not the opening goal. The opening goal is an agent in any instance seeing one procedure, the hazard rule, and that instance's own rules. File transport can place the bytes. It does not claim discovery in a fresh session, and it does not claim the agent applies them. Those claims stay where the 2026-09-27 note put them: a manual check per tool, and application unclaimed.

---

## What should stay in the instance

| Kind | Examples already seen | Why |
|------|----------------------|-----|
| Product rules | Eight rules in one local tree, none of them on the allowlist | True for that repository only. A directory swap of `.cursor/rules/` would delete them. The file copy avoids that. Keep the file copy. |
| Search list | The local mother-guard file in the instance that owns it | The mother rule already says the list stays in the instance. The mother's `asc-mother-guard.mdc` is a different file. |
| Home-directory user policy | Machine-branch rule, model-choice rule, home git layout | True for this human's machines. They belong in the home repository. They do not belong in the mother allowlist, and they do not belong in a client tree's `.cursor/rules/`. |
| Instance agent skills | Any `.agents/skills/<id>/` whose `<id>` is not on the allowlist | Same pattern as the Cursor file copy. The directory replace is per skill id, not of `.agents/skills/` as a whole. |

The home-directory duplicates of `asc-builder-anti-pattern.mdc` and `asc-mother-guard.mdc` are not a mother patch. After a tree receives the shared files by `core-upgrade`, those two user rules are a second, drifted copy loaded into every workspace. Removing them is a commit in the home repository. This note does not make that commit.

`$HOME/.cursor/rules/` cannot be the spread channel. It does not travel with `core-upgrade`. It does travel, on these machines, into workspaces that are not ASC. A colleague who clones a project instance does not have that directory.

---

## Proposed shrink, later

Not file transport. Two later rows. Deleting the mother files in the same commit that drops them from the allowlist breaks the upgrade that is already running.

`upgrade.sh` replaces `asc/` and `scripts/asc/contrib/asc/` before it copies Cursor rules. The copy is `cp -f` from the clone. A missing source exits 4. The running script is the previous one: its array still names the files, the new script is already on disk, and the instance rule is left as it was. The next run executes the new script, which no longer copies those paths, so the old instance files stay active.

Changing frontmatter in place is a different case. `asc-dollar-prefix.mdc` lost `alwaysApply` in `7801625` and stayed on the active allowlist. An older script's `cp` overwrites the instance file with those bytes. That edit is not a retirement. Deleting the file still is, and still waits for stage A.

Retirement is only for a file that leaves the allowlist:

| File | Why it would leave |
|------|--------------------|
| `asc-builder-anti-pattern.mdc` | `asc-author-code` already says to read the templates and the records. The table in the rule is a cache. |
| `asc-lightweight.mdc` | 115 lines on every turn, including turns that do not touch ASC. It also tells the agent to patch the rule itself on every step. That is how the rule grows. The durable points (tests are runs, README proposals, gates, small diffs) belong in `asc-author-code`, `asc-author-docs`, and `AGENTS.md`, each said once. |
| `asc-dollar-prefix.mdc` | Only if the vocabulary note inside `asc-author-docs` replaces the file. The globs-only edit already landed. The file stays on the active allowlist. |

### Stage A — files still in the clone

The mother still contains the retired files, so a previous `upgrade.sh` can `cp` them and exit 0. The new script's active allowlist omits them. After the active copies succeed, it walks the retired list:

- Instance file missing: continue.
- `cmp -s` against the clone copy: remove the instance file. Those bytes are the last shipped copy.
- Bytes differ: print `retired rule kept (local bytes differ):` and the path. Continue. Exit 0.

A previous script can reinstall a byte-identical file during stage A. The next stage A run removes that reinstall. A local edit survives. This `cmp` is the ownership check for these handwritten paths. It is not `guidance.render-manifest.yml`. These files are not generated rules under `.cursor/rules/asc-anti-pattern/`.

### Stage B — files deleted from the mother

A separate row. Unsafe for any tree whose running `upgrade.sh` still names the path: that run exits 4 after `asc/` has already been replaced, and the instance file remains. Publish stage B only for trees that have completed stage A. Nothing in `core-upgrade` can see that every tree has done so. A wait is not a substitute.

The 2026-09-27 first-slice check says the handwritten lightweight, mother-guard, and dollar-prefix rules are still present after a render. Stage B revises that check: mother-guard stays; a retired file may disappear; `asc-builder-anti-pattern.mdc` was not in that check. This note does not render the generated set, and it does not add a second generator.

---

## Where the copy runs

The copy stays in `asc/core/upgrade.sh`, beside the clone.

`data/tmp/upstream-asc` is deleted before `post_upgrade` runs, unless the caller passed `k` as `$2`. The skills and the Cursor rules are not inside `asc/` or `scripts/asc/contrib/asc/`. They exist only in that clone until the allowlist copies them.

A stale `upgrade.sh` that still calls the hook cannot be fixed by a new hook implementation. The process already running is the old script. It deletes the clone, then calls the hook. The hook then has nothing to copy from. Putting the allowlist inside `asc/` so the existing directory swap delivers it, and publishing outward from the hook, would make the first run work. It would also store a second copy of every instruction file inside `asc/`. That shadow tree is the heavier design. Reject it.

What actually happens, by the script the tree is running when the slice reaches the mother. The 2026-09-29 pull moved two trees from the first row to the third.

| Script running before the slice | First `make core-upgrade` | Second run |
|--------------------------------|---------------------------|------------|
| 156-line script, hook call live. Observed 2026-09-28. Not found on the trees rechecked 2026-09-29. | Replaces `asc/` and `scripts/asc/contrib/asc/` with the new script. Deletes the clone. Calls the hook. The new hook does not have the clone. Skills, rules, and `AGENTS.md` are not copied. The hook does run reinit, below. | The new script runs. It copies the allowlist from a fresh clone, installs `AGENTS.md` when absent, then calls the hook. |
| 156-line script, hook call commented. Home-directory instance, still true on 2026-09-29. | Same swap. No hook. No instruction copy. No reinit from this upgrade. | The new script copies the allowlist, installs `AGENTS.md` when absent, then calls the hook. |
| 168-line script, hook call commented, skills and four rules already present. The two pulled trees, compared before `7801625`. `AGENTS.md` still absent. | The running script already copies the allowlist, so the skills and four rules are copied again from the clone, including the globs-only dollar-prefix file. It does not install `AGENTS.md`. It does not call the hook. | Against the current tip, the 171-line script replaces `AGENTS.md` with `cp -f` and still does not call the hook. Against this slice, that copy runs only when the file is absent, and the hook runs. |
| No `upgrade.sh`. Still true for one tree on 2026-09-29. | No spread until that tree has the script. Out of this slice. |  |

On a 156-line script whose hook call is live, that first run does execute the new `post_upgrade` hook implementation. The two trees pulled on 2026-09-29 no longer take that path. Their first upgrade against the slice uses the 168-line script, whose hook call is commented, so that first run does not reinit. The second run does.

The hook implementation sources `asc/instance/reinit.sh`. Reinit clears `data/asc/cache`, then runs `asc/instance/init.sh -y`. Init calls `f_instance_init`. Reinit does not set the dry-run flag (`-y` only skips prompts), so the live path runs, in this order: `f_global_write`, `f_make_generate`, the `pre` init hook call, `hook_ms` for `clone`, `hook` for `init`, `ensure_dirs_exist`, the permission reset, and the `post` init hook call. A first upgrade on a live-hook tree rewrites that instance's generated files and runs its init hooks even though no instruction file was copied. The second run on a 168-line tree does the same rewrite, after `AGENTS.md` has been installed.

`hook` sources the matched file and then continues. It does not return the sourced file's status. `reinit.sh` does not check the status of `init.sh`. A failed init is invisible to today's `upgrade.sh`. A `return` inside the sourced hook implementation returns from `hook`, because the file is sourced. An `exit` there ends the upgrade shell.

Proposed for this slice: `post_upgrade.hook.sh` runs reinit and, when `init.sh` returns non-zero, `return`s that status from the sourced file so `hook` stops before it overwrites the status. The new `upgrade.sh` exits with that status. There is no rollback. The directory swap has already happened. On a second-run failure the instruction copy has already happened too. The commented `git add` / `git commit` / `git push` stays deleted.

Say the two-run install, and this reinit, in the header comment of `upgrade.sh`. Two runs are still the install for a tree whose running script is not yet this slice. The two trees pulled on 2026-09-29 already copy the allowlist. Against the current tip, their second run replaces `AGENTS.md` and still skips the hook, because `7801625` did not restore the call. Against this slice, that second run copies `AGENTS.md` only when it is absent, and the hook runs. One run is the install only when the script already contains this slice. Every run that calls the hook re-inits the instance.

### Why this is not a per-tool hook implementation

`.asc_extensions_ignore` in this mother lists `agent`, `asc/cursor`, `asc/codex`, `asc/claude`, and `rules`. A hook implementation that lives only under those extensions does not run here. The IDE still reads `.cursor/rules/` and `.agents/skills/` whether or not those extensions are enabled. The shared bytes have to be copied by `core-upgrade` on an instance that has never enabled them.

A later tool that needs a different payload (a one-line `CLAUDE.md` that points at `AGENTS.md`, for example) is a hook implementation of `post_upgrade` in that tool's extension. `hook` already runs every match, which is the right call when more than one tool is enabled. That hook implementation adjusts its own file. It does not replace the allowlist, and it does not run on a mother that ignores the extension. No YAML manifest for the allowlist. The arrays already in `upgrade.sh` are the list. Growing them by one path is the change. A config file would be a second list.

`host-asc-core-sync` stays on `asc/` and `scripts/asc/contrib/asc/`, as [23-host-asc-core-sync.md](./23-host-asc-core-sync.md) says. Instruction files are not core files. They travel with `core-upgrade` or they do not travel. Do not add them to that mirror.

---

## File transport

This slice places bytes. It does not claim the opening goal. The opening goal needs the index present on that instance, and then a fresh session per tool to see whether the tool discovered the files. Application stays unclaimed. The parallel gates row is the authorization. The discuss row is not.

Authorized only when that parallel row has `approved: "yes"` and `go: "yes"`.

1. Leave the directory list and the four Cursor rule paths in `asc/core/upgrade.sh`.
2. Replace the unconditional `cp -f` of `AGENTS.md` with a copy that runs only when the destination is absent. Do not write `<!-- asc-agent-guidance:start -->` or the end marker. Give that copy the same failure exit the Cursor-rule loop already has.
3. Restore the `hook -s core -a post_upgrade` call after the clone is removed.
4. `post_upgrade.hook.sh` still runs reinit and does no `git` write. Delete the commented push. When `init.sh` returns non-zero, return that status from the sourced hook so `upgrade.sh` can exit with it.
5. Document the two-run install and the reinit side effect in the script header.
6. Do not add a file under `asc/` that mirrors `.agents/` or `.cursor/`.

The slice includes a fixture. A header comment and a manual run do not replace it. A manual run is not `make test-core`. The fixture uses a temporary docroot, not a real instance and not `$HOME/Documents/asc`.

- An extra `.cursor/rules/local.mdc` and an extra `.agents/skills/local-only/SKILL.md` are still there after the copy.
- The four rules and the three skill directories match the fixture upstream.
- `AGENTS.md` is copied when missing, unchanged when present, and the transported file contains neither guidance marker.
- A stubbed `init.sh` failure makes the process exit non-zero. The fixture does not run reinit against a real tree. It also records that the directory swap has already happened when init fails, so the failure path is a non-zero exit with the new `asc/` left in place.

---

## Later, each its own row

1. Stage A of the shrink, then stage B, as above. Fold any sentence that is still true into one agent skill before stage B deletes the file that held it.
2. Home repository: remove the user-rule copies of the shared ASC files after the project copies exist. Keep the machine and model rules.
3. `guidance-render`, on an instance that has enabled the extensions, as already specified. The first successful run creates the `AGENTS.md` span. This note does not insert that span by hand. This mother's ignore list stays.

---

## Tasks

- [x] Mother and four local trees compared on 2026-09-28. Counts and `upgrade.sh` differences recorded above.
- [x] `guidance-render` is absent. The three agent skills are handwritten.
- [x] 2026-09-29: the discuss row stays `go: no`. File transport is a parallel row, also `go: no`.
- [x] 2026-09-29 resurvey: two pulled trees match the mother's allowlist and comment the hook call. Skills and the four rules are present and byte-identical. `AGENTS.md` is absent. Local rules are still beside the shared ones. The home-directory instance and the tree with no `upgrade.sh` are unchanged. That match is against the mother before `7801625`.
- [x] `7801625`: `asc-dollar-prefix.mdc` no longer sets `alwaysApply`. `upgrade.sh` copies `AGENTS.md` with `cp -f` and does not check that copy.
- [ ] File transport, only after the parallel row has `go: yes`. Same four rules and three skill directories. The `AGENTS.md` copy becomes install-when-absent. Hook call restored. Init failure exits non-zero. Push stays out.
- [ ] Shrink stage A, shrink stage B, and home-repository cleanup stay unstarted. The `AGENTS.md` span stays unstarted until `guidance-render` writes it.
