# Design patterns and antipatterns

| Field | Value |
|-------|--------|
| **Date** | 2026-09-26 |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | How every ASC project that also uses Cursor names a repeated shape, and how it names a repeated mistake. Design patterns stay the builder. Antipatterns are a new list agents read against what they just produced. |
| **Out of this plan** | New scripts. Filling `make generate`. Moving builder to `asc/builder/`. An `antipattern.entity.yml`. A gates row. A README edit. Enabling `agent` or `workflow`. Copying Cursor rules or skills. Importing a host shell template tree. Reordering [25-concert-order.md](./25-concert-order.md). |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), except `$HOME`.

`gates.core.yml` is a later agent approval surface. Do not add a row for this note.

This note was written on branch `to-review`. The work tree was already dirty (`README.md`, `.cursor/rules/asc-lightweight.mdc`), so the mother was not pulled. Do not treat the sentences below as written on a clean `main`.

Home-directory notes from 2026-09-24 and 2026-09-25 stay in that instance. They are not copied here. This file keeps only the generic consequences: branch contract, core-file sync, and shared Cursor how-tos.

---

## Two lists

A repeated shape and a repeated mistake are not the same record.

| List | What it is | Where it lives | What an agent does with it |
|------|------------|----------------|----------------------------|
| Design pattern | A template that produces an ASC shape | Builder extension, already on disk | Instantiate it. Do not hand-write a second copy of the same shape. |
| Antipattern | A known bad result, added as it is recognized | Not on disk yet. This note reserves the name. | After producing a diff, compare the diff to the list. A hit stops the edit. |

README already puts generating ASC code from folder or string templates in scope, at `asc/extensions/builder`. It does not mention a negative list. That omission stays until a human accepts the split in this file. No proposal block in this step.

---

## Design patterns are the builder

The positive list is the scaffold under `asc/extensions/builder/template/`. `make generate` is the substituter that is supposed to render a string, a file, or a directory from those templates. The entry point `asc/extensions/builder/instance/generate.sh` is empty. [22-make-generate.md](./22-make-generate.md) is still plan / review and authorizes a string-print slice only after its gates row is approved. This note does not fill that script and does not approve that row.

What is already there:

| Piece | State |
|-------|--------|
| `template/core/` | Real scaffold files. Filename tokens `[subject]`, `[action]`, `{subject}`, and body tokens `{{ name }}`. |
| `template/hydrate.sh`, `template/list.sh`, `template/represent.sh`, `template/diff.sh` | Stubs. |
| `template.entity.yml`, `prototype.entity.yml` | 0 bytes. |
| `prototype/*.sh` | Stubs (`build`, `rebuild`, `represent`, `status`, `update`, `list`, `test`). |
| Kernel move | [20-builder-kernel-subject.md](./20-builder-kernel-subject.md) is later. Builder stays an extension so a stack can ignore it. |

A design pattern is one of those templates plus the token contract in the generate plan. It is not a new entity type. `prototype` is the name already reserved for a built result of a template. Both entity files stay empty until a generator has emitted one file a human applied. Empty YAML is not the list.

`file/pattern.able.yml` is also 0 bytes, and it sits on the file subject. That name is a file capability, not this list. Do not reuse it for design patterns or for antipatterns.

One host still copies a project skeleton with a shell function: a named directory of templates, tokens written `{{ NAME }}`, one alias file rewritten after the copy. That is the same job as `make generate` directory mode. It is not ASC, and it does not move into this repository as part of this note. A generic template reaches `asc/extensions/builder/template/` only when a human promotes it. Host-only skeletons stay on that host.

---

## Antipatterns are the check list

An antipattern is one recognized mistake, written so the next agent can see it in a diff without a footnote. The list grows when a mistake shows up again. It is not a dump of every review comment.

It is not these things:

| Nearby name | Why it is a different record |
|-------------|------------------------------|
| Design pattern / builder template | A template emits files. An antipattern matches a diff and refuses it. |
| `skill` | [skill.entity.yml](../../../asc/extensions/agent/skill/skill.entity.yml) is one development task (synonyms `procedure`, `playbook`), stored as a sidecar at `data/entities/skill/<id>.yml`, rendered by `skill/render` into `.cursor/skills/<id>/SKILL.md`. A task is not a ban. |
| `gap` | [20-gap-entity-not-core.md](./20-gap-entity-not-core.md) keeps knowledge and task gaps out of this tree. An antipattern is a known bad shape, not an open question. |
| `file/pattern.able` | File capability stub. Wrong subject. |
| `workflow-next` | [22-workflow.md](./22-workflow.md) prints a gates row. The concertation set that printer aside. The check is not a lap closer. |
| A Cursor rule or skill file | A pointer an agent loads. The durable list is the record the pointer names. |
| A "bad ideas" section in one changelog | [25-concert-order.md](./25-concert-order.md) already states several. They stay in that note. This list is where later ones accumulate so they are not only inside the note that discovered them. |

### Shape to accept before any file

Do not add `antipattern.entity.yml` until the fields below are accepted. Another empty entity file does not start the list. The first records can be written as plain files once the fields are accepted; the entity wrapper waits until a real loader needs it.

| Field | Holds |
|-------|--------|
| `id` | Self-explainable label. One name. No numbered phase. |
| `detect` | What in the produced diff counts as a hit. Short enough to apply to a patch. |
| `instead` | The design pattern, or the existing plan, to follow. A pointer, not a second copy of that plan. |
| `scope` | `core` when every ASC instance should refuse it. `instance` when only one project should. |

