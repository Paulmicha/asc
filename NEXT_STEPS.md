# NEXT_STEPS

Discussion for the queue in [`NEXT_STEPS.agent.md`](NEXT_STEPS.agent.md). This file is the other project-docroot hook path (rung 4, same model as `env.yml`). Dry-run returns it; it is not sourced.

```sh
hook_ms 'dry-run' -s 'doc' -a 'NEXT_STEPS' -c 'md' -r
```

`asc/doc/next_steps.sh` rewrites the agent file only. Edits here stay until a human changes them.

Go-ahead for a task in the agent file is the matching row in [`gates.yml`](gates.yml) (`approved` and `go`). This file is the discussion. An agent starts a task only when that row's `go` is yes.

## Sequential

Wave C `git` is done (`asc/git/git.opt-inc.sh`, off `ASC_INC`). Eager case-table *planned* → **on disk** is done (mysql/pgsql skipped). Optional wrap-vs-bootstrap measure stays unapproved.

- [x] **Done** [19-lazy-opt-inc-remaining-core-waves.md](changelog/2026/09/19-lazy-opt-inc-remaining-core-waves.md) — `git` off `ASC_INC`.
- [x] **Done** [19-eager-vs-lazy-include-cases.md](changelog/2026/09/19-eager-vs-lazy-include-cases.md) — leftover planned rows marked on disk / skipped.
- [x] **Done** [22-deprecate-subject-asc-extensions.md](changelog/2026/09/22-deprecate-subject-asc-extensions.md) — positive-list deprecated; July 24 plan rejected; no loader.
- [ ] **Leave unapproved** [11-lazy-opt-inc-and-entry-point-extraction.md](changelog/2026/09/11-lazy-opt-inc-and-entry-point-extraction.md) — optional wrap-vs-bootstrap measure. Not this hour.

## Parallel

- [x] **Done** shunit2 output-var cases for migrated scalars ([31-subshell-printf-v-candidates.md](changelog/2026/07/31-subshell-printf-v-candidates.md)).
- [x] **Done** waves 4–8 (`f_software_*_status`, `f_fs_get_most_recent`, host/shell, git get_*, test case helpers).
- [x] **Done** design for `eval` / `f_yaml_parse` replacement (Category C in the same changelog). Keep `eval` until a later implementation gates row.
- [ ] **Leave unapproved** Category G bootstrap `global … "$(f_*)"` literals.

## Awaiting approval before any code

- [x] **Accepted for discussion** [24-yml-structure.md](changelog/2026/07/24-yml-structure.md) — plan SoT; still not an implementation go-ahead for loaders/schema merge.
- [x] **Rejected** [24-subject-asc-extensions.md](changelog/2026/07/24-subject-asc-extensions.md) — superseded by the 2026-09-22 deprecation.
- [31-nameref-clarity-candidates.md](changelog/2026/07/31-nameref-clarity-candidates.md) — inventory. Docs only. Still unapproved.
- [10-begin-entity-system-with-remote-instances.md](changelog/2026/09/10-begin-entity-system-with-remote-instances.md) — task 8 README proposal written; awaits human accept.
- [20-builder-kernel-subject.md](changelog/2026/09/20-builder-kernel-subject.md) — later, no code. `instance/generate.sh` detailed 2026-09-22.
- [20-host-scan-project-instances.md](changelog/2026/09/20-host-scan-project-instances.md) — later, no code. `asc/instance/discover.sh` detailed 2026-09-22.
- [22-xdg-state-store.md](changelog/2026/09/22-xdg-state-store.md) — plan / review. Host registry path `$HOME/.local/state/asc/registry`. No memory code.

[20-meadows-plan-review-feedback-loop.md](changelog/2026/09/20-meadows-plan-review-feedback-loop.md) is skipped. Do not re-run it.
