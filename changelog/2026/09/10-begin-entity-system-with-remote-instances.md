# Begin entity system with remote instances

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

| Field | Value |
|-------|--------|
| **Date** | 2026-09-10 |
| **Status** | plan (corrected: contracts vs types; discovery → cache → load) |
| **Scope** | README `#### Instanciation`: implement the missing functions that (1) discover entity **types**, (2) discover concrete **instances**, (3) generate **cached** instances for `f_entity_load`. First consumer: replace the body of `f_remote_instance_load()`. |
| **SoT** | Root `README.md` § Entities. Stub already started: `asc/extensions/entity/entity.inc.sh`. Fixture: `data/entities/host/foobar.home.arpa.yml`. |
| **Not this file** | Treating `sidecar.able` as an entity type or filling `*.able.yml` as if they were `*.entity.yml`; full `include` / `override` / `alter` / `append` schema merger; Linking vs Nesting; DB storage; `dirs.yml`; enabling `remote` in this repo’s ignore file. |

**Goal:** During instance (re)init, ASC discovers every enabled entity type and every concrete instance of those types, writes loadable cache files, and `f_entity_load <type> <id>` sources that cache in the calling shell. `f_remote_instance_load` becomes a wrapper around that.

**Architecture:** Type files (`*.entity.yml`) are definitions. Contract files (`*.able.yml`) are capabilities a type may `include`. When a **type** includes the **sidecar.able contract**, its concrete instances are YAML files under `data/entities/<type>/`. Init walks types, then instances, then writes `data/asc/cache/entities/<type>/<id>.sh`. Load only sources the cache (the stub already does this; the cache path in the stub is wrong — see below).

**Tech Stack:** Bash 4+, existing `f_yaml_parse` / bash-yaml, shunit2 (`make test-core`), hook `post` / `init`, eager include `asc/extensions/entity/entity.inc.sh`.

## Vocabulary (do not mix)

| Kind | Filename | What it is | Example |
|------|----------|------------|---------|
| **Type** (definition) | `$type.entity.yml` | Abstract spec shared by all instances of that type | `asc/host/host.entity.yml` → type `host` |
| **Contract** (ability) | `$name.able.yml` | Capability a type or another contract may include | `asc/sidecar/sidecar.able.yml` |
| **Concrete instance** | (storage-dependent) | One named object of a type | `data/entities/host/foobar.home.arpa.yml` |
| **Load cache** | generated `.sh` | Field exports for a shell | `data/asc/cache/entities/host/foobar.home.arpa.sh` |

`sidecar.able` is **only** a contract. README: a type that includes it may store each instance as a local YAML file. It is not an entity type. Do not give `sidecar.able.yml` `required.field` as if it were `host.entity.yml`. Do not name functions or cache dirs after `sidecar.able`.

There is a separate empty stub `asc/sidecar/sidecar.entity.yml` (entity type named `sidecar` if we ever need one). Leave it alone.

`host` and `remote_host` are sidecar.able **types** only because their entity files **include** that contract — not because they “are sidecars”.

## What already exists (do not recreate)

`asc/extensions/entity/entity.inc.sh` (eager `$ext/$ext.inc.sh`, already started):

| Function | State | This plan |
|----------|--------|-----------|
| `f_entity_load <type> <id>` | Sources a `.sh` cache; **path is `asc/cache/entities/…` (wrong)** | Fix path to `data/asc/cache/entities/<type>/<id>.sh`. Keep the two-arg signature. |
| `f_entity_instanciate` | Empty TODO | Persist a concrete instance (YAML under `data/entities` for sidecar.able types). Not required for the first load of already-hand-authored files; implement after cache generate, or leave TODO if unused by init. |
| `f_entity_spec_get_keys` | Copy of remote `f_remote_definition_get_keys` | Adapt: keyed by **type**, prefix from type name, not hardcoded `REMOTE_INSTANCE_*`. |
| `f_entity_spec_get_key` | Copy: still calls `f_entity_load` with **one** arg and reads `REMOTE_INSTANCE_*` | Adapt: `f_entity_load "$p_type" "$p_id"` and `${PREFIX}_$KEY`. |
| `f_entity_cache_purge <type>` | Lists `asc/cache/entities/$type` then `rm asc/cache/entities/$file` (**missing `$type/` in rm**) | Fix to `data/asc/cache/entities/<type>/`. |

