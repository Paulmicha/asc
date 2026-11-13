# Simplify ASC: disk writes, paths, entities, and contracts

| Field | Value |
|-------|-------|
| **Date** | 2026-11-06 |
| **Status** | Proposed for review. Inventory and direction. Deleting files, editing the README, and adding a `gates.core.yml` row stay unauthorized. |
| **Scope** | A first picture of a smaller ASC: what the tree writes, which path spellings compete, and which entity and contract files have no reader. |
| **User question** | The half-implemented entity and contract layer, and the drafts that describe it, are the first cleanup target. |
| **Still open** | Whether the host sidecar specimen stays, whether `skill.entity.yml` stays beside `SKILL.md`, and which dated plans become historical once this direction is accepted. |

**Goal:** Name a substantial simplification that matches the README’s own scope (a thin pivot layer) and the skill-library shape already used by the four maintained skills.

**Architecture today:** Make pivots, hooks, env files, a lookup cache, and four `SKILL.md` procedures do the work. Beside them, `*.entity.yml` and `*.able.yml` describe a schema language the shell does not execute.

**Tech stack:** Bash, Make, YAML sidecars, and Markdown skills. No new store.

**Spec:** The inventories below. They were read from this tree on 2026-11-06. Mother init was not re-run. A later deletion slice re-runs `entity_discover.test.sh` and `skill_entity.test.sh` before any file leaves.

`$` in this note is an ASC placeholder (`$subject`, `$action`, `$extension`), except `$HOME`, `$PROJECT_DOCROOT`, and `$PWD`.

## Sources and evidence boundaries

