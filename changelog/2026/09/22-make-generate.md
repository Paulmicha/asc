# `make generate` — render builder templates

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | Fill the existing builder entry point so it renders ASC code from a string template, a file template, or a directory template. First code slice: [22-make-generate-string.md](./22-make-generate-string.md). |
| **Out of this plan** | The kernel move in [20-builder-kernel-subject.md](./20-builder-kernel-subject.md). A YAML loader for `literal.able` / `template.able`. `<asc-if>`. Writing a second substituter in `template/hydrate.sh`. Scaffolding a new project instance (`make setup` / `make init`). |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

Go-ahead is the `make generate` row in [`gates.yml`](../../../gates.yml). `go` stays `no` until that row is approved. Approving it authorizes the string-print slice only.

---

## What already exists

`make generate` is already a pivot. `data/asc/pivots.mk` sends it to `asc/extensions/builder/instance/generate.sh`. That file is empty. The `instance-` prefix is stripped, so `instance/generate` is `generate`, not `builder-instance-generate`.

Sibling pivots, also stubs: `make template-hydrate`, `template-list`, `template-diff`, `template-represent`. `asc/make/generate.sh` is a different command, `make make-generate` (pivot list). Leave it.

`~/asc/extensions/builder/instance/generate.sh` is the same empty file. This plan changes the mother. The home instance picks it up when `asc/` is copied from the mother.

[20-builder-kernel-subject.md](./20-builder-kernel-subject.md) leaves this script empty until a hydrate tool exists, and it sketches the pivots as `builder-template-hydrate` after a `git mv` to `asc/builder/`. Those names are the post-move names. Today the pivot is `template-hydrate`. This plan does not move the tree and does not rename the pivot.

README lists `tpl` beside `hook` as a function with no `f_` prefix. No `tpl` function is defined in `asc/core/`. This entry point does not call `tpl`.

---

## Contract

One script, three modes. Substitution stays in `instance/generate.sh` until a second caller exists. `template/hydrate.sh` stays the TODO stub so there is not a second engine.

| Mode | Call | Result |
|------|------|--------|
| String | `asc/extensions/builder/instance/generate.sh str '<template>' <name> <value> …` | Substituted text on stdout. No file write. |
| File | same script, `file <src> <dest> <name> <value> …` | One body rendered. `dest` omitted → stdout. |
| Directory | same script, `dir <src> <dest> <name> <value> …` | Walk `src`. Substitute each relative path and each file body. Write under `dest`. |

Token assignments are `name` then `value` as two arguments. `name=value` is not the spelling: GNU make treats `=` as a goal assignment.

`dest` for `dir` must be absent or empty. A non-empty dest fails and writes nothing. The script does not run `make setup` or `make init`.

Unknown tokens fail the run. Leftover `{{ … }}`, `[token]`, or `{token}` in the output is a failure, not a partial render. `<asc-if>` is not a token. A template that contains it fails in the string slice; a later child owns it.

---

## Tokens on disk

The able sketches in the kernel-subject plan are not the inventory. The templates under `asc/extensions/builder/template/core/` are.

Filename tokens: `[subject]`, `[object]`, `[action]`, `[hook]`, `[able]`, `[entity]`, `[test_group]`, `[test_suite]`, `[test_case]`, `{subject}`, `{file_ext}`, `{variants}`.

Body tokens include `{{ slot }}`, `{{ docblock }}`, `{{ examples }}`, `{{ COMPONENT }}`, `{{ TEMPLATE }}`, `{{ SERVICE }}`, `{{ CMD }}`, `{{ path }}`, `{{ hook_variants }}`, `{{ test_group }}`, `{{ test_suite }}`, `{{ one_time_setup }}`, `{{ ACTION_TEST_PATH }}`. Names inside `{{ }}` may contain spaces; trim them.

`<asc-if not-empty="one_time_setup">` appears in two test templates. It stays out of the string slice.

Two bracket styles are already in filenames (`[subject]` and `{subject}`). The dir mode accepts both. It does not add a third spelling.

---

## Children

| Plan | Ships | Blocked by |
|------|--------|------------|
| [22-make-generate-string.md](./22-make-generate-string.md) | `str` mode, stdout, `{{ name }}` only | This gate |
| File mode | One file body, stdout or `dest` | String-slice tests |
| Directory mode | Path tokens + body tokens, write under an empty `dest` | File mode, and a fixture copied from `template/core/` |
| `<asc-if>` | The `not-empty` block in the test templates | Directory mode |

---

## Gaps

1. **`make generate` is the instance scaffold in the September 20 plan, and the renderer in this one.** Same empty file. This plan makes it the renderer. A later instance-scaffold caller can invoke it. It does not grow a second script to keep the old split.
2. **`template-hydrate` is the other empty door.** Filling both would fork the substituter. Hydrate stays a stub until something other than `generate` calls the same function.
3. **Post-move pivot names differ.** After `asc/builder/`, heuristic A would call the same file `builder-instance-generate` unless the `instance-` strip still applies. The move plan owns that. Do not add an `ASC_SYNONYMS` row for `generate`.
4. **The able sketch token list is short of the tree.** `{{ SERVICE }}`, `{{ CMD }}`, `{{ hook_variants }}`, and the filename/body split are in the files and not in that sketch. Implement from the tree.
5. **`tpl()` is named in the README and absent in core.**
6. **Make will not carry `=` or an unquoted template.** Tests call the script. `make generate str …` is the human shortcut only for values that survive GNU make.
7. **`<asc-if>` has no rule yet.** The kernel-subject plan already left it open. A dir render of the stock test templates fails closed until that child exists.
8. **No eager include, no able loader, no new global.**

---

## Tasks

- [ ] Confirm `make generate` renders templates, and `template/hydrate.sh` stays a stub.
- [ ] Confirm the string slice is print-only, as in the child plan.
- [ ] Leave directory mode and `<asc-if>` unwritten until the string slice has a passing test.
