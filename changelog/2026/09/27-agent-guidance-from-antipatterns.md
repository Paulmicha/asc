# Agent guidance from anti-pattern records

| Field | Value |
|-------|--------|
| **Date** | 2026-09-27 |
| **Status** | **plan / review**. The split is chosen. The generation contract below is part of that choice. Nothing in this note is an implementation go-ahead. |
| **Scope** | Another spin on [26-patterns-and-antipatterns.md](./26-patterns-and-antipatterns.md), specific to Cursor and Codex. The changelog records the design. Markdown anti-pattern files stay the reusable guidance. Builder templates stay the concrete shapes. Skill entities compose a task procedure that points agents at both. Generation stays deterministic and small. |
| **Out of this plan** | Filling `stage-inspect`. Turning any prose record into a blocking detector. Enabling `agent`, `asc/cursor`, `asc/codex`, or `asc/claude` on this mother's ignore list. Retargeting the Claude skill writer. Converting the Markdown records into the YAML shape suggested on 2026-09-26. Filling the `shell_conditions` examples. Filling `make generate`. Adding a gates row. Rendering one skill per anti-pattern. Calling an LLM as part of normal generation. A description-only Cursor rule (globs omitted). Deleting legacy `.cursor/skills/`, `.codex/skills/`, or `.claude/skills/` copies. A second operator config file besides `guidance.render.yml`. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), except `$HOME`, `$PROJECT_DOCROOT`, and `$1`.

`gates.core.yml` is a later agent approval surface. Do not add a row for this note.

This note was written on branch `to-review`. That branch was already level with `origin/to-review`, and `git pull --ff-only` reported already up to date. The generation contract was tightened twice later the same day from review. Rendering stays all-or-nothing: an invalid selection is reported and the tree is left as it is. There is no automatic repair and no silent drop of a dependency. |

[26-patterns-and-antipatterns.md](./26-patterns-and-antipatterns.md) still says the first records are unwritten, and it suggests a YAML record (`id`, `detect`, `instead`, `block`, `audience`, `globs`). The tree has moved. This note keeps the Markdown files and revises the order: agent guidance can ship before mechanical checking.

---

## What this is for

README [Scope](../../../README.md) already names the pieces: pivot entry points, contracts, templates in `asc/extensions/builder`, and a complementary anti-pattern registry. Optional exemplar implementations stay opt-in. This note does not add a second kind of ASC object. It says how those existing pieces become guidance a Cursor agent and a Codex agent can read.

Four roles:

| Role | Where it lives | What it is |
|------|----------------|------------|
| Design | This changelog, and [26-patterns-and-antipatterns.md](./26-patterns-and-antipatterns.md) | Why the split exists. A historical note can stay tentative. It is not the generator input. |
| Guidance | `data/entities/anti-pattern/<group>/*.md` | A constraint or convention: what to avoid, what to prefer, and why. |
| Shape | `asc/extensions/builder/subject/*.tpl.sh` | The canonical file an agent copies from when the guidance names a template. |
| Procedure | `data/entities/skill/<id>.yml` | One task. It names the records and the templates. It is not a second copy of either. |

Generation reads the maintained records, the skill sidecar, and the instance selection. It does not re-read the changelog to decide what to emit. A changelog entry may be the origin of a rule, recorded as a reference. After that, the record is the input.

---

## What is already on disk

Sixteen Markdown records. Each already has `description` and `globs`. The other fields suggested on 2026-09-26 (`id`, `detect`, `instead`, `block`, `audience`) are absent. `globs` is already there.

| Group | Files |
|-------|--------|
| `asc` | `action_script_existence`, `docblock_file_sh`, `docblock_file_yml`, `docblock_function`, `docblock_named_options`, `docblock_positional_arguments`, `docblock_return_codes`, `docblock_scoped_vars`, `hook_call_existence`, `inc_vs_opt-inc`, `shell_conditions`, `shell_errors`, `shell_function_existence` |
| `general` | `breathing_line_breaks`, `editorconfig` |
| `python` | `dependencies` |

`data/entities/anti-pattern/asc/shell_conditions.md` still has TODO examples. It stays `draft`. `data/entities/anti-pattern/general/breathing_line_breaks.md` is hundreds of lines of examples. A generator that copied the whole body would publish that file as a rule.