- [Main README](../../../../README.md): Overarching goal, Scope, Non-goals, Skills, Entities, Data dirs, File structure. The README remains the concept source. This note reports where a paragraph describes behavior the shell does not run.
- [Build Your Own Skill Library](https://drive.google.com/file/d/1ithrUotyBW6FZBpMvYJBo1d9EKTFVUf4/view), `@0xShoopy`, Applied Agent Engineering, Field Notes 2026. All ten pages read on 2026-11-06. The formula used here is skill = trigger + procedure + resources + checks, with a short project file for facts that are true on every task. Layer names, star counts, and the cost model are the author’s. They are not an ASC contract and were not re-measured.
- [Host needs plan](06-host-needs-and-skill-feedback.md) and the review of that plan on 2026-11-06. The review stands. Its corrections are still only in that review; the needs file was not edited. This note does not reopen capture format, clocks, or where a procedure file sits. It records one consequence: a need is a Markdown record, and `idea.entity.yml` is a sidecar opt-in with no fields. |
- [Entity start](../09/10-begin-entity-system-with-remote-instances.md), [no core gap entity](../09/20-gap-entity-not-core.md), [host registry path](../09/22-xdg-state-store.md), [cache layout](../09/11-bootstrap-cache-layout-and-invalidation.md), [changelog backlog](../09/27-backlog-priority.md).
- This checkout’s [`.asc_extensions_ignore`](../../../../.asc_extensions_ignore).

Counts below were taken with `find` on `*.entity.yml` and `*.able.yml`, excluding `asc/vendor/**`. `asc/vendor/**` is committed third-party code. Bootstrap does not generate it.

## 1. Simplification in one page

The README’s scope is a thin layer: wrap other programs, keep pivot names stable, adapt with variants, and leave complex agent work to a dedicated instance. The non-goals already refuse an all-orchestrating platform.

The skill-library note describes the same split in industry vocabulary. A project file holds facts true for every task. A skill holds one procedure, loaded when its description matches, with resources opened on demand and a yes/no definition of done. Deterministic work is a script. Feedback becomes a checklist line or a changelog line.

ASC already has that shape in four places `asc/core/upgrade.sh` replaces:

- `.agents/skills/asc-actions-priority/SKILL.md`
- `.agents/skills/asc-author-code/SKILL.md`
- `.agents/skills/asc-author-docs/SKILL.md`
- `.agents/skills/asc-mother-guard/SKILL.md`

Pivots (`$subject/$action.sh`), hooks, and env files are the shell vocabulary those skills tell an agent to prefer. They are the thin layer. They stay.

The entity and contract chapters try to be a second language for the same jobs: skills, storage, validation, linking, and discovery. On disk that language is 25 `*.entity.yml` files and 126 `*.able.yml` files. Seventeen entity files and 122 ability files are empty. The loader in `asc/extensions/entity/entity.inc.sh` discovers type stems and, for the sidecar stem only, flattens `data/entities/$type/*.yml` into shell exports. Its own comment says contract files are matched and left unopened. `f_entity_instanciate` is a commented body. `include` does not merge files. `append`, `alter`, `override`, `map`, `is`, `size`, `validate`, and `default` are not applied. `entity.type` and `file.name` have no reader in `asc/**/*.sh`.

The useful cleanup is to stop growing that schema, delete the files no reader uses, and keep the running pivot, cache, registry, log, and skill files. Historical changelogs stay on disk with a status that says they are history.

This direction is proposed. It becomes a deletion only after review.

### What stays, in the proposed picture

| Piece | Role |
|-------|------|
| `$subject/$action.sh`, hooks, variants | The pivot vocabulary. |
| `.env`, `data/asc/globals.sh`, `data/asc/pivots.mk` | Instance state. `make cc` leaves them. `make reinit` rewrites them. |
| `data/asc/cache/` | Lookup only: discovery, hook matches, pivot list, test-case list. |
| `data/asc/registry/` and `$HOME/.local/state/asc/registry/` | One string per key. The host path is the accepted decision in the 2026-09-22 note. |
| `data/logs/`, `data/threads/` | Run records. |
| The four `SKILL.md` directories | Procedures. Hand-written. |
| `data/entities/anti-pattern/**/*.md` | Authoring catalog. A path under `data/entities/` with a Markdown body. The checker scripts that would parse it are still TODO. The files stay. |
| `gates.core.yml`, `SPECIMEN.gates.yml`, `SPECIMEN.env.yml` | Human approval registry and the copy models. |

### What the proposed picture retires

| Piece | Why it can go |
|-------|----------------|
| Empty `*.able.yml` and empty `*.entity.yml` | They register a stem or a filename and constrain nothing. |
| Unread sketches (`idea`, `change`, `agent`, `repo`, git abilities) | A body the shell never opens. |
| README mechanisms that exist only as headings: queue entities, thread entities, `data/skills/`, `data/prompts/`, `data/event/` | No writer and no reader. |
| Further entity features: merger, validator, linker, database instantiate, `*.contract.yml` | The July YAML note left the contract kind open. This note’s proposal is to leave it closed. |

`docs/plans/2026/09/20-gap-entity-not-core.md` already keeps a `gap` type out of core. That lock stays. The needs plan stays a host Markdown directory, outside this schema.

## 2. What this checkout enables

`.asc_extensions_ignore` turns extensions off by name. The bundled directories that remain enabled are `builder`, `checker`, `entity`, and `file_registry`.

Ignored here, so their writers do not run on mother init: `agent`, `apt`, `compose`, `crontab`, `db`, `hardware`, `hosts_file`, `interaction`, `memory`, `remote`, `remote_db`, `remote_instance`, `rules`, `software`, `ssh`, `workflow`, and the `asc/…` contrib ids in the same file (`cursor`, `codex`, `claude`, `drupalwt`, `moodle_d4php`, `remote_traefik`, `transcription`, and the rest of that list).

Core subjects are always scanned: `git`, `host`, `instance`, `thread`, `log`, `make`, `doc`, `test`, and the kernel. `builder` is enabled and its generate entry point is still a TODO. `checker` is enabled and `anti/pattern.sh` is still a TODO. Enabling the directory is not the same as a working feature.

## 3. Everything ASC writes

Paths are relative to `$PROJECT_DOCROOT` unless they start with `$HOME`. `make cc` deletes `data/asc/cache/` only. `make uninit` also deletes `.env`, `data/asc/globals.sh`, `data/asc/pivots.mk`, a leftover `data/asc/generated.mk`, and generated Compose YAML when that hook runs. Logs, threads, the registry, software state, cron scripts, and `data/entities/` survive both.

### 3.1 Bootstrap and init, in this checkout

| Artifact | Path | Writer | Disposition |
|----------|------|--------|-------------|
| Primitives cache | `data/asc/cache/core/active.sh` | `f_asc_primitives_cache_write` in `asc/core/core.manual-inc.sh`, from `asc/bootstrap.sh` when the stamp misses | Keep. Load-bearing. |
| Discovery stamp | `data/asc/cache/core/stamp` | `f_asc_primitives_cache_ensure` | Keep. |
| Hook lookup | `data/asc/cache/hook/$key.sh` | `hook` in `asc/core/hook.manual-inc.sh` | Keep. Key order is `s`, `a`, `p`, `v`, `e`, `c`, then `t` / `r`. |
| Globals | `data/asc/globals.sh` | `f_global_write` in `asc/core/global_write.sh`, from `f_instance_init` | Keep. |
| Make env | `.env` | same `f_global_write` | Keep. |
| Make include | `data/asc/pivots.mk` | `f_make_generate` in `asc/make/generate.sh` | Keep. Root `Makefile` includes it. |
| Pivot list | `data/asc/cache/pivots.sh` | `f_make_generate` | Keep. |
| Test-case list | `data/asc/cache/test-cases.sh` (override `ASC_TEST_CASE_CACHE`) | `f_make_generate_test_cases` | Keep. |
| Entity type list | `data/asc/cache/entities/types.sh` | `f_entity_types_discover`, from `asc/extensions/entity/instance/post_init.hook.sh` | The only entity product init always writes. Retire with the schema, or keep while the host specimen stays. |
| One host sidecar cache | `data/asc/cache/entities/host/foobar.home.arpa.sh` | `f_entity_cache_generate` | Specimen. The sole concrete instance is `data/entities/host/foobar.home.arpa.yml`. |

`f_entity_instances_discover` does not write an `instances.sh` index. A skip list in the remote loader mentions that name. No writer for it was found.

### 3.2 Explicit core actions

| Artifact | Path | Writer | Disposition |
|----------|------|--------|-------------|
| Log body | `data/logs/$entrypoint.txt` | `asc/log/storage.hook.sh` via `asc/log/log.wrap.sh` | Keep. The entry name is the make pivot. |
| Log sidecar | `data/logs/$entrypoint.sidecar.txt` | same hook | Keep. One line per run. |
| Rotated logs | `data/logs/$entry.txt.1` and `.2` | `f_log_rotate_file` in `asc/log/rotate.sh` | Keep. Size rotation, on `make log-rotate`. |
| Thread record | `data/threads/$entry.yml` | `f_thread_yml_write` in `asc/thread/thread.inc.sh` | Keep. |
| Thread lock | `data/threads/$entry.lock` | `f_thread_lock_acquire` | Keep. |
| Host thread index | `$HOME/.local/share/asc/threads/$hash.yml` | `f_thread_host_publish` | Keep while thread monitoring stays. This is `$HOME/.local/share`, a different tree from the registry’s `$HOME/.local/state`. Off when `ASC_MONITORING` or `ASC_HOST_THREAD_MONITOR` is `0`, `false`, or `off`. |
| Agent next-steps | `NEXT_STEPS.agent.md` or `NEXT_STEPS.agent.$INSTANCE_TYPE.md` | `f_doc_next_steps_write` in `asc/doc/next_steps.sh` | Keep. The script refuses to write the human `NEXT_STEPS*.md` file and refuses to write gates. |
| Print HTML | `data/tmp/doc-print/$name.html` | `asc/doc/md2pdf_asc.py`, `asc/doc/html_preview.sh` | Keep with the print pipeline. |
| PDF | beside the source `*.md` | `asc/doc/pdf_export.sh` | Keep. May also install Playwright browsers under `$HOME/.cache/ms-playwright` when that directory is missing. |
| In-place TOC | the given `*.md` | `asc/doc/md_toc.sh` | Keep. `pre-commit` can run it when the README has a `<nav>` block. |
| Merged markdown | caller-chosen path | `asc/doc/md_merge.sh` | Keep. |
| Upgrade clone, then swaps | `data/tmp/upstream-asc`, then `asc/`, `scripts/asc/contrib/asc/`, and the four `.agents/skills/asc-*` directories, plus `AGENTS.asc.md` | `asc/core/upgrade.sh` | Keep. The instance root `AGENTS.md` stays. The `.claude/skills` symlink is commented out. |
| Git hooks | `$PROJECT_DOCROOT/.git/hooks/$name` | `f_git_write_hooks` from `asc/git/init.hook.sh` | Writes only when `ASC_GIT_HOOKS_WIRED` is non-empty. |
| Host shell map | `$HOME/.bash_aliases_asc` (or `.bashrc_asc` / `.profile_asc`) | `asc/host/shell/write_aliases.sh` | Explicit `make host-shell-write-aliases`. Appends a source line to an existing plug. |
| User crontab | the user’s crontab, not a project file | `f_host_crontab_add` in `asc/host/host.inc.sh` | Explicit host action. |

`f_yaml_write` in `asc/yml/yml.inc.sh` is the shared YAML writer. Current callers are thread YAML and the host thread index.

### 3.3 Writers present in the tree, idle in this checkout

These scripts contain writes. The extension that owns them is listed in `.asc_extensions_ignore`, so mother init does not run them. A project instance that enables the extension does.

| Artifact | Path | Script | Extension |
|----------|------|--------|-----------|
| Compose files | `{compose,docker-compose,compose.override,docker-compose.override}.yml` at the docroot | `f_dc_write_yml` in `asc/extensions/compose/compose.inc.sh` | `compose` |
| Instance registry value | `data/asc/registry/.$slug.reg` | `asc/extensions/file_registry/instance/registry_set.hook.sh` | `file_registry` is **enabled**. Included here because it is the registry writer, not an init product. |
| Host registry value | `${FILE_REGISTRY_HOST_LEVEL_PATH:-$HOME/.local/state/asc/registry}/host/.$slug.reg` | `asc/extensions/file_registry/host/registry_set.hook.sh` | `file_registry`. Default in `global.vars.sh` is the literal `$HOME/.local/state/asc/registry`. The shell does not read `$XDG_STATE_HOME`. |
| DB password and setup flag | instance registry keys | `asc/extensions/db/db.inc.sh` | `db` |
| Routine dump | `data/db-dumps/…` then `.gz` | `asc/extensions/db/db/db.opt-inc.sh` | `db` |
| Cron scripts | `data/asc/cron.sh`, `data/asc/cron/$subject-$action.sh` | `asc/extensions/crontab/crontab.inc.sh` | `crontab` |
| Remote definition cache | `data/asc/cache/entities/remote_instance/$id.sh`, `_parsed.sh`, and `data/asc/cache/remote_instance_ids.sh` | `f_remote_instances_setup` in `asc/extensions/remote/remote.inc.sh` | `remote`. Reads a `remote_instances*.yml` hook file. Does not read `remote_instance.entity.yml`. |
| Remote download, sync, init, dumps | caller path, remote docroot, `$ASC_DB_DUMPS_DIR/$remote_id/$db_id/` | `asc/extensions/remote/remote.inc.sh`, `remote/files_dir_sync_from.sh`, `asc/extensions/remote_instance/remote/init.sh`, `asc/extensions/remote_db/remote/*.sh` | `remote`, `remote_instance`, `remote_db` |
| Skill projection | `$SKILL_RENDER_ROOT/.cursor/skills/$id/SKILL.md` and the `.codex` and `.claude` twins | `scripts/asc/contrib/asc/{cursor,codex,claude}/skill/render.hook.sh` via `f_skill_render` | `agent`, `asc/cursor`, `asc/codex`, `asc/claude` |
| Software manifest state | `data/asc/software/managed.list` | `asc/extensions/software/host/provision.opt-inc.sh` | `software` |
| Traefik files | `data/asc/traefik.yml`, `data/asc/acme.json` | `scripts/asc/contrib/asc/remote_traefik/` | `asc/remote_traefik` |
| Fetched Traefik log | `data/logs/remote/$remote_id/$stamp.traefik.log` | `scripts/asc/contrib/asc/remote_traefik/remote/traefik_logs_fetch.sh` | `asc/remote_traefik` |
| Drupal / Moodle trees and settings | app docroots, `data/tmp`, `data/private`, `config.php` / `settings.php` | `scripts/asc/contrib/asc/drupalwt/`, `scripts/asc/contrib/asc/moodle_d4php/` | those contrib ids |
| Apache vhost | `/etc/apache2/sites-available/$INSTANCE_DOMAIN.conf` | `scripts/asc/contrib/asc/apache/apache.inc.sh` | `asc/apache` |
| Transcription | `data/media/YYYY/MM/` and `transcribed.txt` | `scripts/asc/contrib/asc/transcription/transcribe/all.sh` | `asc/transcription` |
| SSH key | `$HOME/.ssh/id_ed25519_$suffix` | `asc/extensions/ssh/ssh.opt-inc.sh` | `ssh` |
| Test results | `data/test-results/…` | `asc/test/test.opt-inc.sh` when `ASC_TEST_RESULTS` is not `0` | core test subject. Runs when tests run. |

`file_registry` is the one row in that table whose extension is on. It writes when `f_instance_registry_set` or `f_host_registry_set` is called, including a generated DB password on instances that enable `db`.

### 3.4 Names that are only deleted, and paths with no writer

| Path | What the tree does | Disposition |
|------|--------------------|-------------|
| `data/asc/generated.mk` | `rm -f` in `asc/make/generate.sh` and on the uninit/setup purge lists | Legacy name. Nothing writes it. The purge line can go in the same slice that stops mentioning it. |
| `data/asc/cache/make.sh` | `rm -f` in `asc/make/generate.sh` | Legacy name of `data/asc/cache/pivots.sh`. |
| `data/asc/cache/asc.sh` | Deleted on the cold primitives path | Legacy flat cache. |
| `data/asc/cache/hook.*` (flat files) | Wiped with the hook directory on a stamp miss | Legacy. Live keys are files inside `data/asc/cache/hook/`. |
| `$HOME/.local/state/asc/needs/` | Named in the 2026-11-06 needs plan | Proposed there. No shell writer in this tree. |
| `gates.yml` / `gates.$variant.yml` | Human-authored. `next_steps.sh` says it does not write them. | Keep as the approval registry. |
| `NEXT_STEPS.md` and `NEXT_STEPS.$variant.md` | Human-authored | Keep. |
| `data/entities/queue/`, `data/entities/thread/` | README headings are `TODO` | No directory. Thread records are `data/threads/`. |
| `data/skills/`, `data/prompts/`, `data/event/` | README headings or the long-process example | No reader and no writer found. |
| `data/loops/`, `data/cronjobs/`, `data/changes/` | `.gitignore` only | No shell reference found. |
| Builder render output | `asc/extensions/builder/template/hydrate.sh` is `# TODO`. `asc/extensions/builder/instance/generate.sh` is empty. | Templates under `asc/extensions/builder/subject/` are source, not a generated tree. |
| Host instance catalog | `asc/host/instance/discover.sh` and `asc/host/instance/set.sh` are `# TODO` | The 2026-09-20 scan plan is unimplemented. |
| Core file sync | `asc/host/asc_core_sync.sh` stops at `# TODO` after a registry read | Unimplemented. `make host-cursor-rules-sync` prints and does not copy. |

## 4. Path patterns

There is no variable named `ASC_CACHE` and no generic `DATA_DIR`. Project paths hang off `$PROJECT_DOCROOT` (default `$PWD`, `asc/core/global.vars.sh`). Host paths are absolute under `$HOME`.

### 4.1 Patterns the code uses

| Pattern | Purpose | Disposition |
|---------|---------|-------------|
| `./asc/$subject/` | Core active dir. | Keep. |
| `./asc/extensions/$extension/$subject/` | Bundled extension. | Keep the rung. Empty schema files inside it are the removal candidates in §5 and §6. |
| `./scripts/asc/contrib/asc/$extension/` and `./scripts/asc/contrib/$vendor/$extension/` | Contrib rungs. | Keep. |
| `./scripts/asc/extend/$subject/` | Project-specific rung. | Keep. |
| `$subject/$action.sh`, `$subject/$action.hook.sh`, `pre_` / `post_` | Pivots and hooks. | Keep. |
| `.asc_extensions_ignore` and the dotted `STACK_VERSION` / `HOST_TYPE` / `INSTANCE_TYPE` variants | Which extensions are off. Last existing file wins. | Keep. |
| `env.yml` and its variant and `.env-local*` forms | Instance env. | Keep. |
| `data/asc/globals.sh`, `data/asc/pivots.mk`, `.env` | Generated instance state, outside the cache directory. | Keep. The cache diagram in the README labels the globals file `data/asc/global.vars.sh`. The file tree later in the same README, and the code, use `data/asc/globals.sh`. The running name is `globals.sh`. |
| `data/asc/cache/core/`, `data/asc/cache/hook/`, `data/asc/cache/pivots.sh`, `data/asc/cache/test-cases.sh` | Accepted 2026-09-11 layout. | Keep. |
| `data/asc/cache/entities/$type/$id.sh` | Load cache. | Tied to the entity loader. |
| `data/entities/$type/$id.yml` | Sidecar input. Only types whose `include:` chain names `sidecar.able`. | One real file: `data/entities/host/foobar.home.arpa.yml`. |
| `data/entities/anti-pattern/$group/*.md` | Catalog. Discovery globs `*.yml` only, so these files are outside the entity loader. | Keep the Markdown. A later path rename is a separate README proposal. |
| `data/asc/registry/.$slug.reg` | Instance registry. | Keep. |
| `$HOME/.local/state/asc/registry/host/.$slug.reg` | Host registry. Accepted 2026-09-24. | Keep. |
| `data/logs/`, `data/threads/` | Run records. | Keep. The README data-dir heading `data/entities/thread` and the file-tree comment that calls `data/entities/` the log place describe other paths. |
| `data/db-dumps` | `ASC_DB_DUMPS_DIR`. | Keep the dump feature where `db` is enabled. Two subdirectory orders are written in comments and in code; see §4.2. |
| `data/tmp/`, `data/tmp/upstream-asc`, `data/tmp/doc-print/` | Scratch, upgrade clone, print HTML. | Keep. |
| `changelog/YYYY/MM/DD-$name.md` | This tree’s plan spelling. | Keep for changelogs. |
| `.agents/skills/$id/SKILL.md` | Procedures upgrade copies. | Keep. |
| `.cursor/skills/`, `.codex/skills/`, `.claude/skills/` under `SKILL_RENDER_ROOT` or the docroot | Projections of a skill sidecar, written by ignored contrib hooks. | Idle here. The four maintained skills are the hand-written source. |
| `scripts/asc/extend/custom.mk` | Optional Make include. | Hand-authored when present. |

### 4.2 Competing layouts

These are the collisions a simplification has to pick from. Each row is a fact in the current tree.

| Topic | Layouts found | Proposed pick |
|-------|----------------|---------------|
| Generated globals name | Code writes `data/asc/globals.sh`. Sources in active dirs are `global.vars.sh`. The README cache diagram says `data/asc/global.vars.sh`. | `data/asc/globals.sh`. A later README proposal corrects the diagram. |
| Include override vs hook override | Hooks swap through `scripts/asc/override/` (`asc/core/hook.manual-inc.sh`). Includes swap through `scripts/overrides/` (`asc/core/autoload.manual-inc.sh`). The autoload comment and the README both say `scripts/asc/override`. | One prefix, chosen when that code is next touched. This note does not change it. |
| Remote rows vs sidecars | Sidecars are `data/entities/$type/$id.yml`. Remote rows are a `remote_instances*.yml` hook file compiled into `data/asc/cache/entities/remote_instance/`. | Leave the remote compiler as its own hook until someone enables `remote`. Do not add `data/entities/remote_instance/` in the name of consistency. |
| Skills | `SKILL.md` under `.agents/skills/`. Product copies under `.cursor`, `.codex`, `.claude`. A skill type would be `data/entities/skill/$id.yml`. `data/skills/` is a TODO heading. `*.able.yml` is a third spelling of “skill” in the README synonym list. | One source: hand-written `SKILL.md`. Render hooks stay available for a later instance that enables them. `data/skills/` stays uncreated. |
| Host state vs host share | Registry: `$HOME/.local/state/asc/registry`. Thread index: `$HOME/.local/share/asc/threads`. Needs, if implemented as the other plan says: `$HOME/.local/state/asc/needs/`. | Three directories with three jobs. Do not fold them into the registry’s one-string files. Do not derive needs from `FILE_REGISTRY_HOST_LEVEL_PATH`. |
| Dump directories | Host routine path uses `$ASC_DB_DUMPS_DIR/local/$DB_ID`. A comment and the container global use `$DB_ID/local`. Remote sync uses `$remote_id/$db_id`. | Pick one order in a `db` slice. Out of this note’s deletion list. |
| Compose basenames | Generate mode writes `compose.yml` and `compose.override.yml` and still looks up `docker-compose.yml` and `docker-compose.override.yml`. | `compose.yml` and `compose.override.yml` when Compose work resumes. |

### 4.3 Datestamp spellings

**2026-11-13 direction:** The [local action records idea](../../../ideas/2026/11/13-local-action-records.md) proposes dated per-launch wrapper logs and separate chat archives, and deprecates `data/changes/`. The existing paths and proposed picks in this inventory remain historical observations, not evidence that the newer layout is implemented.

These are different conventions. This note adds none.

| Spelling | Where | Writer? |
|----------|-------|---------|
| `YYYY/MM/DD-$name.md` | `changelog/` | Human files. Accepted for this directory. |
| `data/$name/YYYY/MM/DD/HH.MM.SS.MS.$file.md` | README long-process example, `data/event/…` | No writer found. |
| `data/$name/YYYY/MM/DD/HH-II-SS-$file.txt` | `docs/plans/2026/09/25-concert-order.md` | Proposal. `sidecar.able.yml` at `asc/sidecar/` is absent. |
| `YYYY/MM/DD/HHhMM-$slug-need.md` | Needs plan, under `$HOME/.local/state/asc/needs/` | No writer. A review on 2026-11-06 asked for zero-padded hours. |
| `%Y-%m-%d.%H-%M-%S` | DB dump token, and `data/logs/remote/$id/$stamp.traefik.log` | Used when those actions run. |
| `%Y-%m-%dT%H:%M:%S.%3N` | Inside log sidecar lines and thread YAML | File contents, not directories. |
| `YYYY/MM` | `data/media/` in the transcription script | Used when that contrib runs. |
| `.1` / `.2` | `asc/log/rotate.sh` | Used. A rotation suffix, not a date. |

Proposed rule until a new writer exists: changelog files keep `YYYY/MM/DD-$name.md`. Dump files keep the stamp they already write. A third dated tree waits until that feature has a single owner.

## 5. Entities

Discovery scans `*.entity.yml`. Stem is the filename (`host.entity.yml` → type `host`). A duplicate stem keeps one type; the deepest path wins. `include:` is walked only to answer “does this chain name `sidecar.able`?”. The type file is not merged into the instance. Reserved roots are dropped when the cache is generated. `hostname` is filled from the filename for the type names `host` and `remote_host` by a hardcoded branch, not by reading `map:`.

The 2026-09-10 plan’s tasks 1–7 (load, discover, generate, post-init, getters, remote wrapper) are in the code. Its non-goals (merger, database instantiate, remote rows as sidecars) are still open. This note proposes to stop there and remove the unused declarations, rather than implement task 8’s schema.

`entity_discover.test.sh` requires type `host`, the `sidecar.able` stem on that type, and the field name `hostname`. It expects a missing type `file` to fail the sidecar check. It does not name the empty types. `skill_entity.test.sh` requires `skill.entity.yml`.

### 5.1 Files with a body

| Path | What the YAML contains | Runtime today | Disposition |
|------|------------------------|---------------|-------------|
| `asc/host/host.entity.yml` | `include: sidecar.able`, `map.hostname`, `required.field.hostname` | Init caches the one sidecar. Getters see the key `hostname`. `is`, `size`, `default`, `validate`, and `map` are stored as text and unused. | Keep while the specimen and its test stay. |
| `data/entities/host/foobar.home.arpa.yml` | `include: host.entity` | The one concrete instance. Hostname comes from the filename. | Keep with the specimen. |
| `asc/extensions/remote/host/remote_host.entity.yml` | `include: host.entity` | Unread while `remote` is ignored. | Keep only if the include-chain specimen is still wanted. Otherwise a removal candidate with the rest of the schema. |
| `asc/extensions/agent/skill/skill.entity.yml` | Sidecar plus `render.able`; required `description` and `task`; optional `body` | `f_skill_render` would generate one skill cache. `agent` is ignored, so init skips it. The test calls the getters. | Keep until that test is retired. The library source remains `SKILL.md`. No `data/entities/skill/` instances exist. |
| `asc/extensions/entity/asc/entity.entity.yml` | Synonym `label` → `name`, `title` | Indexed as type `entity`. No field reader. | Vocabulary for the README primitive paragraph. Removal candidate once that paragraph no longer points at the file. |
| `asc/extensions/workflow/idea/idea.entity.yml` | `include: sidecar.able` and comments | `workflow` is ignored. The needs plan cites it to record that it is not a needs schema. | Removal candidate. |
| `asc/extensions/workflow/change/change.entity.yml` | `required.fields` / `optional.fields` (plural) | The getter looks for `required.field` (singular), so the keys would miss even if `workflow` were enabled. | Removal candidate. |
| `asc/extensions/agent/agent/agent.entity.yml` | Synonyms and `include: store.able` | Nothing reads it. `store.able.yml` is empty. `memory` is ignored. | Removal candidate. |
| `asc/git/repo.entity.yml` | `depends_on.entity` and `url.field` | Indexed as type `repo` because `git` is a core subject. The getter learns nothing beyond `id`. | Removal candidate. |

### 5.2 Empty entity files

These 17 files are 0 bytes. On an enabled tree they add a type stem and nothing else. Ignored extensions are not indexed.

| Path | Indexed on mother init? | Disposition |
|------|-------------------------|-------------|
| `asc/host/dependency.entity.yml` | yes | Removal candidate. |
| `asc/host/process.entity.yml` | yes | Removal candidate. |
| `asc/host/vitals.entity.yml` | yes | Removal candidate. |
| `asc/instance/instance.entity.yml` | yes | Removal candidate. |
| `asc/thread/thread.entity.yml` | yes | Removal candidate. |
| `asc/extensions/builder/template/template.entity.yml` | yes (`builder` is enabled) | Removal candidate. Builder templates on disk are `*.tpl.sh`. |
| `asc/extensions/builder/prototype/prototype.entity.yml` | yes | Removal candidate. |
| `asc/extensions/agent/llm/llm.entity.yml` | no | Removal candidate. |
| `asc/extensions/workflow/change/plan.entity.yml` | no | Removal candidate. |
| `asc/extensions/memory/store/store.entity.yml` | no | Removal candidate. |
| `asc/extensions/memory/storage/storage.entity.yml` | no | Removal candidate. |
| `asc/extensions/hardware/hardware/hardware.entity.yml` | no | Removal candidate. |
| `asc/extensions/hardware/nested_hardware/nested_hardware/hardware.entity.yml` | no, and deeper than the depth-2 scan | Removal candidate. The nested directory stays until the subjects-ignore plan decides the nest fixture. |
| `asc/extensions/software/software/software.entity.yml` | no | Removal candidate. |
| `asc/extensions/software/nested_software/nested_software/nested_software.entity.yml` | no, and too deep | Removal candidate. Same nest-fixture note. |
| `asc/extensions/remote/remote_host.entity.yml` | no | Removal candidate. Duplicate stem of `remote/host/remote_host.entity.yml`. |
| `asc/extensions/remote/remote_instance.entity.yml` | no | Removal candidate. The remote catalog compiler does not open it. |

There is no `gap.entity.yml` and no `anti-pattern.entity.yml`. Keep that absence.

### 5.3 README sentences the loader does not perform

Recorded so a later proposal can shorten the Entities chapter. This note does not rewrite the README.

- `include` merges files. The loader matches a stem.
- `append` / `alter` / `override` edit an inherited declaration. Those roots are skipped.
- `map`, `default`, `validate`, `is`, `size`, `allowed`, `storage` change behavior. They are not applied.
- The host contract chain runs `entity.entity` → `able.able` → `sidecar` → `shell` → `ssh` → `host` → `remote_host`. On disk, `host.entity.yml` includes `sidecar.able` only.
- `asc/sidecar/sidecar.able.yml` is the cited sidecar contract. That path is absent. Empty copies named `sidecar.able.yml` live under `thread`, `workflow/change`, `hardware`, and `software`.
- Dynamic storage through `store.able.yml` and `f_entity_instanciate`. The ability file is empty and the function body is commented out.
- Linking and `reference:` have no reader.
- `data/entities/queue`, `data/entities/thread`, and `data/skills` are storage. Those directories are absent.

## 6. Contracts

There is no `*.contract.yml` and no loader that opens one. Three different things share the word:

| Kind | What it is | Examples that actually constrain something |
|------|------------|--------------------------------------------|
| Shell behavior locked by tests | Functions and flags | `f_entity_load` sources `data/asc/cache/entities/$type/$id.sh`. `hook_ms` selects `gates.core.yml` in `next_steps.test.sh`. `f_yaml_parse` writes an output variable. Drupal settings tokens stay literal PHP. |
| Human registries | YAML a person edits | `gates.core.yml` (not sourced; a task may go ahead only when `go` is `yes`, and nothing in runtime enforces that). `.env-local.yml` (`instance.type: core`), loaded by `f_instance_yaml_config_parse`. `*.crontab.yml`, loaded when `crontab` is enabled. `remote_instances*.yml`, compiled when `remote` is enabled. No specimen remote file is in this tree. |
| `*.able.yml` | README’s name for a capability | The stem string inside an entity `include:` list. The file itself is unopened. |

`asc/extensions/entity/asc/yml.yml` points at `asc/core/able.able.yml`, `asc/core/contract.entity.yml`, and `asc/extensions/entity/entity/entity.entity.yml`. Those three paths are absent. `able.able.yml` and `entity.entity.yml` live under `asc/extensions/entity/asc/`.

### 6.1 Ability files that contain text

| Path | Body | Reader | Disposition |
|------|------|--------|-------------|
| `asc/extensions/entity/asc/able.able.yml` | Synonym `skill` → `capability`, `ability`, `contract` | None. Abilities are not globbed. | Vocabulary. Same treatment as `entity.entity.yml`. |
| `asc/extensions/agent/skill/render.able.yml` | Comment describing `hook -s skill -a render` and the `SKILL_*` exports | The skill test greps this file. `f_skill_render` does not parse it. | Keep while the skill test and the render hooks cite it. |
| `asc/git/git.able.yml` | `entities: [folder, file]` | None | Removal candidate, with the git state draft. |
| `asc/git/state.able.yml` | Allowed states for folder and file | None | Removal candidate. The only written enum in the ability set, and still unread. |

### 6.2 Empty ability files

122 files, 0 bytes. Grouped by directory. All are removal candidates. Deleting them changes no `include:` match, because the match uses the stem written in the entity file.

| Directory | Count | Note |
|-----------|-------|------|
| `asc/extensions/software/software/` | 31 | Includes a `sidecar.able.yml` copy. |
| `asc/extensions/software/nested_software/nested_software/` | 30 | Same family, plus a `sream.able.yml` typo. |
| `asc/extensions/hardware/hardware/` | 24 | Includes a `sidecar.able.yml` copy. |
| `asc/extensions/hardware/nested_hardware/nested_hardware/` | 23 | |
| `asc/host/` | 5 | `nest`, `provision`, `shell`, `ssh`, `synchronize`. The README links these. A README proposal has to land with the deletion or the links dangle. |
| `asc/extensions/workflow/change/` | 5 | `chain`, `link`, `nest`, `sidecar`, `taxonomy`. |
| `asc/extensions/entity/entity/` | 1 | `measure.able.yml`. |
| `asc/extensions/entity/field/` | 1 | `field.able.yml`. |
| `asc/extensions/memory/store/` | 1 | `store.able.yml`, the file the README cites for storage assignment. |
| `asc/thread/` | 1 | `sidecar.able.yml`. |

Do not recreate `asc/sidecar/sidecar.able.yml`, `asc/core/contract.entity.yml`, or `contract.able.yml`. The sidecar contract that runs is the string `sidecar.able` in `host.entity.yml`.

### 6.3 Keep, as contracts that are not the schema

- `gates.core.yml` and `SPECIMEN.gates.yml`
- `.env-local.yml` and `SPECIMEN.env.yml`
- Crontab YAML, for instances that enable `crontab`
- The shell tests named in the table above
- `data/entities/anti-pattern/**/*.md`, as authoring rules the checker does not yet execute

## 7. Drafts that describe the schema

The changelog index’s frontier paragraph still says entity discovery is unstarted. [The backlog](../09/27-backlog-priority.md) already records that this is stale: tasks 1–7 shipped, and the remainder is a README proposal. Completed notes stay. The following open plans assume a schema this note proposes to retire. Accepting this direction marks them historical. It does not delete them.

| Plan | What it assumes | Proposed status after acceptance |
|------|-----------------|----------------------------------|
| `2026/09/10-begin-entity-system-with-remote-instances.md` | Continue from discovery into a fuller entity system. | History of the loader that shipped. No further schema tasks. |
| `2026/07/24-yml-structure.md` | A possible `*.contract.yml` kind. | Closed by this note’s proposal: no new kind. |
| `2026/09/22-make-ds.md` and `make-ds-literal.md` | A core DSL entry point over the entity vocabulary. | Park. The gates rows are already `go: no`. |
| `2026/09/22-make-generate.md` and `make-generate-string.md` | Render builder templates, starting from a string. | Park. Separate from deleting empty `template.entity.yml`. The `*.tpl.sh` sources stay. |
| `2026/09/22-xdg-state-store.md` | Host registry path, plus a `store` vocabulary. | The registry path stays accepted. `store.entity.yml` / `store.able.yml` are empty removal candidates. Memory stays disabled. |
| `2026/09/25-concert-order.md` | A dated sidecar path template. | Park until a writer exists. |
| `2026/09/22-workflow.md` | `workflow-next` printing gates rows. | Unrelated to entity deletion. Stays a plan with `go: no`. |
| `2026/09/22-gates-registry-alternative.md` | `reg-get` / `reg-set` YAML as a second gates store. | Park. `gates.core.yml` remains the registry. |
| `2026/11/06-host-needs-and-skill-feedback.md` | Host Markdown needs. | Stays proposed on its own terms. It must not grow an entity type. |

`NEXT_STEPS.agent.core.md` was generated earlier and does not list this note. Regenerating it is a separate explicit action. This note does not run `asc/doc/next_steps.sh`.

## 8. Proposed target

After the deletion slice, a stranger reading the tree should be able to say:

1. Actions live at `$subject/$action.sh`. Hooks and variants select implementations. `.env` and `data/asc/globals.sh` hold the instance. `data/asc/pivots.mk` is the Make list.
2. `data/asc/cache/` is disposable lookup. `make cc` removes it and leaves instance state.
3. One host map of strings lives at `$HOME/.local/state/asc/registry`. One host thread index lives at `$HOME/.local/share/asc/threads`.
4. Procedures for agents live in `.agents/skills/*/SKILL.md`.
5. The entity loader, if it remains for one more slice, knows type `host` and one fixture file. It does not know twenty empty types.
6. Capability files that remain are the ones a test or a person opens: `render.able.yml` while the skill test needs it, and the human registries in §6.3.

README edits that follow are dated proposals beside the Entities, Data dirs, and File structure passages: correct `globals.sh`, point thread storage at `data/threads/`, and shorten the contract chain to the stem the loader matches. Those proposals are a later slice.

## 9. Open questions

1. **Host specimen.** Keep `host.entity.yml` and `data/entities/host/foobar.home.arpa.yml` as the regression fixture, or delete the loader in the same slice and drop `entity_discover.test.sh` with it?
2. **Skill schema.** Keep `skill.entity.yml` for `skill_entity.test.sh`, or treat the four `SKILL.md` files as the only skill source and retire the test with the schema?
3. **Remote.** The remote compiler is a real writer and it ignores `remote_instance.entity.yml`. Leave that compiler untouched until `remote` is enabled somewhere, which is the proposal here?
4. **Anti-pattern path.** Leave the Markdown under `data/entities/anti-pattern/`, or move it beside `asc/extensions/checker/` in a later rename?
5. **Ignored extension trees.** Delete empty YAML now, and leave `hardware`, `software`, `memory`, and `workflow` directories in place until each extension is either implemented or removed as a whole?
6. **Index.** The frontier paragraph in `changelog/README.md` still describes 2026-09-21. Rewriting that paragraph is its own edit. This note only adds a 2026-11 row.

The proposed answers are: keep the host specimen for one slice; keep `skill.entity.yml` until its test is explicitly retired; leave the remote compiler alone; leave the anti-pattern path alone; delete empty YAML without removing extension directories; leave the frontier paragraph for a dedicated index edit.

## 10. Later slices, unauthorized

Each slice needs its own review. None of them is a `go: yes` row.

1. Delete the 122 empty `*.able.yml` files, the 17 empty `*.entity.yml` files, and the unread sketches in §5.1 (`idea`, `change`, `agent`, `repo`, `git.able.yml`, `state.able.yml`). Re-run the entity and skill tests. Update the needs plan’s citation of `idea.entity.yml` in the same slice so it does not point at a removed file.
2. Add README proposals, escaped, beside the Entities and Data dirs passages the inventories contradict.
3. Decide the host specimen (question 1) and either keep the loader or remove `asc/extensions/entity/` from the enabled set.
4. Collapse the two override prefixes when include loading is next edited.
5. Pick one dump-directory order when `db` is next edited.
6. Mark the parked plans in §7 historical in the changelog index, without deleting the files.

Writing this note does not modify skills, does not write host state, and does not change `gates.core.yml`.