No shell in the file. Maps, lists, and explicit keys, same YAML habits as an entity type. `scope: core` lives under `asc/extensions/builder/` so a later core mirror can carry it. `scope: instance` stays in that instance (`scripts/asc/extend/` or that instance's own notes) and is not promoted.

Sidecar storage is the wrong lifetime. Skill instances may rotate. An antipattern a later agent must still see is source, reviewed like code. Secrets never go in either list.

Suggested first core records, each one line, each already decided elsewhere. Writing them is a later step, after the fields are accepted. This note does not create the files.

| id | detect | instead |
|----|--------|---------|
| `long-lived-develop` | A new long-lived `develop`, release, or hotfix branch on an ASC project repo | [25-concert-order.md](./25-concert-order.md) branch contract. Feature branches stay allowed. |
| `home-buffer-on-client` | The home-directory buffer branch shape applied to another project's repository | Same note. That buffer is one repo shared by several machines. |
| `gates-as-design-queue` | A gates row added so a design note becomes the work queue | Gates stay the later agent surface. |
| `registry-rewritten-as-entities` | `file_registry` turned into YAML instances | Registry stays one string per key. |
| `blind-rule-copy` | A copy of every `.cursor/rules` file into another docroot | [25-concert-order.md](./25-concert-order.md) shared how-tos. Instance-only rules stay. |
| `antipattern-as-skill` | One skill instance per ban, rendered into `.cursor/skills/` | One list. At most one later skill whose task is "read the list and compare the diff". |

---

## What an agent checks

This is the behavior. It is not a script.

1. If the work repeats an ASC shape and a builder template already covers it, render that template. Do not invent a parallel file.
2. When the diff is ready to keep, read the core antipattern list and this instance's list.
3. Compare the diff, including branch intent, to each `detect` line.
4. A hit stops the edit. Do not paraphrase the bad shape into a cleaner file and continue.
5. A new repeated mistake becomes a new record only after a human accepts it. An agent does not grow the core list inside the same turn that produced the mistake.

`agent` is listed in `.asc_extensions_ignore`, so `skill/render` is not a pivot on this tree. Leave that ignore line. The check does not wait on enabling `agent`.

---

## Git branches

The branch contract is already the concert note. Three transports stay three: mother trunk, one repo shared by several machines, and each project's own branches. This note does not add a fourth.

Builder templates do not name branches. A branch policy is not a directory to hydrate. Antipattern records may point at the concert note so an agent checking a diff also checks the branch it is about to commit on. They do not generate branch names.

`make git-acp` still adds the whole work tree and pushes the current branch. It does not read this list. Do not wrap it.

---

## What moves between instances

Same split as any other generic core byte.

| Byte | Moves down | Moves up |
|------|------------|----------|
| Builder templates and `scope: core` antipattern records under `asc/` or `scripts/asc/contrib/asc/` | With the forward core mirror, once [23-host-asc-core-sync.md](./23-host-asc-core-sync.md) is allowed. This note does not allow `apply`. | Human promotion of a generic fix, after that instance's mother-guard search. |
| `scope: instance` antipatterns, host skeletons, instance Cursor rules | No. | No. |
| Cursor skill projections (`.cursor/skills/`) | No. `skill/render` writes them in the tree that holds the sidecar. | No. A skill file is not the list. |
| `.cursor/rules` | No. `make host-cursor-rules-sync` compares filenames and copies nothing. | No. |

Shared Cursor how-tos remain concert item 4. The only how-to this design adds later is one sentence: read the antipattern list and compare the diff. That sentence is a pointer. It is not a second copy of the records, and it does not wait on a skill renderer.

A backport of a mother improvement is still the forward mirror plus, in the other direction, a reviewed promotion. Antipattern records do not get their own sync command. Discover, the registry catalog, and the sidecar path template stay on the concert order. This list does not replace them and does not block them.

---

## Bad ideas, stated flat

- A second template copier beside `make generate`.
- Importing a host's `templates/` tree into the mother because the shell function looks like the builder.
- `antipattern.entity.yml` with an empty body, next to the empty `template.entity.yml`.
- Storing bans as `skill` sidecars.
- Reviving `gap` in core under another name.
- Using `pattern.able` on the file subject for this list.
- A checker script, a gates row, or a `workflow` lap in this step.
- Enabling `agent` so the check can render.
- Copying rules or skills across docroots so the list "arrives".
- Letting this note jump ahead of the sidecar rewrite.

---

## Order

Concert order stands. Sidecar path template first, registry left as it is, discover later, shared how-tos as their own pass.

This design sits beside that, not in front of it:

1. Human accepts the split and the four fields.
2. Then the first core records may be written as files under the builder extension. Still no entity file unless a loader needs one.
3. A single how-to pointer waits on the shared-how-to pass.
4. `make generate` stays on its own plan. New design-pattern templates wait until that renderer can write a directory, except the scaffold files already under `template/core/`.

---

## Tasks

- [ ] Human accepts: design pattern = builder template; antipattern = a check record.
- [ ] Human accepts the fields `id`, `detect`, `instead`, `scope` before any antipattern file or entity YAML.
- [ ] Do not add a checker, a gates row, a skill instance, or a README proposal in this step.
- [ ] Do not import a host template tree. Do not fill `make generate` from this note.
- [ ] Leave [25-concert-order.md](./25-concert-order.md) as the queue. Core sync and rule-filename compare stay the transports. No new copier.