| Existing file | Role in this note |
|---------------|-------------------|
| `data/entities/anti-pattern/asc/shell_function_existence.md` | Guidance: a function needs a reason to exist. The preferred alternative is the direct call. |
| `asc/extensions/builder/subject/action.tpl.sh` | Shape for an action script. Placeholders: `{{ docblock }}`, `{{ example }}`, `{{ slot }}`. |
| `asc/extensions/builder/subject/subject.opt-inc.tpl.sh` | Shape for an optional include. `subject.inc.tpl.sh` is the eager shape `inc_vs_opt-inc` argues against. |
| `asc/extensions/agent/skill/skill.entity.yml` | A task, independent of Cursor, Codex, or Claude. Fields today: required `description` and `task`, optional `body`. Instances would be `data/entities/skill/<id>.yml`. None exist yet. |
| `asc/extensions/agent/skill/render.able.yml` | `hook -s skill -a render`. The loader exports `SKILL_ID`, `SKILL_DESCRIPTION`, `SKILL_TASK`, and `SKILL_BODY` when set. Today a contrib hook writes one product file. The writers interpolate `description` with `printf`, which can emit invalid frontmatter. |
| [26-patterns-and-antipatterns.md](./26-patterns-and-antipatterns.md) | The earlier design. Its catalog path and its "an anti-pattern is not a skill" rule still hold. Its "first records are unwritten" sentence and its "project rules only after `stage-inspect`" order do not. |

Skill writers today, all invoked because `f_skill_render` calls `hook`, and `hook` runs every match:

| Hook | Destination |
|------|-------------|
| `scripts/asc/contrib/asc/cursor/skill/render.hook.sh` | `.cursor/skills/<id>/SKILL.md` |
| `scripts/asc/contrib/asc/codex/skill/render.hook.sh` | `.codex/skills/<id>/SKILL.md` |
| `scripts/asc/contrib/asc/claude/skill/render.hook.sh` | `.claude/skills/<id>/SKILL.md` |

`asc/extensions/agent/test/core/skill_entity.test.sh` expects those three files. Core skill files are forbidden from naming a product.