**Missing (the actual work):**

| Function | Job |
|----------|-----|
| `f_entity_types_discover` | Find all `*.entity.yml` in active dirs (enabled extensions only). Cache the type list. |
| `f_entity_instances_discover` | For each discovered type, find concrete instances. For types that include **sidecar.able**, that is `data/entities/<type>/*.yml`. |
| `f_entity_cache_generate` | Write `data/asc/cache/entities/<type>/<id>.sh` from a discovered instance so `f_entity_load` can source it. |

Init (`post` / `init` hook on the entity extension): discover types → discover instances → generate cache.

Then: `f_remote_instance_load` → `f_entity_load remote_instance "$id"`, and the remote catalog compiler writes into the **same** cache dir (still authored as `remote_instances.yml` this slice).

## Global Constraints

- Run from `$PROJECT_DOCROOT`. `f_*`, `*_arr` / `*_dict`, `p_` / `o_` / `b_`.
- Cache root is **`data/asc/cache/entities/`** (README Instantiation). Never `asc/cache/` (that would be inside the source tree).
- Load cache files `export` mutables, not `global()` readonly, not `.env`. Prefix = type name, sanitized, uppercased: `host` → `HOST_`, `remote_instance` → `REMOTE_INSTANCE_`.
- Do not export `HOST_TYPE` or `INSTANCE_TYPE` from an entity load.
- Reserved YAML root keys are not instance fields: `synonym`, `include`, `includes`, `required`, `optional`, `append`, `alter`, `override`, `map`.
- `include:` (singular) on a **type** file names other type or **contract** files (`host.entity`, `sidecar.able`). Runtime merger of override/alter/append is out of scope; this slice only needs to **read** `include:` enough to know whether a type includes `sidecar.able` (direct or via another entity type).
- `includes:` (plural) reusable blocks stay as in README; remote catalog already implements that. Do not reimplement it inside entity discovery.
- `map` on a type (README): for `host` / `remote_host`, the instance **filename stem** is the `hostname` field. Apply when generating cache if `hostname` is empty.
- `entity` extension is already enabled. After `entity.inc.sh` is on disk, `make reinit` so `ASC_INC` lists it.
- Do not commit unless the user asked. Do not create a branch unless asked.

---

## File map

| Path | Role |
|------|------|
| Modify: `asc/extensions/entity/entity.inc.sh` | Fix load/purge paths; add discover types, discover instances, generate cache; adapt spec getters. |
| Create: `asc/extensions/entity/instance/post_init.hook.sh` | `hook -p post -a init`: types → instances → cache. |
| Create: `asc/extensions/entity/test/core.hook.sh` | `make test-core` batch. |
| Create: `asc/extensions/entity/test/core/entity_discover.test.sh` | Types + instances + cache + load. |
| Modify: `asc/host/host.entity.yml` | Type file: `include: [sidecar.able]` only (contract include, not a rewrite of sidecar.able). Optional `map.hostname: filename` + `hostname` field as in README. |
| Modify: `asc/extensions/remote/host/remote_host.entity.yml` | Type file: `include: [host.entity]` so it inherits sidecar.able. |
| Modify: `asc/extensions/remote/remote.inc.sh` | Compiler output dir → entity cache; `f_remote_instance_load` wraps `f_entity_load`. |
| Modify: `asc/extensions/remote/instance/ensure_dirs_exist.hook.sh`, `remote/instance_remove.sh` | Paths follow the cache dir. |
| Leave: `asc/sidecar/sidecar.able.yml` | Contract stub. Do not turn it into an entity definition. |
| Leave: `asc/sidecar/sidecar.entity.yml` | Unrelated type stub. |
| Leave: `data/entities/host/foobar.home.arpa.yml` | Concrete `host` instance (`include: [host.entity]`). |
| Leave: `f_remote_instances_setup` parse + `includes:` merge + required `host` + SSH defaults. Change output path and load wrapper only. |

Cache / instance layout:

```text
data/asc/cache/entities/types.sh                 # entity_types_arr+=(…)
data/asc/cache/entities/instances.sh             # optional index (type + id)
data/asc/cache/entities/<type>/<id>.sh           # export HOST_HOSTNAME='…'
data/entities/<type>/<id>.yml                    # concrete instance if type includes sidecar.able
```

---

