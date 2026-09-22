# `make generate` string print

| Field | Value |
|-------|--------|
| **Date** | 2026-09-22 |
| **Status** | **plan / review** (not an implementation go-ahead) |
| **Scope** | First slice of [22-make-generate.md](./22-make-generate.md): substitute `{{ name }}` in one string and print it. |
| **Out of this slice** | File mode, directory mode, filename tokens, `<asc-if>`, `template/hydrate.sh`, the builder `git mv`. |

`$` in this file is the ASC docs placeholder (`$subject` / `$action`), not a shell variable.

Starts only when the `make generate` row in [`gates.yml`](../../../gates.yml) has `go: "yes"`.

---

## Behavior

`asc/extensions/builder/instance/generate.sh` takes `str`, then the template, then zero or more `name` / `value` pairs.

| Input | Print |
|-------|--------|
| `str 'echo {{ slot }}' slot hello` | `echo hello` |
| `str '{{ COMPONENT }}' COMPONENT app` | `app` (trim the name inside the braces) |
| `str 'keep'` | `keep` |
| `str '{{ slot }}'` | non-zero, no stdout (unknown token) |
| `str 'hello [subject]' subject core` | non-zero (`[subject]` is a filename token; this slice only replaces `{{ }}`) |
| `file` or `dir` as the first argument | non-zero (later children) |

A value may be empty only when the caller passes the name and an empty argument. A missing name is the unknown-token failure.

Quotes in the printed text are the template’s quotes, unchanged. The script does not shell-parse the template and does not `eval` it.

---

## Files

| File | Change |
|------|--------|
| `asc/extensions/builder/instance/generate.sh` | The `str` mode. Parser stays in this file. |
| `asc/extensions/builder/test/core/template.test.sh` | Replace the empty `test_generate_from_temlate` body with the table above. Keep the existing filename (typo and all) so the test hook still finds it. |

Tests invoke the script. They do not need `make reinit`. `template/hydrate.sh` stays the nine-line TODO.

---

## Tasks

- [ ] After the generate gate is go: fill `str` mode in `instance/generate.sh`.
- [ ] Make `test_generate_from_temlate` assert the table above and run that test file.