Cursor discovers `.cursor/skills/`, `.codex/skills/`, and `.claude/skills/` as well as `.agents/skills/`. Leaving the Claude writer in place can show a second copy of the same skill next to the shared file. [Cursor skills](https://cursor.com/docs/skills).

`asc/extensions/checker/stage/inspect.sh` is still a comment. A generated rule that only says "run `stage-inspect`" points at a stub.

This mother's `.asc_extensions_ignore` lists `agent`, `asc/cursor`, `asc/codex`, and `asc/claude`. Rendering belongs on an instance that has selected those extensions. This note does not remove those lines.

Handwritten project rules already in this mother: `.cursor/rules/asc-lightweight.mdc`, `asc-mother-guard.mdc`, `asc-dollar-prefix.mdc`. There is no `AGENTS.md` and no `.agents/` directory here.

---

## Three ways to produce the files

| Direction | What happens | Why it loses or wins |
|-----------|----------------|----------------------|
| Convert the changelog itself | Historical discussion, tentative proposals, and current guidance share one file the generator would have to interpret. | Easy once. The next edit to the discussion rewrites the guidance. |
| Render curated records and task descriptions | Explicit source files. A small transformation. Same inputs, same outputs. | **This note's choice.** |
| Ask an LLM on each generation | Useful when a human wants a draft. | Interpretation, a model dependency, and output that changes between runs become part of ordinary ASC operation. Drafting can stay outside the generator. |

---

## Two outputs

One anti-pattern does not become one skill. The 2026-09-26 rejection of `antipattern-as-skill` stands. A skill is a procedure. A rule expresses a constraint or convention the procedure tells the agent to read.

| Purpose | Example | Output |
|---------|---------|--------|
| Guidance while editing | Avoid an eager include that has no caller | A Cursor rule. The shared `AGENTS.md` section names that rule. |
| Procedure for a task | Create or modify an ASC shell action | One skill that references the relevant records and the builder templates |

A rule does not need a replacement template. `instead` is optional.

### First skill: `asc-author-shell`

Sidecar, when this leaves plan / review: `data/entities/skill/asc-author-shell.yml`. The `task` text is authored. Template placeholders do not say when to pick a shape.

The first slice includes four records on purpose. All four are `ready`, all four are selected, and the skill references all four. `hook_call_existence` is in that set. It has no `instead`. `shell_conditions` stays `draft` and stays unselected.

| Record | Choice it informs | `instead` |
|--------|-------------------|-----------|
| `asc/action_script_existence` | A new `*.sh` action is an entry point. It has to earn that. | `asc/extensions/builder/subject/action.tpl.sh` |
| `asc/inc_vs_opt-inc` | Eager `*.inc.sh` loads on every bootstrapped shell. Prefer `*.opt-inc.sh` when a caller exists. | `asc/extensions/builder/subject/subject.opt-inc.tpl.sh` |
| `asc/shell_function_existence` | A function has to earn its existence. Often the direct call is the shape. | Omitted. |
| `asc/hook_call_existence` | A hook call exists when a real variant exists. | Omitted. The hook-call templates stay unused until a later skill names them. |

`make generate` is still the empty substituter from [22-make-generate.md](./22-make-generate.md). The procedure treats a template as a file to copy by hand:

1. Decide whether the change belongs in an action, an optional include, or a hook implementation.
2. Read each selected record's `## Guidance` section. Follow the link to the rest of the record for examples.
3. When the record has `instead`, copy that template. Replace each `{{ token }}` with the text for this change. `action.tpl.sh` has `{{ docblock }}`, `{{ example }}`, and `{{ slot }}`.
4. Search the new file for `{{` and `}}`. A remaining placeholder means the copy is unfinished. The template's presence on disk is not a usable example.
5. When the record has no `instead`, do not invent a file.
6. Run the relevant available checks.

The docblock records, `shell_errors`, `general`, and `python` stay unselected until a selection lists them.

---

## Where the files go

| Destination | Who may replace it | Role |
|------------------|---------------------|------|
| `.agents/skills/<id>/SKILL.md` | `guidance-render` | Shared skill file. `f_skill_render` only stages the bytes. |
| `.cursor/rules/asc-anti-pattern/<group>/<id>.mdc` | `guidance-render`, from bytes the Cursor guidance hook staged | Cursor rule. Group and id are both in the path. |
| `AGENTS.md` | `guidance-render` | Shared project instructions for Cursor and Codex. One owned section. The hash covers that section only. |

`asc/dependencies.md` and `python/dependencies.md` become two files:

- `.cursor/rules/asc-anti-pattern/asc/dependencies.mdc`
- `.cursor/rules/asc-anti-pattern/python/dependencies.mdc`

The stem `asc-anti-pattern/` keeps these files away from the handwritten `asc-*.mdc` rules. Before any write, the planned destination map must contain each path once. A duplicate destination aborts the run.

Codex has no glob attach. Cursor rules do. `AGENTS.md` is shared project guidance, not a Codex-only file. Codex ignores `AGENTS.md` when `AGENTS.override.md` is in the same directory. [Codex skills](https://learn.chatgpt.com/docs/build-skills), [Cursor skills](https://cursor.com/docs/skills), [Cursor rules](https://cursor.com/docs/rules), [Codex `AGENTS.md`](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

The Cursor contrib README (`scripts/asc/contrib/asc/cursor/README.md`) already states the `.mdc` frontmatter table. A plain `.md` in `.cursor/rules/` is ignored. `alwaysApply: true` ignores `description`. These generated rules use `alwaysApply: false`. `description` and `globs` are YAML scalars produced by a serializer, not by wrapping an interpolated string in quote characters.

Cursor's modes are not fallbacks for each other:

| Frontmatter | When Cursor includes the rule |
|-------------|-------------------------------|
| `alwaysApply: true` | Every Agent chat in that workspace. `description` and `globs` are ignored. This generator does not emit that mode. |
| `globs` set | A matching file is in context. This is the mode these rules use. `description` is there for a human reader. It is not a second trigger. |
| `description` set and `globs` omitted | The agent judges the description. This generator does not emit that mode. |

Generation, discovery, and application are three different results:

| Stage | Meaning | What this work can claim |
|-------|---------|--------------------------|
| Generation | The selected files were written, or `check` found nothing pending. | Exit status of `guidance-render`. |
| Discovery | A fresh session can see the file. | A manual check, per product, after generation. Cursor can also see `.cursor/skills/`, `.codex/skills/`, and `.claude/skills/`. |
| Application | The product follows the file on a task. | Not claimed. A skill may be chosen from its description. That choice is not a guaranteed run. A glob rule attaches only when a matching file is in context. |

Duplicate-free discovery is guaranteed only for a clean tree: no `.cursor/skills/<id>/SKILL.md`, no `.codex/skills/<id>/SKILL.md`, and no `.claude/skills/<id>/SKILL.md` for a selected id, and `asc/claude` not enabled. This slice does not change the Claude hook and does not delete legacy copies. Identical bytes are not provenance. The old writers recorded no ownership. The Cursor and Codex skill hooks print a legacy path when their own old file exists. That print does not change the exit status. A Claude copy is noted in the discovery check, not by a new scanner.

### What a rule contains

The generator copies the body of the record's `## Guidance` section as text. It does not summarize the rest, and it does not rewrite links inside that section. Examples stay in the record.

The section is plain prose. It has no Markdown link (`](...)`) and no `@` path. A repository-relative path may appear as text. The renderer appends the source link, and the template link when `instead` is set, after the copied prose. Those appended links are the ones rewritten for the output file: one `../` per directory between that file and the project docroot, plus the same path as text. In a Cursor rule the text form is also an `@` path, which Cursor resolves from the workspace root. A link that lives inside `## Guidance` would still be resolved from the generated file, so a record that contains one cannot be `ready`.

References stored in records and skill sidecars are repository-relative (`data/entities/anti-pattern/asc/inc_vs_opt-inc.md`).

A record with no `## Guidance` section cannot be `ready`. Selecting it fails the run. The failure is a report. The tree stays as it is.

`## Guidance` for `inc_vs_opt-inc`, when this is implemented:

```markdown
## Guidance

Do not add an eager `*.inc.sh` without a strong reason. Those files load in every ASC-bootstrapped shell. Prefer `*.opt-inc.sh`. A helper used by one action can stay in that action, or be sourced as a `*.manual-inc.sh`.
```

The sections already in that file (`Anti-pattern example`, `Correct example`) stay. The other three first-slice records get a `## Guidance` section of the same kind, written by a human. The generator copies that prose and appends its own links.

### Glob scope

The record's `globs` value is a file-type pattern. The selection's `scope` decides which trees the generator turns into positive Cursor globs. `exclude` is input to that projection. It is not a negation pattern in the generated file. Cursor receives only positive globs. Whether those globs attach is a Cursor session test, not a property of the YAML.

For a pattern with no slash (`*.sh`), and for each `scope` root:

- emit `<root>/<pattern>`
- emit `<child>/**/<pattern>` for each immediate subdirectory of `<root>`, in byte sort, skipping any path listed in that root's `exclude`

The first-slice projection therefore contains `asc/extensions/**/*.sh` and omits `asc/vendor/**/*.sh`. That omission is a hypothesis until Cursor is asked. In a fresh session, a context that includes `asc/extensions/agent/skill/render.sh` must attach the rule, and a context that includes `asc/vendor/shunit2/shunit2_macros_test.sh` must not. If either result disagrees with the positive list, narrow the `scope` roots to directories Cursor does attach. Do not add a negation glob, and do not add a second config file. Until that session is run, attachment stays unverified.

---

## Selection, readiness, reconciliation

One selection file, at `$PROJECT_DOCROOT/guidance.render.yml`. Absent file: the run fails and names that path. The generator does not infer a set from enabled extensions. Listing a group is not a switch. Only the `records` and `skills` lists are selected. `asc` does not pull `general` or `python`.

A selected skill's `guidance` list must be a subset of `records`. Every referenced record must exist, have `status: ready`, and have a `## Guidance` section with no Markdown link and no `@` path. Otherwise the run fails and names the skill, the reference, and the reason (`missing`, `not selected`, `draft`, `no Guidance section`, `link inside Guidance`). It writes nothing. It also removes nothing. A record that changed to `draft` while a selected skill still names it is this failure. The existing rule stays on disk.

A selected record that is `draft`, or that has no `status`, fails the same way. Unselected drafts are ignored. `shell_conditions` stays unselected.

Removal is a later successful run, after the operator has updated the selection and the dependent skill together. On that run the record is absent from `records` and from every selected skill's `guidance`. The manifest still lists the output. The current bytes match the hash. Validation of what remains has succeeded. Then `guidance-render` deletes that unchanged file. The same bar applies to a skill id that is no longer selected. A hash mismatch is a conflict: the run reports it and leaves every file unchanged, including files that would otherwise have been removed.

Changing `status` to `draft` does not by itself remove output.

`AGENTS.md` is one section, not one file per record. The section is rewritten from the whole selected set on a successful run. The span is removed only when a successful run has an empty `records` list and an empty `skills` list, and only under the section rules below.

---

## Ownership

`guidance-render` is the only writer that replaces files in the instance, updates `guidance.render-manifest.yml`, or deletes an owned path. `f_skill_render` and the guidance hooks write into a staging directory the caller passes. They do not read the manifest.

Manifest: `$PROJECT_DOCROOT/guidance.render-manifest.yml`. This is generated state, not a second operator config. It records each owned output and the sha256 of the last bytes `guidance-render` wrote. For `AGENTS.md` that hash is the marker span only, from the start marker through the end of the end-marker line. Bytes outside the span are not hashed. An edit there is not a conflict. Generated files and this manifest stay together. A checkout that has the files without the manifest will treat those files as unowned collisions.

| Kind | Hash covers | Removal, on a successful run only |
|------|-------------|---------|
| `file` | The whole file | Delete the file when the hash matches and the selection no longer names it. |
| `section` | The marker span only | Delete that span when the hash matches and the selection is empty. Leave the rest of the file. When the remainder is empty or whitespace, delete the file too. |

Write rules, applied only after validation has succeeded and every staged file exists:

- The destination is absent: create it, record the hash.
- The destination exists and the path is not in the manifest: refuse. Do not modify it. This covers a handwritten file at a generated path.
- The destination is in the manifest and the current hash matches: replace it, record the new hash. For `AGENTS.md`, replace the span and leave the surrounding bytes.
- The destination is in the manifest and the current hash differs: leave it, report the conflict, write nothing for this run.

`AGENTS.md` is always kind `section`. The markers are `<!-- asc-agent-guidance:start -->` and `<!-- asc-agent-guidance:end -->`.

| Situation | Result |
|-----------|--------|
| The file is absent. | Initial install. Create it containing only the span and a trailing newline. |
| The file exists, the manifest has no section entry, and the file has no marker. | Initial install. Append the span. Leave the existing bytes. Hash the new span. |
| The file exists, the manifest has a section entry, and the marker pair is missing. | The managed span disappeared. Conflict. Do not append a new pair. Do not modify the file. |
| The marker pair is duplicated, or the end marker precedes the start marker. | Conflict. Do not modify the file. |
| The pair is valid once, and the span hash matches. | Replace the span on a successful run. Edits outside it stay. |
| The pair is valid once, the span is empty or whitespace, and the manifest has no section entry. | Initial install. Write the span. |
| The pair is valid once, the span has other content, and the manifest has no matching hash. | Conflict. Preserve the file. |

A failed validation, a conflict, a marker error, or a failed stage leaves the previous tree in place. Staging directories are deleted. Replacement and removal start only after validation and staging have both succeeded.

### Legacy skill copies

Deferred. The first slice installs the shared skill and the selected rules. It does not delete old product copies, and it does not treat matching text as proof that this generator wrote them.

Cursor and Codex `skill/render` hooks stop writing `SKILL.md`. When they run, each prints `legacy skill file still present: <path>` if its own old file exists for the skill id being staged (`.cursor/skills/<id>/SKILL.md`, `.codex/skills/<id>/SKILL.md`). The notice is not a planned change and not a conflict. The Claude hook is unchanged, so it does not join this report. Removal waits until a later slice has a manifest entry for that path.

---

## Interface

One new entry point: `asc/extensions/agent/guidance/render.sh`, pivot `guidance-render`. Operator input is `guidance.render.yml` plus the optional positional argument `check`. No second action and no second config file.

`guidance-render` validates the selection, asks `f_skill_render` and `hook -s guidance -a render` to stage bytes, checks ownership, then replaces. `check` stops before replacement. It prints one of three outcomes and writes nothing: no manifest update, no append, no leftover staging directory.

| Exit | Outcome | `check` | write |
|------|---------|---------|-------|
| 0 | **current** | Owned outputs already match the plan. | The plan was applied. |
| 2 | **changes needed** | The plan is valid and the tree differs. | Unused. |
| 1 | **invalid or conflicting** | Selection, markers, ownership, or staging failed. | Same. The tree is unchanged, including outputs that a valid plan would have removed. |

A legacy-file notice can appear on any of these exits. It does not select the exit.

Core files under `asc/extensions/agent/` do not name Cursor, Codex, or Claude. `.agents/skills/` and `AGENTS.md` are shared destinations and may be named there. Product paths live in contrib hooks. `skill_entity.test.sh` changes with the stager: under `SKILL_RENDER_ROOT`, one `.agents/skills/<id>/SKILL.md`; the Cursor and Codex skill hooks do not create a file; the Claude hook still creates `.claude/skills/<id>/SKILL.md` under that same root when that hook runs. The test does not require a file under the project docroot.

### Skill contract

`f_skill_render` writes `.agents/skills/<id>/SKILL.md` only under `SKILL_RENDER_ROOT`. The caller must set that variable to a staging directory. If it is unset, or if it is `$PROJECT_DOCROOT`, `f_skill_render` exits 1 and writes nothing. `asc/extensions/agent/skill/render.sh` sets a fresh staging directory, prints the staged path, and does not copy into the instance. Installing that file is `guidance-render`'s step, after the ownership checks.

A contrib `skill/render` hook writes only under `SKILL_RENDER_ROOT`, and only product-specific output. The Cursor and Codex skill hooks stop writing `SKILL.md`. They may print the legacy notice above. The Claude skill hook stays a product writer for this slice, still confined to `SKILL_RENDER_ROOT`. `guidance-render` does not promote that Claude file into the instance.

Frontmatter `description` and `globs` go through one YAML 1.2 serializer. The loaded scalar must equal the input string. Wrapping the raw text in `"` without escaping is not that serializer. Inside a double-quoted scalar the writer escapes `\` as `\\`, `"` as `\"`, newline as `\n`, carriage return as `\r`, and tab as `\t`. `:`, `#`, and `'` need no extra escape once the scalar is actually double-quoted. `alwaysApply` is the boolean `false`, not the string `"false"`.

Fixture that must round-trip, quotes and newline included:

```text
Say "ready": then stop
# not a comment
path\tail
```

`printf '"%s"'` of that fixture is invalid YAML. A parser loading the emitted frontmatter must return the same three lines.

The skill entity gains:

```yaml
guidance:
  - asc/action_script_existence
templates:
  - asc/extensions/builder/subject/action.tpl.sh
```

`guidance` entries are `group/id`. `templates` entries are repository-relative paths and must exist. Both lists are optional on the entity and required to match the selection when present.

### Guidance hook

`guidance-render` exports the variables below, then calls `hook -s guidance -a render` once per selected record. The hook writes only under `GUIDANCE_TMP`. It also writes a one-line file `dest.path` there, the repository-relative destination. The Cursor hook sets that path to `.cursor/rules/asc-anti-pattern/<group>/<id>.mdc` and exits 1 for any other path, including a `SKILL.md` or `AGENTS.md`. `guidance-render` installs the staged bytes only when the hook exited 0. The product prefix lives in the contrib hook, not in `asc/extensions/agent/`. The hook does not replace the destination. `GUIDANCE_MODE` tells the hook whether the caller is checking or writing; neither mode lets the hook touch the instance tree.

| Variable | Contents |
|----------|----------|
| `GUIDANCE_GROUP` | `asc` |
| `GUIDANCE_ID` | `inc_vs_opt-inc` |
| `GUIDANCE_DESCRIPTION` | The record description, raw |
| `GUIDANCE_GLOBS` | The projected glob string |
| `GUIDANCE_BODY` | The `## Guidance` section body, without the heading |
| `GUIDANCE_SOURCE` | `data/entities/anti-pattern/asc/inc_vs_opt-inc.md` |
| `GUIDANCE_INSTEAD` | The template path, or empty |
| `GUIDANCE_TMP` | An empty directory for this record |
| `GUIDANCE_MODE` | `check` or `write` |

There is no Codex guidance hook in this slice. The Codex skill hook's only new behavior is the legacy notice.

### Exact selection

`$PROJECT_DOCROOT/guidance.render.yml` for the first slice:

```yaml
records:
  - asc/action_script_existence
  - asc/inc_vs_opt-inc
  - asc/shell_function_existence
  - asc/hook_call_existence
skills:
  - asc-author-shell
scope:
  - root: asc
    exclude:
      - asc/vendor
  - root: scripts/asc
```

`$PROJECT_DOCROOT/data/entities/skill/asc-author-shell.yml`:

```yaml
description: Create or modify an ASC shell action, optional include, or hook call.
task: |
  1. Decide whether the change belongs in an action, an optional include, or a hook implementation.
  2. Read each guidance record's Guidance section. Open the source link for examples.
  3. When a record has a template, copy it and replace every placeholder.
  4. Search the new file for "{{" and "}}". Any hit is unfinished.
  5. When a record has no template, do not invent a file.
  6. Run the relevant available checks.
guidance:
  - asc/action_script_existence
  - asc/inc_vs_opt-inc
  - asc/shell_function_existence
  - asc/hook_call_existence
templates:
  - asc/extensions/builder/subject/action.tpl.sh
  - asc/extensions/builder/subject/subject.opt-inc.tpl.sh
```

Failure text when `hook_call_existence` is dropped from `records` while the skill still lists it:

```text
guidance-render: skill asc-author-shell references asc/hook_call_existence, which is not selected.
-> Aborting (1). No file was written.
```

Failure text when `shell_conditions` is added to `records` while it is still `draft`:

```text
guidance-render: record asc/shell_conditions is selected and its status is draft.
-> Aborting (1). No file was written.
```

### Exact rule

`.cursor/rules/asc-anti-pattern/asc/inc_vs_opt-inc.mdc`, for the scope above. The glob list is the sorted projection, not a hand-trimmed sample. The link prefix is `../../../../` because the file sits four directories under the docroot.

```markdown
---
description: "Never add eager loaded shell includes without a strong reason to do so."
globs: "asc/*.sh, asc/core/**/*.sh, asc/data/**/*.sh, asc/dir/**/*.sh, asc/doc/**/*.sh, asc/extensions/**/*.sh, asc/file/**/*.sh, asc/git/**/*.sh, asc/host/**/*.sh, asc/instance/**/*.sh, asc/log/**/*.sh, asc/loop/**/*.sh, asc/make/**/*.sh, asc/sidecar/**/*.sh, asc/ssh/**/*.sh, asc/test/**/*.sh, asc/thread/**/*.sh, asc/yml/**/*.sh, scripts/asc/*.sh, scripts/asc/contrib/**/*.sh, scripts/asc/extend/**/*.sh, scripts/asc/local/**/*.sh, scripts/asc/override/**/*.sh, scripts/asc/sandbox/**/*.sh"
alwaysApply: false
---

Do not add an eager `*.inc.sh` without a strong reason. Those files load in every ASC-bootstrapped shell. Prefer `*.opt-inc.sh`. A helper used by one action can stay in that action, or be sourced as a `*.manual-inc.sh`.

Source: [data/entities/anti-pattern/asc/inc_vs_opt-inc.md](../../../../data/entities/anti-pattern/asc/inc_vs_opt-inc.md)

@data/entities/anti-pattern/asc/inc_vs_opt-inc.md

Template: [asc/extensions/builder/subject/subject.opt-inc.tpl.sh](../../../../asc/extensions/builder/subject/subject.opt-inc.tpl.sh)
```

The owned `AGENTS.md` span for this selection names the skill and the four source paths in selection order. It does not paste the Guidance sections.

```markdown
<!-- asc-agent-guidance:start -->
# ASC agent guidance

Skill: [.agents/skills/asc-author-shell/SKILL.md](.agents/skills/asc-author-shell/SKILL.md)

Records:

- [data/entities/anti-pattern/asc/action_script_existence.md](data/entities/anti-pattern/asc/action_script_existence.md)
- [data/entities/anti-pattern/asc/inc_vs_opt-inc.md](data/entities/anti-pattern/asc/inc_vs_opt-inc.md)
- [data/entities/anti-pattern/asc/shell_function_existence.md](data/entities/anti-pattern/asc/shell_function_existence.md)
- [data/entities/anti-pattern/asc/hook_call_existence.md](data/entities/anti-pattern/asc/hook_call_existence.md)
<!-- asc-agent-guidance:end -->
```

---

## Order, revised

[26-patterns-and-antipatterns.md](./26-patterns-and-antipatterns.md) put `stage-inspect` first and the Cursor projection after that command exists. This note reverses that for guidance:

1. Add `status`, optional `instead`, and `## Guidance` on the four first-slice records. Write the skill sidecar and the selection example on the instance that will render.
2. Render with `guidance-render` on an instance that has enabled `agent` and `asc/cursor`.
3. Later, a record may grow an explicit executable check where one is meaningful. That check is a separate field and a separate go-ahead. Prose does not silently become a `block: yes` detector.

The hook design in the 2026-09-26 note stays the backstop design. This note does not implement it.

---

## First slice

On one selected instance, using the selection file above:

- Four records, two templates, one skill, four Cursor rules, one `AGENTS.md` section, one manifest.
- `shell_conditions` is not selected.
- After a successful render and after a later removal of the generated set, the handwritten `asc-lightweight`, `asc-mother-guard`, and `asc-dollar-prefix` rules are still present.
- An existing `AGENTS.md` paragraph outside the marker span is still present after a render and after the span is removed.

Verification:

- The `inc_vs_opt-inc` rule matches the exact file above. A YAML 1.2 parser loads `description` and `globs` back to the source strings. The fixture with quotes, a newline, `#`, and `\` round-trips the same way. `printf '"%s"'` of that fixture is not an acceptable writer.
- The generated glob string contains `asc/extensions/**/*.sh` and does not contain `asc/vendor/**/*.sh` or a `!` pattern. That string check is not the attachment test.
- Cursor attachment, in a fresh session: `asc/extensions/agent/skill/render.sh` in context includes the rule; `asc/vendor/shunit2/shunit2_macros_test.sh` in context does not. Until that session is run, attachment is unverified. A mismatch narrows `scope` roots. It does not add a negation glob.
- A second write with the same inputs produces the same bytes. `check` then exits 0 (**current**).
- `check` against a tree that still needs the first install exits 2 (**changes needed**) and leaves the tree unchanged.
- Dropping `asc/hook_call_existence` from `records` without editing the skill exits 1 and writes nothing. An existing rule for that id stays.
- Selecting `asc/shell_conditions` while it is `draft` exits 1 and writes nothing.
- A rendered record set to `draft` while `asc-author-shell` still lists it exits 1. Its rule, the other rules, the skill, and `AGENTS.md` stay as they were.
- Two groups with the same id produce two destinations. A destination collision exits 1 before any replacement.
- A handwritten file at a generated path, with no manifest entry, exits 1 and is unchanged.
- Editing a generated rule, then re-running, exits 1 and keeps the edit.
- An existing `AGENTS.md` with text above the insertion point and no markers, and no manifest entry, is an initial install: `check` exits 2; a write appends the span and leaves the text above it. The stored hash is the span. A later edit above the span still exits 0 when the span matches.
- A manifest section entry whose markers are then deleted exits 1 and does not append a replacement span.
- Duplicated or reversed markers exit 1 and leave the file unchanged.
- A `## Guidance` body that contains a Markdown link or an `@` path cannot be `ready`. Selecting that record exits 1 and writes nothing.
- A skill reference to a record that is not selected exits 1.
- A hook that fails while staging exits 1 and leaves the previous outputs in place.
- Calling `skill/render.sh` does not create or modify `.agents/skills/` in the instance.
- Deselecting a record and removing it from the skill, with the hash still matching, deletes that record's rule and no other file.
- Setting a record to `draft` removes its rule only on a later successful run that also omits it from `records` and from every selected skill. The draft change alone removes nothing.
- Fresh Cursor session: the shared skill and the four `.mdc` files are discoverable, and the attachment pair above has been tried. Fresh Codex session: the shared skill and `AGENTS.md` are discoverable. When `AGENTS.override.md` exists beside it, record that Codex is not reading the generated section. A legacy product copy is reported and left in place; discovery is not described as duplicate-free while it remains.

---

## Design choice

Markdown stays the canonical anti-pattern format. Skill entities compose task procedures from those records and from builder templates. The changelog explains the choice. It is not the file the generator reads.

---

## Tasks

- [x] Sixteen Markdown records exist under `data/entities/anti-pattern/{asc,general,python}/`. They already carry `description` and `globs`.
- [x] Skill render writes three private copies (`.cursor/skills/`, `.codex/skills/`, `.claude/skills/`). No `.agents/skills/` writer yet. Descriptions are interpolated raw.
- [x] `stage-inspect` is still a comment. This note does not fill it.
- [ ] Add `status`, optional `instead`, and a short `## Guidance` section. Missing `status` means `draft`. Mark the four first-slice records `ready`. Leave `shell_conditions` in `draft`.
- [ ] Write `data/entities/skill/asc-author-shell.yml` as in the exact selection. `guidance` lists those four ids.
- [ ] `f_skill_render` stages `.agents/skills/<id>/SKILL.md` under `SKILL_RENDER_ROOT` only. It refuses an unset root and refuses `$PROJECT_DOCROOT`. `skill/render.sh` does not install into the instance. Cursor and Codex skill hooks stop writing `SKILL.md`. Leave the Claude hook writing under the staging root. Update `skill_entity.test.sh`.
- [ ] `guidance-render` owns validation, the manifest, reconciliation, and replacement. It reads `guidance.render.yml`, projects positive globs, and installs staged skill and rule bytes only after checks pass.
- [ ] YAML 1.2 serialization for `description` and `globs`, with the quote, newline, and backslash fixture round-tripping through a parser.
- [ ] Manifest hashes. `AGENTS.md` hashes the span only. Initial install with no markers appends. A managed span whose markers disappeared conflicts and does not modify the file. Edits outside the span are not conflicts.
- [ ] A skill that still references a `draft` or unselected record fails before any write or removal. Removal runs only after a valid selection has dropped both the record and the skill reference, and the hash still matches.
- [ ] `guidance-render check` exits 0 (**current**), 2 (**changes needed**), or 1 (**invalid or conflicting**) and writes nothing.
- [ ] Cursor and Codex skill hooks print their own legacy skill path when that file exists. Do not delete it, and do not add a Claude scanner, in this slice.
- [ ] Cover the failure cases in the verification list, including the Cursor attachment session for a nested ASC file and a vendor file.
- [ ] First slice on an instance that has selected the extensions. Do not clear this mother's ignore entries from this note.
- [ ] Do not add `block`, do not call an LLM from the generator, and do not add a gates row.