### Task 1: Fix `f_entity_load` / `f_entity_cache_purge` paths + failing tests

**Files:**
- Create: `asc/extensions/entity/test/core.hook.sh`
- Create: `asc/extensions/entity/test/core/entity_discover.test.sh`
- Modify: `asc/extensions/entity/entity.inc.sh` (paths only in this task)

**Interfaces:**
- Consumes: stub `f_entity_load`, `f_entity_cache_purge`
- Produces: load/purge against `data/asc/cache/entities/<type>/<id>.sh`

- [ ] **Step 1: Test-core hook**

```sh
#!/usr/bin/env bash
##
# Implements hook -s 'test' -a 'core' -v 'HOST_TYPE PROVISION_USING'.
#
f_test_batch_exec 'asc/extensions/entity/test/core' || exit $?
```

- [ ] **Step 2: Failing tests (cache path + load)**

```sh
#!/usr/bin/env bash
##
# Entity type / instance discovery and load-cache tests.
#
# @requires asc/vendor/shunit2
#
. asc/bootstrap.sh

oneTimeSetUp() {
  mkdir -p data/asc/cache/entities/_probe
  cat > data/asc/cache/entities/_probe/alpha.sh <<'EOF'
export _PROBE_ID='alpha'
export _PROBE_OS='debian'
EOF
}

oneTimeTearDown() {
  rm -f data/asc/cache/entities/_probe/alpha.sh
  rmdir data/asc/cache/entities/_probe 2>/dev/null || true
}

test_entity_load_is_defined() {
  assertEquals 'function' "$(type -t f_entity_load)"
}

test_entity_load_requires_type_and_id() {
  f_entity_load >/dev/null 2>&1
  assertNotEquals 'must fail without args' '0' "$?"
  f_entity_load _probe >/dev/null 2>&1
  assertNotEquals 'must fail without id' '0' "$?"
}

test_entity_load_missing_cache_fails() {
  f_entity_load _probe 'missing' >/dev/null 2>&1
  assertNotEquals 'missing cache must fail' '0' "$?"
}

test_entity_load_sources_data_asc_cache() {
  f_entity_load _probe 'alpha' || fail 'load failed'
  assertEquals 'alpha' "$_PROBE_ID"
  assertEquals 'debian' "$_PROBE_OS"
}

test_entity_cache_purge_removes_type_dir_files() {
  mkdir -p data/asc/cache/entities/_probe
  echo 'export _PROBE_ID=x' > data/asc/cache/entities/_probe/z.sh
  f_entity_cache_purge _probe || fail 'purge failed'
  assertFalse 'cache file still there' "[ -f data/asc/cache/entities/_probe/z.sh ]"
}

. asc/vendor/shunit2/shunit2
```

- [ ] **Step 3: Run — expect FAIL** on `test_entity_load_sources_data_asc_cache` (stub looks at `asc/cache/entities/`).

Run: `make reinit && make test-core`

- [ ] **Step 4: Fix paths in `entity.inc.sh`**

`f_entity_load`:

```sh
local cache="data/asc/cache/entities/${p_entity_type}/${p_entity_id}.sh"
```

`f_entity_cache_purge`:

```sh
local cache_dir="data/asc/cache/entities/${p_entity_type}"
f_fs_file_list "$cache_dir"
for file in $file_list; do
  rm "${cache_dir}/${file}" || return 1
done
```

If `p_entity_type` is empty, fail (same pattern as load). If the dir is missing, return 0 (nothing to purge).

- [ ] **Step 5: Run — expect PASS** for Task 1 tests. `make test-core`

- [ ] **Step 6: Commit** (only if the user asked)

```bash
git add asc/extensions/entity/entity.inc.sh \
  asc/extensions/entity/test/core.hook.sh \
  asc/extensions/entity/test/core/entity_discover.test.sh
git commit -m "$(cat <<'EOF'
fix: point f_entity_load at data/asc/cache/entities

EOF
)"
```

---

### Task 2: Discover entity types

**Files:**
- Modify: `asc/extensions/entity/entity.inc.sh`
- Modify: `asc/extensions/entity/test/core/entity_discover.test.sh`
- Modify: `asc/host/host.entity.yml` (minimal type: include the sidecar.able **contract**)

**Interfaces:**
- Consumes: `ASC_EXTENSIONS`, active-dir layout, `f_yaml_parse` (optional this task)
- Produces: `f_entity_types_discover` → `data/asc/cache/entities/types.sh` and calling-scope `entity_types_arr`

