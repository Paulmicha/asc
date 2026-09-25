# Cursor ASC contrib extension

Hooks and host commands for the Cursor IDE. `skill/render.hook.sh` writes a skill projection. `host/cursor_rules_sync.sh` (`make host-cursor-rules-sync`) pulls the mother and prints each local instance’s `.cursor/rules` next to the mother’s. It does not copy rules.

## Where Cursor rules apply

Files in a project’s `.cursor/rules/*.mdc` are project rules. They load for the workspace whose root is that project. `alwaysApply: true` means every Agent chat in that workspace, including files under subfolders while the window stays rooted there.

Open a different folder as the workspace and those files drop out. That window uses that folder’s own `.cursor/rules`. A parent folder’s `.cursor/rules` still applies to projects under that parent, because discovery walks upward.

Rules that follow the user to every project are User Rules, set in Customize → Rules. They are plain text on the Cursor account. They have no frontmatter, no globs, and no `alwaysApply`. Team rules, when present, also apply across that team’s projects and may use a glob. Precedence when guidance conflicts: Team Rules, then Project Rules, then User Rules. All applicable rules are merged.

A home directory that is itself the workspace does not make its `.cursor/rules` host-wide. Same path on disk, project scope only. `~/.cursor/rules` is machine-local storage. It is not applied when another folder is the workspace.

Rules apply to Agent chat. They do not apply to Tab completion or Inline Edit.

`AGENTS.md` in the project root (and in subdirectories) is plain markdown with no frontmatter. Nested files combine with parents. The more specific file wins. Use `.mdc` when a rule should be conditional.

## Rule syntax

Project rules are `.mdc` files. A plain `.md` file in `.cursor/rules` is ignored. One concern per file. Keep a file under 500 lines.

```markdown
---
description: When this rule is relevant
globs: asc/**/*.sh, scripts/asc/**/*.sh
alwaysApply: false
---

# Title

Do this. Point at a real file with @path instead of pasting it.
```

| `alwaysApply` | `description` | `globs` | When it is included |
| --- | --- | --- | --- |
| `true` | ignored | ignored | Every Agent chat in that workspace |
| `false` | omitted | set | A matching file is in context |
| `false` | set | omitted | The agent judges the description relevant |
| `false` | omitted | omitted | Only when the chat `@`-mentions the rule |

Globs are comma-separated. `*.sh` matches the project root. `**/*.sh` matches any directory. `asc/**` matches everything under `asc/`.

```text
✅ alwaysApply: true for a constraint every chat in that workspace must see
✅ globs when the rule is about one kind of file
✅ a description when the agent should pull the rule in only sometimes
❌ alwaysApply: true on a rule that only matters for one directory
❌ a description plus alwaysApply: true (the description is ignored)
```

## Local plugin

A local plugin reuses `.mdc` rules in any folder. The load does not depend on which folder is open.

```text
~/.cursor/plugins/local/<name>/.cursor-plugin/plugin.json
~/.cursor/plugins/local/<name>/rules/*.mdc
```

`plugin.json` is `{"name": "<name>"}`. After adding or changing it, run Developer: Reload Window. `alwaysApply` and globs work as they do in a project.

## How to use them

Add a rule when the same mistake shows up again. Check project rules into git. Reference a canonical file with `@path` instead of copying code into the rule.

```text
✅ One concern, a concrete example, and the path of a file that already does it right
✅ Split a long rule into several files
❌ A style guide a linter already enforces
❌ Every command the agent already knows
❌ An edge case that rarely happens
❌ A second copy of what the codebase already says
```
