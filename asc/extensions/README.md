# ASC extensions

Every folder in this path is an extension, but not their subfolders.

In order to disable extensions without having to delete or move their folder,
add one per line in the dotfile `.asc_extensions_ignore` (to be placed in
`scripts/asc/override/.asc_extensions_ignore`).

Core also ships `asc/extensions/.asc_extensions_ignore` (default exclusions for
this tree). Project override files take precedence when present.

### preset

Canonical / ideal ASC presets (discover → list → write → improve). Lives as an
extension so packs stay out of core subjects; subject folder matches the
extension name (same layout as `software` / `nested_asc`):

| Action | Path | Make |
|--------|------|------|
| Catalog ideals | `asc/extensions/preset/preset/discover.sh` | `make preset-discover` |
| Host-filtered catalog | `asc/extensions/preset/preset/list.sh` | `make preset-list` |
| Apply packs / scaffolds | `asc/extensions/preset/preset/write.sh` | `make preset-write …` |
| Diagnose / hook dry-run | `asc/extensions/preset/preset/improve.sh` | `make preset-improve …` |

Helpers: `asc/extensions/preset/preset/preset.inc.sh` (`u_preset_root` → that dir).
Pack templates (`app`, `db`, `11ty`, …) sit under the subject folder so they are
not mistaken for extension subjects. Enabled by default (not listed in
`.asc_extensions_ignore`).

### nested_asc

Optional extension for listing nested ASC project instances and running commands
in a virgin env inside them:

| Action | Path | Make |
|--------|------|------|
| List / map layouts | `asc/extensions/nested_asc/nested_asc/list.sh` | `make nested-asc-list [ref]` |
| Virgin-env exec | `asc/extensions/nested_asc/nested_asc/exec.sh` | `make nested-asc-exec <ref> e:<entry>` / `exec.sh <ref> <entry>` / `-- <cmd>` |

`ref` is a short id from the instance folder name (Compose-style). On name
collisions, qualify with parent folders (`client/my-project`). Absolute paths
still work. Command argument forms after `<ref>`:

| Form | Behavior |
|------|----------|
| `<make-entry>` / `e:<make-entry>` | Nested `make <entry> …` (`e:` only when calling via `make`) |
| Path-like (`/`, `./`, `../`, contains `/`, ends `.sh`, or existing file) | Raw in child — no make wrap |
| `-- <cmd…>` | Explicit raw command |

Shared helpers: `nested_asc.opt-inc.sh` (lazy via bootstrap phase 90 when any
subject action bootstraps). Optional `$action.opt-inc.sh` for action-only
helpers. Not `nested_asc.inc.sh` (eager `ASC_INC`).

Listed in `.asc_extensions_ignore` by default — remove `nested_asc` from the
active ignore file and `make reinit` to enable.