Type id = filename stem: `host.entity.yml` → `host`. Duplicate stems: last in genericity order wins (same list as README Specificity).

Walk (enabled extensions only; skip names in the active `.asc_extensions_ignore`):

```text
asc/*.entity.yml
asc/<subject>/*.entity.yml
asc/extensions/<ext>/*.entity.yml
asc/extensions/<ext>/<subject>/*.entity.yml
scripts/asc/contrib/asc/<ext>/**/*.entity.yml
scripts/asc/contrib/<vendor>/<ext>/**/*.entity.yml
scripts/asc/extend/*.entity.yml
scripts/asc/extend/<subject>/*.entity.yml
scripts/asc/override/…   # if a type file is overridden, that path wins — reuse f_autoload_override if cheap; else skip override this slice and document
```

Do not treat `*.able.yml` as types.

- [ ] **Step 1: Failing test**

```sh
test_entity_types_discover_includes_host() {
  entity_types_arr=()
  f_entity_types_discover || fail 'discover types failed'
  . data/asc/cache/entities/types.sh
  local found=1
  local t
  for t in "${entity_types_arr[@]}"; do
    case "$t" in host) found=0 ;; esac
  done
  assertEquals 'type host (host.entity.yml) not discovered' '0' "$found"
}

test_entity_types_discover_skips_able_files() {
  entity_types_arr=()
  f_entity_types_discover || fail 'discover types failed'
  . data/asc/cache/entities/types.sh
  local t
  for t in "${entity_types_arr[@]}"; do
    assertNotEquals 'sidecar.able is a contract, not a type' 'sidecar' "$t"
  done
}
```

The second test: stem of `sidecar.able.yml` is not collected because we only glob `*.entity.yml`. `sidecar.entity.yml` **would** yield type `sidecar` if we glob all entity files — that file exists and is empty. Either skip `asc/sidecar/sidecar.entity.yml` in the assertion (type `sidecar` is valid as a type stub) **or** assert we never push stems taken from `*.able.yml`. Rewrite the test to:

```sh
test_entity_types_discover_does_not_index_able_files() {
  f_entity_types_discover || fail 'discover types failed'
  assertFalse 'must not cache sidecar.able as a type file' \
    "grep -q 'sidecar.able' data/asc/cache/entities/types.sh 2>/dev/null"
}
```

- [ ] **Step 2: Run — expect FAIL** (`f_entity_types_discover` missing).

- [ ] **Step 3: Implement `f_entity_types_discover`**

```sh
f_entity_types_discover() {
  entity_types_arr=()
  local types_dict
  unset types_dict
  declare -A types_dict
  local file stem

  # Collect paths in genericity order; later assignment wins.
  # Implementation: for each root in the list above, f_fs_file_list … '*.entity.yml'
  # Skip extension dirs not in $ASC_EXTENSIONS.

  mkdir -p data/asc/cache/entities
  {
    echo '#!/usr/bin/env bash'
    echo
    echo 'entity_types_arr=()'
    for stem in "${entity_types_arr[@]}"; do
      printf "entity_types_arr+=('%s')\n" "$stem"
    done
  } > data/asc/cache/entities/types.sh
}
```

Use `f_array_add_once` or the dict so the calling-scope array has unique stems in final-win order.

- [ ] **Step 4: Minimal `asc/host/host.entity.yml`** — this is a **type** including a **contract**:

```yml
include:
  - sidecar.able
map:
  hostname: filename
required:
  field:
    hostname:
      is: string
      size: 1 - 999
      default: localhost
      validate: test-hostname(p1)
```

Do **not** copy this shape into `sidecar.able.yml`.

- [ ] **Step 5: `make test-core` — expect PASS** for type-discovery tests.

- [ ] **Step 6: Commit** (only if the user asked)

```bash
git add asc/extensions/entity/entity.inc.sh \
  asc/extensions/entity/test/core/entity_discover.test.sh \
  asc/host/host.entity.yml
git commit -m "$(cat <<'EOF'
feat: discover entity types from *.entity.yml during init

EOF
)"
```

---

### Task 3: Discover concrete instances

**Files:**
- Modify: `asc/extensions/entity/entity.inc.sh`
- Modify: `asc/extensions/entity/test/core/entity_discover.test.sh`
- Modify: `asc/extensions/remote/host/remote_host.entity.yml`

