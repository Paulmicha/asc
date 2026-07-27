# ASC core concept : Entities (synonym : node ?)

Entities are the shared vocabulary for “things” ASC can name, wrap, nest, and relate. Most of the `entity` extension is still design/stub; this page records the contract so living docs and ideas stay aligned.

Table of contents :

1. [represents ? (why it exists)](entities.md#represents-why-it-exists)
1. [definition (scope ?)](entities.md#definition-scope)
1. [capabilities](entities.md#capabilities)
1. [field vs prop](entities.md#field-vs-prop)
1. [sidecar](entities.md#sidecar)
1. [relationships](entities.md#relationships)
1. [compatibility, applicability ? (protocols, etc)](entities.md#compatibility-applicability-protocols-etc)
1. [yml includes (synonym : inheritance)](entities.md#yml-includes)
1. [change / workflow](entities.md#change--workflow)

TODO below is to be rewrtten to fit the TOC :

---

## represents ? (why it exists)

ASC’s ambition is self-explanatory filenames and paths. **Entities** give a common shape to anything that can be talked about in that vocabulary — jobs, hosts, instances, sidecars, plans, dependencies — without inventing a new ad-hoc YAML dialect per feature.

Useful analogy from ideas:

| Term | Meaning |
|------|---------|
| **thing** | Actual / external (software, hardware, network) |
| **entity** | Virtual model inside ASC (YAML + predicates) |

**Primordial** entity = most generic empty object = `entity.entity.yml` (mother of all entities). Upstream ASC core aims at **primitive-level** contracts and implementations — not every domain ontology.

Open: whether the public synonym stays **node** or only **entity**.

---

## definition (scope ?)

| Piece | Location | Status |
|-------|----------|--------|
| Extension | `asc/extensions/entity/` | Core-ignored by default |
| Predicates | `entity/is/*`, `entity/has/*`, `entity/field/` | Mostly TODO stubs |
| Markers | `*.entity.yml`, `*.able.yml` beside subjects | Partial examples (`thread.entity.yml`, `sidecar.able.yml`, …) |

Abstract nesting scale (most → least generic):

1. primordial  
1. primitive ancestor ?  
1. ancestor  
1. parent  
1. self  
1. child  
1. descendants  

**"Genericity" scale** (YAML / definition layers — root README):

1. Primordial — akin to the first living cell
1. Primitive — YAML files that define the YAML filename suffix (e.g. `able.able.yml`)
1. ASC core extensions
1. ASC contrib extensions
1. Third-party contrib extensions
1. Project-specific implementations

Inheritance is intended to follow remote-instance style YAML **`includes`** (parent ≈ genericity).

Minimal “hello, this depends on …” YAML shapes (planned): dependency sources (pipx, git, deb, appimage, apt), optional `.asc-extension.yml`, hardware/software/state variants.

### Files and dirs as entities

Files and folders (synonym **dir**) can be entities **without** unnecessary sidecars. Use them to target paths that may be gitignored or under generated `data/*`.

Concrete dirs are already nestable; a `dir.entity` should be `$nest.able` so relative paths of any `$subject`/`$action` (or any file) match by swapping prefixes, e.g.:

| Concrete path | Relative reading |
|---------------|------------------|
| `data/cache/foo/bar` | `data_dir.store.able`-prefixed `foo/bar` |
| `scripts/asc/override/foo/bar` | overridden `foo/bar` |

Graphical metaphor (open): files as cells; `$nest.able` ≈ zoomable fractal navigation (pagination / tree bridge TBD).

---

## capabilities

Capabilities are expressed as **`*.able.yml`** (and matching `is/able` / `has/*` scripts when implemented).

| Able | Intent |
|------|--------|
| `$wrap.able` | log, process, thread, `lt`, … |
| `$action.able` | subject entry points (rotate, recognize, …) |
| `$sidecar.able` | changelog / accesslog / time windows |
| `$field.able` | fieldable attributes |
| `contract.able` | original “able” |
| `hook.able` / `implement.able` | emitter / receiver (SKOS-style implement → ontology/taxonomy?) |
| `$nest.able` | nested-git, nested-asc, nested-host / VM / piloting, … |
| `crud.able` | vs hardcoded default entity actions |
| `forget.able` | **lifetime for all durable data** (logrotate-like for any `data/*`) |
| `depend.able` | contrib / remote deps |
| `build.able` / `combine.able` | blueprints + composition (partially out of scope for core) |
| `$use.able` | e.g. `entity/uses/global.sh` |
| `plan.able` | (auto) planified work |
| `break.able` | will it ever end? / circuit breaker / emergency kill |
| `crypt.able` | encryption opt-in |
| `protocol.able` | protocol / argument parser contracts |

Working notes also list near-synonyms to reconcile (not all need distinct files): chainable, pipeable, observable, linkable, slotable, sortable, evaluable, viewable, repeatable, sidecarable, wrappable, discoverable.

**Pattern:** capabilities ≈ `*.able.yml`. **State markers:** `is.*.yml` (able / auto / …) as synonyms of “current state”, distinct from `has/*` attributes.

Agents ideas also list `wrapper.able`, `bridge.able`, `taxonomy.able`, … — **naming must be reconciled** with the `$….able` catalog above (`contract-able` idea).

Also from rewrite notes: `workflow.able`, `slot.able`, `$nest.able` → plan; `freeze.able` for assembled/compiled entry points; builder prototypes via temporary ASC overrides in tests.

---

## field vs prop

| Term | Meaning |
|------|---------|
| **field** | Store.able **instance** values (edit.able) — per-entity data in sidecars / globals / cache / scripts |
| **prop** | YAML **"constants"** shared by all entities of that kind (inherit.able) |

Concrete **prop** example: every `*.entity.yml` has root-level `required` and `optional` keys (nestable YAML `key:value` syntax).

Concrete **field** example (TODO): use `remote_host.entity.yml` and `remote_instance.entity.yml`. A remote instance has a parent remote host; both expose a `hostname` field whose stored value ASC implementations consume.

Fields must be stabilized before relying on parent/child shared field names. See also [yml-structure.md](yml-structure.md) § props vs fields.

---

## sidecar

| Layer | Role |
|-------|------|
| **Entity** | Virtual representation of something |
| **YAML** | Concrete on-disk sidecar of that entity |
| **compose.yml** | Concrete sidecar of a (nestable) project stack |
| **Any script** | Concrete sidecar of any `$action` |

Changelogs are change sidecars; specimen files (`SPECIMEN.*`) follow the same companion pattern. See § relationships for bridge/link sketches.

---

## relationships

| Kind | Working meaning |
|------|-----------------|
| **Link** (edge?) | Virtual relation between entities |
| **Bridge** (association?) | Actual I/O or runtime coupling |
| Software / hardware | Dependency / inventory relations |

### ASC relation notation (docs / blueprints)

Two forms (presence of `--` means **not** an entry point):

| Form | Example |
|------|---------|
| `$subject`--`$object` | `remote-host--foobar` |
| `$subject`--`$predicate`--`$object` | `remote-host--reverse-proxy--state` |

Useful primarily in docs and blueprints. Mapping to complex relational DB stores is **out of scope**.

Locked docs spellings for able-based relations (always with `$`):

```text
($field.able.subject)--($field.able.object)
($triple.able.subject)--($triple.able.predicate)--($triple.able.object)
```

Map via `$action.able.yml` → `$subject.$action`. See [documentation.md](documentation.md) § `$` notation.

Examples of **bridges** (actual I/O coupling):

- [Pipe](wrappers.md#pipe) between stages
- stdout / stderr redirection wrappers
- Sidecars (durable companions beside a primary file)
- Discoverability “through wrappers × bridges” (how an agent finds the next hop)

**Emitter / receiver** labels wrap traces (differentiator). Do not confuse with a **comparator** in rules/conditions (include/exclude logic).

Extension `link` ships `linkable.entity.yml` (stub); sidecar helpers `bridge.sh` / `link.sh` are empty placeholders.

Other relation sketches from notes (open):

| Sketch | Idea |
|--------|------|
| Specimen as sidecar pattern | `SPECIMEN.*` files are companion templates beside the real config — same mental model as `*.sidecar.txt` |
| Git branch as sidecar | Branch metadata / worktree state as a sidecar of a nested-git entity |
| USB / removable store | Hardware-addressable memory: same disk, different mount/host — `$nest.able` + memory store |
| Users / ACL / permission | Compatibility predicates — see § compatibility (ideas still empty) |

Open: connectivity in a broader sense (ssh, curl, dns tooling) as first-class relations vs leaving that to [wrappers.md](wrappers.md) § remote.

---

## compatibility, applicability ? (protocols, etc)

Applicability is sketched as **`is/*`** predicates (mostly TODO):

- Visibility: `public` / `private`
- Event source: manual, agent, cronjob, interaction, timestamp, …
- Graph role: `root` / `sibling` / `leaf`, `relation`
- Contracts: `able` (cognition.able, …)

Attributes as **`has/*`** (mostly TODO): label, type, bundle, plan, log, changelog, idea, sidecar, wrapper, nested, permission, field, origin, author, license, version, state, created, changed, …

Auth pack ideas (`auth`, `acl`, `roles`, `permissions,cascading`, `sudo,human-supervising,control`) are still empty or one-line TODOs — e.g. `role.able.yml?`, `cascade.able` ≈ `nest.able?`. Do not treat them as implemented.

Also open from notes: congestion / decongestion / **circuit breaker** (pair with `break.able`); “is-book-bindable” as a tongue-in-cheek applicability joke — keep real predicates boring and explicit.

---

## yml includes

- Entity inheritance and remote-instance config both use YAML **`includes`**.
- Dependency declarations should stay declarative (`*.dependency.yml` shapes) and feed provision / nest / build flows later.
- Runtime durable entities (planned memory store): `data/<memory_store>/<entity>.yml` plus sidecar — see [organization.md](organization.md) memory/globals discussion and the `memory` extension stubs.

Until `entity` is enabled and predicates exist, prefer documenting concrete subjects (`thread`, `loop`, `sidecar`) via their live `*.entity.yml` / wrap contracts rather than inventing new YAML dialects.

---

## change / workflow

Workflow is **centered around change**:

| Idea | Detail |
|------|--------|
| Changes are entities | `change.entity.yml` is `$nest.able` (down to file/folder granularity) |
| Changelogs are sidecars | Dated `changelog/YYYY/MM/DD-*.md` companions of change entities |
| Delegate to git | Prefer git for as much of the change surface as possible |
| Form of change | Pieces of prose changelogs **or** something more formal — open; provide MVP use cases first |

Rewrite motto: every problem is a (re)formulation problem; descriptions of changes should boil down to DSL up to atomic file/folder edits. Builder can generate files/dirs from blueprints; **code refactoring stays out of core** (third-party / nested apps).

Open: task-oriented vs knowledge-oriented modes with a mutual killswitch.
