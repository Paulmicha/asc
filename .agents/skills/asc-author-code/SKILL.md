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

## Before writing code

1. Read the relevant concepts, scope, and naming conventions in `README.md`,
   plus `.editorconfig` for the files being changed.
2. List the current files under `data/entities/anti-pattern/`. Read the full
   applicable records, including examples: `general` for applicable formatting,
   `asc` for ASC shell/YAML work, and language or other groups when relevant.
   Use descriptions, globs, and the actual task to judge applicability. Include
   new records added since this skill was written.
3. List and read matching templates under `asc/extensions/builder/subject/`,
   including relevant subdirectories. Select the shape before creating a file:

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
- TODO examples are not established syntax. Apply clear prose requirements,
  without inventing missing rules or copying stale example identifiers. Resolve
  conflicts using user instructions, README definitions, and the actual runtime
  contract; raise an unresolved material conflict with the user.
- Recheck sources when scope or file types change. After context loss, reload
  relevant sources before continuing edits.

## Before delivering

Review the actual diff or proposed code against the selected templates and every
applicable record read. Correct violations introduced by this work, check that
no template placeholders remain, and run checks appropriate to the change.
Do not describe a stub checker as verification.
Support runtime claims with the relevant ASC test or action actually executed,
and report its result. Static inspection or syntax checks alone do not prove
runtime behavior; mark behavior that was not run as unverified.

Briefly report the templates/records used, validation performed, and unresolved
departures. Reading guidance once does not replace this final comparison. Apply
this workflow to code written by delegated agents too.