**Interfaces:**
- Consumes: `entity_types_arr` (or re-runs type discover), type YAML `include:` lists
- Produces: `f_entity_instances_discover` → calling-scope `entity_instances_arr` of `type/id` (or two arrays `entity_instance_types_arr` + `entity_instance_ids_arr` — pick one and use it in later tasks). Prefer `entity_instance_ids_arr` plus parallel `entity_instance_types_arr` (same length) to avoid splitting on `/` in ids like `foobar.home.arpa`.

A type **includes sidecar.able** when its `include:` list (after sanitizing stems) contains `sidecar.able`, or contains another `*.entity` whose file includes sidecar.able (walk the entity-type chain only; do not execute override/alter). `host.entity.yml` includes `sidecar.able` after Task 2. `remote_host.entity.yml`:

```yml
include:
  - host.entity
```

Instance id for sidecar.able types = YAML filename stem: `foobar.home.arpa.yml` → `foobar.home.arpa`.

If `data/entities/<type>/` is missing, that type has zero file instances (OK).

- [ ] **Step 1: Failing test**

```sh
test_entity_instances_discover_finds_host_fixture() {
  entity_types_arr=()
  entity_instance_types_arr=()
  entity_instance_ids_arr=()
  f_entity_types_discover
  f_entity_instances_discover || fail 'discover instances failed'
  local i found=1
  for i in "${!entity_instance_ids_arr[@]}"; do
    if [[ "${entity_instance_types_arr[$i]}" == 'host' \
       && "${entity_instance_ids_arr[$i]}" == 'foobar.home.arpa' ]]; then
      found=0
    fi
  done
  assertEquals 'data/entities/host/foobar.home.arpa.yml not discovered' '0' "$found"
}
```

- [ ] **Step 2: Run — expect FAIL**.

- [ ] **Step 3: Implement `f_entity_type_includes_able` + `f_entity_instances_discover`**

```sh
# Return 0 if type YAML include chain contains the contract stem (e.g. sidecar.able).
f_entity_type_includes_able() {
  local p_type="$1"
  local p_able="$2"   # e.g. sidecar.able
  # Resolve p_type to its *.entity.yml path (most-specific).
  # f_yaml_parse include list; recurse into *.entity includes; stop on cycles.
}

f_entity_instances_discover() {
  entity_instance_types_arr=()
  entity_instance_ids_arr=()
  local type file id
  if [[ ${#entity_types_arr[@]} -eq 0 ]]; then
    f_entity_types_discover
  fi
  for type in "${entity_types_arr[@]}"; do
    if ! f_entity_type_includes_able "$type" 'sidecar.able'; then
      continue
    fi
    [[ -d "data/entities/${type}" ]] || continue
    f_fs_file_list "data/entities/${type}" '*.yml'
    for file in $file_list; do
      id="${file%.yml}"
      entity_instance_types_arr+=("$type")
      entity_instance_ids_arr+=("$id")
    done
  done
}
```

Types that do not include sidecar.able are skipped here. Their instances may come from other storage later (`f_entity_instanciate` / memory). **remote_instance** rows still live in `remote_instances.yml` this slice — they are **not** required to appear in `data/entities/remote_instance/` yet. Task 5 feeds their cache from the existing compiler.

- [ ] **Step 4: `make test-core` — expect PASS.**

- [ ] **Step 5: Commit** (only if the user asked)

```bash
git add asc/extensions/entity/entity.inc.sh \
  asc/extensions/entity/test/core/entity_discover.test.sh \
  asc/extensions/remote/host/remote_host.entity.yml
git commit -m "$(cat <<'EOF'
feat: discover sidecar.able entity instances under data/entities

EOF
)"
```

---

### Task 4: Generate load cache from discovered instances

**Files:**
- Modify: `asc/extensions/entity/entity.inc.sh`
- Modify: `asc/extensions/entity/test/core/entity_discover.test.sh`

**Interfaces:**
- Consumes: `f_yaml_parse`, instance YAML, `f_entity_type_prefix` (add if missing), `map` hostname/filename for `host` and `remote_host`
- Produces: `f_entity_cache_generate <type> <id>` writes `data/asc/cache/entities/<type>/<id>.sh`; `f_entity_cache_generate_all` walks discovered instances

