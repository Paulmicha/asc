# ASC guidance, once, as project agent skills

| Field | Value |
|-------|-------|
| **Date** | 2026-09-30. Revised the same day after review. |
| **Status** | Compatibility diff is in this work tree and is not published. Not a direction to run `core-upgrade`. Recorded-file checks and the `AGENTS.md` gate are open. |
| **Scope** | One copy of ASC authoring guidance, versioned in the mother as project agent skills. Inheritance follows the publication order below, not today's `origin/main`. The linux home repository keeps one host Cursor rule that points at the ASC tree being worked on. |
| **Out of this plan** | A `README.md` edit. A new `gates.core.yml` row. Removing the current home Cursor rule bodies. Creating `data/skills/`. Enabling ignored `agent`, `cursor`, `codex`, or `claude` extensions. A commit. |

`$` in this file is an ASC placeholder (`$subject` / `$action`), except `$HOME`.

Mother `main` matches `origin/main`. `git pull --ff-only` was already up to date. The work tree is dirty with the uncommitted edits in [30-cursor-rules-home.md](./30-cursor-rules-home.md). This note is written against that tree.

An **agent skill** here is a procedure at `.agents/skills/<name>/SKILL.md`. README [Contracts](../../../README.md) still uses "skills" for `*.able.yml` abilities as well, and [Default file-based agent skills storage : `data/skills`](../../../README.md) is still `TODO`. Nothing in this note reads `data/skills/`. That collision is already recorded in [28-agent-instructions-travel.md](./28-agent-instructions-travel.md). This note does not edit the README.

---

## What this is for

ASC guidance should be written once, in the mother, and kept current in every instance, including the linux home folder. That inheritance waits on the publication order below. Cursor rules on that host should tell Cursor to use the ASC tree being worked on. They should not carry a second copy of the procedures.

Files already present in the workspace need no installer. Agent skills are selected by task. The project index names the tasks that require each skill, so Cursor and Codex share one entry point and the procedures are not maintained again inside Cursor rules.

---

## What is already on disk

| Path | This checkout |
|------|----------------|
| `AGENTS.md` | Present. Compact index. It names the ASC tasks that require `asc-author-code`, `asc-author-docs`, and `asc-mother-guard`. |
| `.agents/skills/asc-author-code/` | Present. |
| `.agents/skills/asc-author-docs/` | Present. |
| `.agents/skills/asc-mother-guard/` | Present. |
| `CLAUDE.md`, `.claude/` | Absent. |
| `asc/core/upgrade.sh` | Does not copy `.cursor/rules/`. Swaps the three skill directories, replaces `AGENTS.md` on every run, and points `.claude/skills` at `../.agents/skills`. |

The linux home instance has `asc/bootstrap.sh` and does not have `AGENTS.md` or `.agents/skills/`. Its host Cursor rules under `$HOME/.cursor/rules/` still include always-applied ASC procedure text (`asc.mdc`, `asc-builder-anti-pattern.mdc`, `asc-mother-guard.mdc`). [30-cursor-rules-home.md](./30-cursor-rules-home.md) moved ownership of generic Cursor rules to that directory. Those files load in every Cursor workspace on this host. The project files are what travel with an instance.

[30-cursor-rules-home.md](./30-cursor-rules-home.md) checked file placement and syntax. It did not check that Cursor, Codex, or Claude Code follows a skill on a task.

---

## Proposed layout

| Role | Versioned location |
|------|--------------------|
| ASC procedures | `.agents/skills/<name>/SKILL.md` in each instance |
| Required task routing | A short project `AGENTS.md` |
| One Cursor host rule, in the linux home repository, not in the mother | A short pointer at the `AGENTS.md` of the ASC tree being worked on |
| Claude native discovery and invocation, when that is wanted | `.claude/skills` → `../.agents/skills` |

The host rule stays conditional on an ASC tree. A host rule reaches Cursor sessions on this host only.

The ASC tree being worked on is the nearest directory at or above the files in the task that contains `asc/bootstrap.sh`. The pointer reads that tree's `AGENTS.md`, not whatever `AGENTS.md` sits at the Cursor workspace root. Those differ when the workspace contains or touches another ASC tree. The linux home workspace is that shape: its root is an ASC instance, and the mother checkout under it is another. Work on mother files uses the mother's index. Work on home-instance files uses the home instance's index, once that file exists. A task that touches more than one tree follows each tree's own index for the files in that tree.

