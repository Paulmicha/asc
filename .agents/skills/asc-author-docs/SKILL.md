---
name: asc-author-docs
description: "Use when writing, editing, or reviewing ASC documentation, README proposals, changelogs, project instructions, or explanatory prose about ASC concepts."
---

# Write ASC documentation from its maintained concepts

Paths below are relative to the project root containing `asc/bootstrap.sh`.
Read the relevant README sections and `.editorconfig` before editing. The README
owns ASC concepts and scope; report material inconsistencies instead of silently
redefining concepts in another document. Label proposed behavior as proposed and
verify paths before describing them as existing implementations.

## README proposals

Preserve human-written README text. Unless the user explicitly authorizes a
direct rewrite, put proposed wording beside the relevant passage inside escaped
`&lt;proposal-YYYY-MM-DD&gt;` and `&lt;/proposal-YYYY-MM-DD&gt;` delimiters, using
today's date. Leave a blank line above and below each delimiter in the source.
Make the nearby explanation clearer or shorter; use one example per idea.
Keep detailed plans in the appropriate docs or changelog, rather than expanding
README proposals into implementation inventories or creating alternate READMEs.

## Vocabulary and notation

- Use self-explanatory English labels and established ASC tokens or synonyms.
  Reply in the user's language while keeping ASC tokens unchanged. Suggest a
  clearer name when useful; rename existing concepts only within the task scope.
- In prose, distinguish a hook call from a hook implementation.
- Use `$` for conceptual placeholders such as `$subject`, `$object`, `$action`,
  `$subject-$action`, `$subject--$predicate--$object`, `$entity`, `$field`,
  `$extension` (or `$ext`), and `$vendor`. Actual names such as index, extract,
  and run-agent have no `$` prefix. Preserve real shell-variable syntax when
  explaining shell expressions.
- Keep instance-specific facts and policies in their owning instance. Link to
  maintained definitions and contracts instead of duplicating implementation
  inventories in skills.

For ASC code examples, also follow
[asc-author-code](../asc-author-code/SKILL.md). Before delivering, check terminology,
links, proposal formatting, and the distinction between planned and verified
behavior. Record durable lessons when relevant; do not create rule or changelog
edits merely to satisfy a per-step update ritual.