Export lines (same quoting as today’s remote compiler):

```sh
export HOST_ID='foobar.home.arpa'
export HOST_HOSTNAME='foobar.home.arpa'
```

Flatten nested YAML with bash-yaml (`ssh.user` → `ssh_user` → `HOST_SSH_USER`). Skip reserved roots. Skip empty values. Trim wrapping quotes. Escape `'` in values.

`include:` on the **instance** file (`include: [host.entity]`) is reserved — do not export it, and **do not** merge the type file into the instance this slice (no schema merger). Filename map still fills `hostname` when missing.

- [ ] **Step 1: Failing test**

```sh
test_entity_cache_generate_host_fixture() {
  f_entity_cache_purge host
  f_entity_cache_generate host 'foobar.home.arpa' || fail 'generate failed'
  assertTrue 'cache missing' "[ -f data/asc/cache/entities/host/foobar.home.arpa.sh ]"
  f_entity_load host 'foobar.home.arpa' || fail 'load failed'
  assertEquals 'foobar.home.arpa' "$HOST_ID"
  assertEquals 'foobar.home.arpa' "$HOST_HOSTNAME"
}

test_entity_cache_generate_skips_include_field() {
  f_entity_cache_generate host 'foobar.home.arpa' || fail 'generate failed'
  f_entity_load host 'foobar.home.arpa'
  assertEquals 'include is reserved' '' "${HOST_INCLUDE:-}"
}
```

- [ ] **Step 2: Run — expect FAIL.**

- [ ] **Step 3: Implement generate**

```sh
f_entity_type_prefix() {
  local p_type="$1"
  local p_out="${2:-entity_type_prefix}"
  local sanitized=''
  f_str_sanitize_var_name "$p_type" 'sanitized'
  f_str_uppercase "$sanitized" "$p_out"
}

f_entity_key_is_reserved() {
  local root="${1%%_*}"
  case "$root" in
    synonym|include|includes|required|optional|append|alter|override|map) return 0 ;;
  esac
  return 1
}

f_entity_cache_generate() {
  local p_type="$1"
  local p_id="$2"
  local sidecar="data/entities/${p_type}/${p_id}.yml"
  local cache="data/asc/cache/entities/${p_type}/${p_id}.sh"
  # parse sidecar, write exports, apply hostname←filename for host|remote_host
}

f_entity_cache_generate_all() {
  local i
  f_entity_instances_discover
  for i in "${!entity_instance_ids_arr[@]}"; do
    f_entity_cache_generate \
      "${entity_instance_types_arr[$i]}" \
      "${entity_instance_ids_arr[$i]}" || return 1
  done
}
```

- [ ] **Step 4: `make test-core` — expect PASS.**

- [ ] **Step 5: Commit** (only if the user asked)

```bash
git add asc/extensions/entity/entity.inc.sh \
  asc/extensions/entity/test/core/entity_discover.test.sh
git commit -m "$(cat <<'EOF'
feat: generate entity instance load cache from data/entities YAML

EOF
)"
```

---

### Task 5: Run discovery + cache generate on instance init

**Files:**
- Create: `asc/extensions/entity/instance/post_init.hook.sh`

**Interfaces:**
- Consumes: `f_entity_types_discover`, `f_entity_instances_discover`, `f_entity_cache_generate_all`
- Produces: cache files after every `make init` / `reinit`

- [ ] **Step 1: Hook**

```sh
#!/usr/bin/env bash
##
# Implements hook -p 'post' -a 'init'.
#

echo "Discovering entity types and instances ..."
f_entity_types_discover
f_entity_instances_discover
f_entity_cache_generate_all
echo "Discovering entity types and instances : done."
echo
```

Purge-before-write: `f_entity_cache_generate_all` should purge per type it will rewrite, or types_discover starts by ensuring `data/asc/cache/entities/` exists. Do not delete unrelated type dirs if a later compiler (remote) also writes there in the same init — **order:** entity hook generates sidecar.able file instances; remote `post_init` then writes `remote_instance` cache from the catalog. Entity generate_all must not `rm -rf data/asc/cache/entities` wholesale.

Safer: `f_entity_cache_generate` overwrites one file; `f_entity_cache_purge "$type"` only for types whose instances come from `data/entities` (sidecar.able), before regenerating that type.

- [ ] **Step 2: `make reinit` then assert cache exists**

