---
name: asc-author-code
description: "Use when creating, modifying, proposing, or reviewing ASC code in this project, including shell actions, includes, hook calls and implementations, tests, YAML contracts, and code examples."
---

# Author ASC code from its maintained conventions

Treat builder templates and applicable anti-pattern records as required working
references throughout the task. Do not substitute remembered conventions or a
convenient neighboring implementation for reading these sources.

All paths below are relative to the project root containing `asc/bootstrap.sh`,
not to this skill directory. Run ASC commands from that project root.

## Shell files

README holds bootstrap, Bash 4, `$PROJECT_DOCROOT`, the naming prefixes
(`f_`, `p_`), include extensions, and the generated files that must not be
hand-edited (`.env`, `data/asc/globals.sh`, `data/asc/pivots.mk`,
`data/asc/cache/*`). `global.vars.sh` in an active directory is source.
The data-dir diagram also labels `data/asc/global.vars.sh`. That is not
`data/asc/globals.sh`.

A `*.sh` file in an active directory is an action. After the `.sh` suffix is
removed, a name that still contains a dot is not an action. Helpers use a
second extension: `*.hook.sh`, `*.inc.sh`, `*.opt-inc.sh`, `*.manual-inc.sh`,
`*.make.sh`. A helper that only one hook calls stays in that hook file.

Before adding a function, search `scripts/asc/extend/<subject>/<subject>.inc.sh`,
then `asc/extensions/*/*.inc.sh`, then `asc/core/`. Call another action as
`scripts/asc/extend/<subject>/<action>.sh`.

The extension ignore file is the project-root `.asc_extensions_ignore` and the
variants listed in `f_asc_extensions_ignore_filepath`.
`scripts/asc/override/.asc_extensions_ignore` is not one of them (legacy path).

Directories replaced on upgrade are the list in `asc/core/upgrade.sh`.

`*.manual-inc.sh` is explicit source only. Loaders never derive it.
`private-inc` is not a suffix. `asc/core/utils/` is not a caller or hook
directory.

Ship the smallest change that still works. Do not add an include with no
caller, and do not make an include eager when only one action or hook needs
it. Do not copy a third-party library into `asc/vendor/`, contrib, or extend.
Delegate it to a host installer. README (Vendor) names the exceptions already
in `asc/vendor/`.

Do not add `gap.entity.yml` or `gap.able.yml` in this core tree.

A harness is one generic `$subject-$action` that makes a `hook_ms` call. The
tool's extension supplies the hook implementation. Do not add a second make
pivot, entity, or able for that tool, and do not score entry points. Place
that hook implementation in `scripts/asc/contrib/asc/$extension/` unless the
tool belongs in almost every instance, then `asc/extensions/$extension/`.
Another vendor: `scripts/asc/contrib/$vendor/`. One project:
`scripts/asc/extend/`. Rank is `f_hook_ms_measure` in
`asc/core/hook.manual-inc.sh`.

## Before writing code

1. Read the relevant concepts, scope, and naming conventions in `README.md`,
   plus `.editorconfig` for the files being changed.
2. List the current files under `data/entities/anti-pattern/`. Read the full
   applicable records, including examples: `general` for applicable formatting,
   `asc` for ASC shell/YAML work, and language or other groups when relevant.
   Use descriptions, globs, and the actual task to judge applicability. Include
   new records added since this skill was written.
3. List and read matching templates under `asc/extensions/builder/subject/`,
   including relevant subdirectories. Select the shape before creating a file.
   Do not paste those templates, or the anti-pattern records, into the reply.
   When the workspace root is not the tree being edited, resolve that tree
   with `f_host_registry_get asc_mother_repo_path` after `. asc/bootstrap.sh`.
   The path is `$reg_val`. When it is empty, use `$HOME/Documents/asc` if that
   directory contains `asc/bootstrap.sh`.

   | Intended code | Template |
   |---|---|
   | Action entry point | `action.tpl.sh` |
   | Optional include | `subject.opt-inc.tpl.sh` |
   | Justified eager include | `subject.inc.tpl.sh` |
   | Abstract hook call | `abstract_hook_call.tpl.sh` or `abstract_hook_call_with_pre_post.tpl.sh` |
   | Test registration/group/case | Inspect `core.hook.tpl.sh`, `test_group.tpl.sh`, `core/`, and `{test_suite}/` |

## While implementing

- Follow the selected template closely: structure, shebang, spacing, docblocks,
  naming, and relevant bootstrap/hook conventions. Fill placeholders with
  task-specific content; retain only meaningful sections and dependencies.
- Apply the anti-patterns when choosing actions, functions, includes, and hook
  calls. Each addition must justify its existence. Prefer direct code to trivial
  wrappers and optional loading to unnecessary eager loading, as prescribed.
- Retain a source/include only when this file uses it or its required side
  effects. A source line in a sibling is not evidence that this file needs it.
- Adapt existing code within the requested scope; do not refactor unrelated
  files or third-party code to make the entire tree match.
- If no template fits, inspect the closest template and a working implementation
  of the relevant contract. Explain material departures instead of silently
  inventing conventions. Do not create a template or framework just for this task.
- TODO examples are not established syntax. The record's description still
  binds. The "Correct example" is the form to write. The "Anti-pattern example"
  is the form to refuse. Do not invent the missing example or copy a stale
  identifier. If a template and a record disagree, stop and say which lines
  disagree.
- Resolve other conflicts using user instructions, README definitions, and the
  actual runtime contract. Raise an unresolved material conflict with the user.
- Editing existing code still follows the matching records. Reshape a file
  onto a template only when the task is to change its shape.
- Recheck sources when scope or file types change. After context loss, reload
  relevant sources before continuing edits.

## Before delivering

Review the actual diff or proposed code against the selected templates and every
applicable record read. Correct violations introduced by this work, check that
no template placeholders remain, and run checks appropriate to the change.
Do not describe a stub checker as verification.
Support runtime claims with `make test-core`, a file under `asc/test/`, or the
action under test, actually executed, and report its result. Static inspection
or syntax checks alone do not prove runtime behavior. Unrun stays unverified.

Briefly report the templates/records used, validation performed, and unresolved
departures. Reading guidance once does not replace this final comparison. Apply
this workflow to code written by delegated agents too.