Discovery this layout relies on, from the product docs, not from a fresh session on this host:

- Cursor and Codex discover `.agents/skills/`. Cursor also reads a project `AGENTS.md`. [Cursor skills](https://prod.cursor.com/docs/skills), [Cursor rules](https://prod.cursor.com/help/customization/rules), [Codex skills](https://learn.chatgpt.com/docs/build-skills).
- Codex loads `AGENTS.md` before work begins. [Codex instructions](https://learn.chatgpt.com/docs/agent-configuration/agents-md).
- Current Claude Code can read `AGENTS.md` when no project `CLAUDE.md` competes. That path-based instruction is a separate mechanism from Claude's own skills. Native discovery and invocation, including automatic selection, read `.claude/skills/<name>/SKILL.md`. `.claude/skills` is a symlink to `../.agents/skills`, so both paths are the same tree. A skill added under `.agents/skills/` is visible to Claude without another link. Older Claude Code may need a `CLAUDE.md` import. [Claude project instructions](https://code.claude.com/docs/en/memory), [Claude skill locations](https://code.claude.com/docs/en/skills).

This checkout has that directory symlink. A real directory at `.claude/skills` is removed by `upgrade.sh` before the link is created. Entries that existed only there do not survive.

---

## What this supersedes

The duplicated ASC procedure text in the home Cursor rules from [30-cursor-rules-home.md](./30-cursor-rules-home.md). Not that note's ownership decision: project files stay in the instance, and a Cursor-only host file stays in the linux home repository. The host file that remains is the short pointer.

`asc-bash.mdc` in the home rules is not part of that remainder. Its old glob attached in any ASC workspace on this host. The split below has landed in this work tree: home-instance facts stay in that host file, with no shell glob, and the reusable shell sentences that were not already in README are in `asc-author-code`. The duplicate always-applied procedure files are still in place until the recorded-file checks pass.

[28-agent-instructions-travel.md](./28-agent-instructions-travel.md) still has a gated file-transport row. This note does not set `go` on it and does not restore the shared Cursor rules.

---

## Publication order

Do not point an instance at `core-upgrade` for this migration until the compatibility commit below is what that command clones. `core-upgrade` clones the published mother, not this dirty work tree.

Observed on 2026-09-30:

- Published `origin/main` still copies four Cursor rules (`.cursor/rules/asc-builder-anti-pattern.mdc`, `asc-dollar-prefix.mdc`, `asc-lightweight.mdc`, `asc-mother-guard.mdc`) after it has replaced `asc/`. A missing source exits 4. [30-cursor-rules-home.md](./30-cursor-rules-home.md) already warns that an older running script can fail that way once the clone no longer has those files. Remote instances are unverified.
- This work tree drops those four paths from `asc/core/upgrade.sh` and, by a later direct instruction, deletes the four files after their missing sentences were moved into `AGENTS.md` and `.agents/skills/`. That deletion is no longer the compatibility commit. An older running script that still names the files will exit 4 once this tree is what `core-upgrade` clones.
- The linux home instance's running `asc/core/upgrade.sh` still copies the three skill directories and `AGENTS.md`, and it does not copy Cursor rules. It does not yet create the `.claude/skills` symlink. Its docroot is the home directory, so `.cursor/rules/` there is the host rules directory. That script was not edited in this step.
- A home `core-upgrade` against today's `origin/main` would still replace `asc/` with the published script. The run after that executes the old script and can copy the four rules back into the host rules directory. The home script can copy skills and `AGENTS.md` only while it is the script that is running, and only from a clone that still contains them.

The compatibility shape was: remove the four paths from `upgrade.sh` and leave the four files as they are on `origin/main`. A later direct instruction deleted the files in this work tree after the missing sentences moved into the skills and `AGENTS.md`. Publishing that deletion still makes an older copying script exit 4. The home instance still must not upgrade against today's `origin/main`.

Deletion publication, later: remove those four files from the mother only after every instance whose running script still names them has completed one upgrade against the compatibility commit. Until that is known, including on remote instances, publishing the deletion makes those upgrades fail after `asc/` has already been replaced.

`upgrade.sh` in this work tree does not copy the four Cursor rules, and the files themselves are gone. It is not committed or pushed. `origin/main` still has the old script and the four files. Do not run `core-upgrade` against either tree for this migration until older scripts that still copy those paths have been updated.

---

## `AGENTS.md` ownership

The index is required task routing only if an instance can keep its own paragraphs. The published script and this work tree both `cp -f` `AGENTS.md` on every run (`asc/core/upgrade.sh`). A later upgrade replaces an existing file, including instance instructions added after the first copy.

[gates.core.yml](../../../gates.core.yml) has a parallel row for [28-agent-instructions-travel.md](./28-agent-instructions-travel.md), order 2: copy `AGENTS.md` only when it is absent. `approved` and `go` are both `no`. This note does not set `go`.

Safe, ongoing inheritance of the index waits on that ownership rule being in the script instances actually run. A one-time successful copy is not that rule. The home instance has no `AGENTS.md` today, so a first copy would install the mother's index, and the next upgrade would still overwrite whatever was added locally.

---

## Checks

Following the right behavior while the host rule bodies are still loaded does not show that the agent read `AGENTS.md` or a skill. Record which instruction files the session loaded or read.

The mother checkout and the home instance are different cases. The mother checkout has `AGENTS.md` and the three skills, and Cursor on this host also injects the always-applied home rules, so a passing answer there can come from those rules. The home instance has neither project file. A session there is not a skill check. Its workspace root is also an ASC tree that contains the mother checkout, so a workspace-root path is the wrong selector. See the pointer rule above.

Order:

1. On the mother checkout, with the project files present and the host bodies still in place, record the files loaded. Treat a match with the host rules as inconclusive.
2. In an isolated or reversible setup, add the pointer and remove the duplicate procedure bodies. Repeat the session in Cursor, Codex, and Claude Code. The loaded files for an ASC task are that tree's `AGENTS.md` and the skill it names.
3. Repeat that isolated check for the home instance only after its project files are present, and only after the publication order above. Confirm the pointer followed the tree that owns the files in the task, not the other ASC tree in the same workspace.
4. After the live host bodies are cleaned up, repeat the recorded-files check on the mother checkout and on the home instance.

Until step 2 passes, leave the live host bodies in place.

---

## `asc-bash.mdc`

Split in the home file. The reusable sentences that README did not already hold are in `.agents/skills/asc-author-code/SKILL.md`. The host file keeps the home-instance facts and no longer uses a shell glob. `model-selection-is-human.mdc` keeps the model and branch constraint.

| Text | Belongs in |
|------|------------|
| This home directory is an ASC project instance. The public mother is `Documents/asc`. Instance facts stay in this home rule. | The home instance only. Scoped so a shell edit in another workspace on this host does not inherit them. |
| Do not name a model, and do not open a git branch, pointing at `model-selection-is-human.mdc`. | That host rule already. Drop the second copy from the bash file when the file is split. |
| Bootstrap, Bash 4, generated `pivots.mk` and the files not to hand-edit, README as source of truth, the mother-guard sentence, path layout, include kinds, action versus helper, `f_` / `p_`, `$` in markdown, and the call and search conventions. | Project guidance: the matching agent skill or `AGENTS.md`. Confirm each sentence is present there before deleting it here, so the split does not drop it. |

Host-only files that stay whole: machine layout, model choice, pull-before-planning, and the instance-to-mother ownership note. That last note still says generic Cursor rules for this host belong in the home user rules. A later edit should say the procedure lives in the project skills and the host file is the pointer.

## Tasks

- [x] This work tree's `upgrade.sh` does not copy the four Cursor rules, and the four files are deleted after consolidation. Not published. An older copying script still fails if this tree is cloned before that script is updated. No instance has been upgraded from this diff.
- [ ] `AGENTS.md` is copied only when absent, via the existing gates row. This note does not set `go`. The script still replaces an existing file on every run.
- [x] Host pointer: `asc-agents-pointer.mdc` uses the nearest `asc/bootstrap.sh` above the files in the task, then that tree's `AGENTS.md`.
- [ ] Recorded-file checks, mother and home as separate cases, including an isolated run with the duplicate bodies absent, then again after live cleanup. The live duplicate bodies stay.
- [x] Split `asc-bash.mdc` as in the table.
- [x] `.claude/skills` is a symlink to `../.agents/skills` in this checkout, and `upgrade.sh` recreates that one link. `AGENTS.md` path instructions stay a separate mechanism. Other instances receive the symlink only when they run this script.