```sh
test -f data/asc/cache/entities/types.sh
test -f data/asc/cache/entities/host/foobar.home.arpa.sh
(. asc/bootstrap.sh && f_entity_load host foobar.home.arpa && echo "$HOST_HOSTNAME")
# expected: foobar.home.arpa
```

- [ ] **Step 3: `make test-core` still PASS.**

- [ ] **Step 4: Commit** (only if the user asked)

```bash
git add asc/extensions/entity/instance/post_init.hook.sh \
  asc/extensions/entity/entity.inc.sh
git commit -m "$(cat <<'EOF'
feat: discover and cache entity instances on instance init

EOF
)"
```

---

### Task 6: Adapt spec getters (unstick the remote copy)

**Files:**
- Modify: `asc/extensions/entity/entity.inc.sh` (`f_entity_spec_get_keys`, `f_entity_spec_get_key`)

**Interfaces:**
- Consumes: `f_entity_load <type> <id>`, `f_entity_type_prefix`
- Produces: type-aware key list / key read with token replace via `f_str_convert_tokens` on the **value**, not `f_str_convert_tokens "$p_remote_id" "$val"` (the stub passes an id as a var name — that is leftover remote code and is wrong)

- [ ] **Step 1: Change signatures**

```sh
# @param 1 String : entity type.
f_entity_spec_get_keys() {
  local p_type="$1"
  # Until schema merger exists: for sidecar.able types, keys = flattened
  # non-reserved keys from the type’s instance YAML is too late (needs an id).
  # v1: keys_arr from the **type** file’s required.field / optional.field
  # names via f_yaml_parse of the type YAML only (no include merge).
  # Plus always 'id'.
  # Hook: hook -s 'entity_spec_keys' -a 'alter' -v 'p_type'  (not REMOTE_INSTANCE_ID)
}

# @param 1 type, @param 2 id, @param 3 key, @param 4 [out var], @param 5 [skip tokens]
f_entity_spec_get_key() {
  f_entity_load "$p_type" "$p_id"
  f_entity_type_prefix "$p_type" 'pfx'
  f_str_uppercase "$p_key" 'KEY'
  var="${pfx}_$KEY"
  val="${!var}"
  # tokens: f_str_convert_tokens on a temp var holding "$val"
}
```

Hardcoded remote dump/file keys stay in `f_remote_definition_get_keys` until schema merger. Do not keep them as the body of `f_entity_spec_get_keys`.

- [ ] **Step 2: Test** `f_entity_spec_get_key host foobar.home.arpa hostname out` → `foobar.home.arpa`.

- [ ] **Step 3: `make test-core` — PASS.**

- [ ] **Step 4: Commit** (only if the user asked)

```bash
git add asc/extensions/entity/entity.inc.sh \
  asc/extensions/entity/test/core/entity_discover.test.sh
git commit -m "$(cat <<'EOF'
refactor: make entity spec key helpers type-aware

EOF
)"
```

---

### Task 7: Replace `f_remote_instance_load` body

**Files:**
- Modify: `asc/extensions/remote/remote.inc.sh`
- Modify: `asc/extensions/remote/instance/ensure_dirs_exist.hook.sh`
- Modify: `asc/extensions/remote/remote/instance_remove.sh`
- Modify: comments that still say `data/asc/remote-instances/`
- Modify: `asc/extensions/entity/test/core/entity_discover.test.sh`

**Interfaces:**
- Consumes: `f_entity_load` (entity extension is enabled by default even when `remote` is ignored)
- Produces: same `REMOTE_INSTANCE_*` exports; compiler writes `data/asc/cache/entities/remote_instance/<id>.sh`

- [ ] **Step 1: Wrapper test** (source `remote.inc.sh` because this repo still ignores `remote`):

```sh
test_remote_instance_load_wraps_entity_load() {
  . asc/extensions/remote/remote.inc.sh
  mkdir -p data/asc/cache/entities/remote_instance
  cat > data/asc/cache/entities/remote_instance/wraptest.sh <<'EOF'
export REMOTE_INSTANCE_ID='wraptest'
export REMOTE_INSTANCE_HOST='1.2.3.4'
EOF
  f_remote_instance_load 'wraptest' || fail 'wrapper failed'
  assertEquals 'wraptest' "$REMOTE_INSTANCE_ID"
  assertEquals '1.2.3.4' "$REMOTE_INSTANCE_HOST"
  assertFalse 'must not require legacy path' \
    "[ -f data/asc/remote-instances/wraptest.sh ]"
  rm -f data/asc/cache/entities/remote_instance/wraptest.sh
}
```

- [ ] **Step 2: Replace load**

```sh
f_remote_instance_load() {
  local p_id="$1"
  local cache_dir='data/asc/cache/entities/remote_instance'
  if [[ -z "$p_id" ]]; then
    local file=''
    f_fs_file_list "$cache_dir" '*.sh'
    for file in $file_list; do
      case "$file" in types.sh|instances.sh|_parsed.sh) continue ;; esac
      p_id="${file%.sh}"
      break
    done
  fi
  f_entity_load remote_instance "$p_id"
}
```

- [ ] **Step 3: Compiler output dir** in `f_remote_instances_setup`: write each id to `data/asc/cache/entities/remote_instance/<id>.sh`. Intermediate parse dump: `data/asc/cache/entities/remote_instance/_parsed.sh`. `f_remote_purge_instances` → `f_entity_cache_purge remote_instance` (then also remove `_parsed.sh` if purge only deletes `*.sh` in that dir — it will). `f_remote_get_instances` lists that dir, skips `_parsed.sh`.

Do **not** invent `data/entities/remote_instance/*.yml` this slice. Catalog YAML remains how remote rows are authored.

- [ ] **Step 4: `make test-core` — PASS.** On a project with `remote` enabled and `remote_instances.yml`, `make reinit` then `f_remote_instance_load <id>` still sets `REMOTE_INSTANCE_HOST`.

- [ ] **Step 5: Commit** (only if the user asked)

```bash
git add asc/extensions/remote/remote.inc.sh \
  asc/extensions/remote/instance/ensure_dirs_exist.hook.sh \
  asc/extensions/remote/remote/instance_remove.sh \
  asc/extensions/entity/test/core/entity_discover.test.sh
git commit -m "$(cat <<'EOF'
refactor: load remote instances through f_entity_load

EOF
)"
```

---

### Task 8: README Instantiation — point at the functions

**Files:**
- Modify: `README.md` Instantiation bullets only (do not rewrite Contracts)

- [ ] **Step 1: Name the functions next to the four discovery bullets**

After the existing numbered list, add that init calls `f_entity_types_discover`, `f_entity_instances_discover`, `f_entity_cache_generate_all`, and that `f_entity_load <type> <id>` sources `data/asc/cache/entities/<type>/<id>.sh`.

Replace `TODO replace f_remote_instance_load` with: it is a wrapper: `f_entity_load remote_instance <id>`.

Add the host fixture example (`HOST_HOSTNAME` from filename map). Leave Linking as TODO.

Keep the wording **sidecar.able** as a contract that types include — never as a type name.

- [ ] **Step 2: TOC only if headings changed** — `asc/doc/md_toc.sh README.md` if needed.

- [ ] **Step 3: Commit** (only if the user asked)

```bash
git add README.md
git commit -m "$(cat <<'EOF'
docs: name entity discover/cache/load functions in Instantiation

EOF
)"
```

---

## Verification

```sh
make reinit
make test-core
(. asc/bootstrap.sh && f_entity_load host foobar.home.arpa && printf '%s\n' "$HOST_HOSTNAME")
```

Expected: `foobar.home.arpa`; `data/asc/cache/entities/host/foobar.home.arpa.sh` exists; `ASC_INC` contains `asc/extensions/entity/entity.inc.sh`; `sidecar.able.yml` still a contract stub; no `sidecar.able` stem in `types.sh`.

## Non-goals

- Rewriting `sidecar.able.yml` into an entity definition.
- Executing `include` / `override` / `alter` / `append` beyond “does this type include sidecar.able?”.
- Driving `f_remote_definition_get_keys` from merged schema.
- Authoring remotes as `data/entities/remote_instance/*.yml`.
- `f_entity_instanciate` DB backends.
- Filling `provision.able` / `ssh.able` / `nest.able` bodies.

## Follow-ups

1. Schema merger so type `include:` copies contract fields into the type spec.
2. Optional: catalog row → YAML instance under `data/entities/remote_instance/`.
3. `f_entity_instanciate` write path.
4. Linking `remote_instance` → `remote_host`.
