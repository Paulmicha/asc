# Changelog → docs/plans migration (narrow)

| Field | Value |
|-------|--------|
| **Date** | 2026-11-10 |
| **Status** | completed |
| **Documentation convention** | [docs/specs/asc/documentation.md](../../../specs/asc/documentation.md) (supersedes the related docs-tree idea) |
| **Related idea (gates / next-steps)** | [docs/ideas/2026/11/10-gates-and-next-steps.md](../../../ideas/2026/11/10-gates-and-next-steps.md) |
| **Scope** | Mother checkout. Preserve every dated `changelog/` note by moving it to `docs/plans/YYYY/MM/` with minimal edits. Maintain an old→new path map and use it to confirm each file arrived. Update affected references (consumers, links inside moved notes, retained `changelog/README.md`, README live paths, directory-level exclusions). Verify by reviewing the move list, changed paths, and resulting diff. |
| **Out of this plan** | Decision extracts. Status remapping or abandon-by-age. Running or extending automated test suites / new test scripts. Redesigning or testing the next-steps scanner workflow; leave `asc/doc/next_steps.sh`’s `changelog/` default for the [gates/next-steps idea](../../../ideas/2026/11/10-gates-and-next-steps.md) (scanner not currently relied on). Multi-instance upgrade rollout. Broader README convention prose without proposal tags. Authoring `docs/specs/*` / living docs. Changing gate `go` values. Client-instance private trees. |

> **For agentic workers:** Checkboxes track progress. This plan is not an implementation go-ahead by itself.

**Goal:** Relocate every dated note under `docs/plans/` without rewriting meaning, keep references and the legacy index usable, and prove arrival via the path map and diff review.

**Architecture:** Inventory with tools available in a plain shell (`find`, `grep`, `git`). Move with `git mv`. Retarget string and directory references as path maintenance. Do not touch next-steps classification or invent a verification harness — walk Appendix A and `git diff`.

**Tech stack:** Markdown, `git mv`, existing path strings in YAML/Markdown/shell.

## Global constraints

- Preserve **every** dated note; no deletes of those files.
- Root `README.md` remains SoT for ASC concepts.
- **README live links:** fix broken targets **in place** (authorized). Ignore `changelog/...` strings inside fenced code blocks (examples, not live links). Explanatory prose / new-convention description still uses escaped proposal blocks unless a broader rewrite is authorized later.
- Preserve existing status wording; optional dated note such as `Review (2026-11-10): status not yet reassessed.` Age alone does not make a note abandoned or superseded.
- No decision-record extraction.
- **Next-steps scanner:** do **not** change `asc/doc/next_steps.sh` in this plan. Record the stale `changelog/` default as follow-up under the gates/next-steps idea.
- Inventory commands must work **without `rg`** (it may be absent). Prefer `find` + `grep -R` and/or `git grep`.
- Verification = review Appendix A, consumer path list, and `git diff` / `git status`. No automated test suite and no new test script.
- Prefer `git mv`. Mother-guard: mother-only generic content.

## File map

| Path | Responsibility |
|------|----------------|
| `docs/plans/YYYY/MM/*.md` | Destination for every former dated `changelog/2026/**/*.md` note |
| `changelog/README.md` | Retain useful context; update its links; add old→new map / pointers |
| `changelog/2026/...` | Empty after verified moves |
| `gates.core.yml`, `SPECIMEN.gates.yml`, `NEXT_STEPS*`, `@see` comments | Path string updates |
| Directory exclusions (e.g. `asc/test/core/yml.test.sh`) | Inspect and update so historical notes are not accidentally re-included or wrongly excluded after the move |
| `asc/doc/next_steps.sh` | **Unchanged here** — deferred to gates/next-steps idea |
| `README.md` | Fix live link targets; convention prose via proposals only |
| Appendix A | Old→new map used for move confirmation |

---

### Task 1: Inventory and old→new map

**Files:**
- Modify: this plan’s Appendix A

- [x] **Step 1: List every dated source (no `rg` required)**

```bash
cd "$HOME/Documents/asc"
find changelog/2026 -name '*.md' -type f | sort | tee /tmp/asc-changelog-sources.txt
wc -l /tmp/asc-changelog-sources.txt
```

Expected: 72 dated files (confirm).

- [x] **Step 2: Fill Appendix A**

One row per dated source: `old_path` → `docs/plans/YYYY/MM/<same-basename>.md`. Also note `changelog/README.md` as retain-in-place. This map is the checklist for Task 2 arrival and Task 6 review.

- [x] **Step 3: Consumer inventory without `rg`**

```bash
cd "$HOME/Documents/asc"
# tracked files
git grep -n 'changelog/2026/' -- \
  ':!changelog/2026/**' ':!asc/vendor/**' ':!data/**' \
  > /tmp/asc-changelog-consumers.txt || true
# also catch directory-level changelog/ references (exclusions, defaults)
git grep -n 'changelog/' -- \
  ':!changelog/**' ':!asc/vendor/**' ':!data/**' \
  ':!docs/plans/2026/11/10-changelog-refactor.md' \
  ':!docs/ideas/**' \
  >> /tmp/asc-changelog-consumers.txt || true
# untracked text under the tree (if any) — find + grep, still no rg
find . \( -path './.git' -o -path './asc/vendor' -o -path './data' -o -path './changelog/2026' \) -prune \
  -o -type f \( -name '*.md' -o -name '*.yml' -o -name '*.yaml' -o -name '*.sh' -o -name '*.mk' -o -name 'Makefile' \) \
  -print 2>/dev/null \
| while IFS= read -r f; do
    git check-ignore -q "$f" 2>/dev/null && continue
    git ls-files --error-unmatch "$f" >/dev/null 2>&1 && continue
    grep -n 'changelog/' "$f" 2>/dev/null | sed "s|^|$f:|"
  done >> /tmp/asc-changelog-consumers.txt || true
sort -u /tmp/asc-changelog-consumers.txt -o /tmp/asc-changelog-consumers.txt
wc -l /tmp/asc-changelog-consumers.txt
```

Review the **full** list. Tag each hit: rewrite path, update directory exclusion, leave intentional, README live-link, or defer (next-steps scanner → idea).

Explicitly include inspection of `asc/test/core/yml.test.sh` (`!**/changelog/**` exclusion around the `f_yaml_parse` caller search). After notes live under `docs/plans/`, that exclusion no longer covers them; decide the maintenance edit (e.g. also exclude `docs/plans/**`, or equivalent) so the existing test’s search scope stays intentional. **Do not run** that test as part of this plan.

---

### Task 2: Move every dated note; confirm via the path map

**Files:**
- `git mv` every Appendix A dated row

- [x] **Step 1: Move from the source list**

```bash
cd "$HOME/Documents/asc"
while IFS= read -r old; do
  base=$(basename "$old")
  y=$(echo "$old" | cut -d/ -f2)
  m=$(echo "$old" | cut -d/ -f3)
  mkdir -p "docs/plans/$y/$m"
  git mv "$old" "docs/plans/$y/$m/$base"
done < /tmp/asc-changelog-sources.txt
```

Preserve every file; do not drop or merge notes.

- [x] **Step 2: Minimal edits inside moved notes**

Allowed:

- Fix **all affected links inside moved notes** that break because the file is one directory deeper under `docs/plans/` — not only peer-note links. Include relative links to the root `README.md`, code, skills, gates, other repo paths, and peers (use Appendix A for peer destinations). Example: a former `changelog/2026/11/...` link `../../../README.md` becomes `../../../../README.md`.
- Optional: `Review (2026-11-10): status not yet reassessed.`

Not allowed: status vocabulary rewrite; decision extracts; abandon/supersede by age; large prose edits.

- [x] **Step 3: Inspect arrival with the path map**

Walk Appendix A (or regenerate pairs from `/tmp/asc-changelog-sources.txt`): for each row, confirm `new_path` exists and `old_path` does not. Record any mismatch before continuing.

```bash
cd "$HOME/Documents/asc"
missing=0
while IFS= read -r old; do
  base=$(basename "$old")
  y=$(echo "$old" | cut -d/ -f2)
  m=$(echo "$old" | cut -d/ -f3)
  new="docs/plans/$y/$m/$base"
  if [[ ! -f "$new" ]]; then echo "MISSING $new"; missing=1; fi
  if [[ -e "$old" ]]; then echo "STILL PRESENT $old"; missing=1; fi
done < /tmp/asc-changelog-sources.txt
echo "legacy dated left: $(find changelog -path 'changelog/2026/*/*.md' 2>/dev/null | wc -l)"
test "$missing" -eq 0
```

Expected: every dated note present at its destination; legacy dated count `0`.

---

### Task 3: Retain and retarget `changelog/README.md`

**Files:**
- Modify: `changelog/README.md`

- [x] **Step 1: Keep useful historical context**

Do not replace the index with a stub that drops frontier notes, priority pointers, or shipped/live/later qualifications.

- [x] **Step 2: Update links inside the retained index**

Rewrite pointers that targeted dated notes under `changelog/2026/...` to their Appendix A destinations. Add the old→new map (or a link to Appendix A). Point at root `README.md` as SoT; optionally mention a regenerable `docs/README.md` index.

- [x] **Step 3: Remove empty year/month dirs** under `changelog/2026/` once Task 2 arrival passed.

---

### Task 4: Update affected references (path maintenance)

**Files:**
- Consumers from Task 1 inventory: gates, NEXT_STEPS, `@see`, skills, etc.
- Directory-level references such as `asc/test/core/yml.test.sh`
- **Not** `asc/doc/next_steps.sh` (deferred)

- [x] **Step 1: Rewrite live path strings**

Using Appendix A, update references that would break: gates rows, NEXT_STEPS lists, `@see` comments, and any other live pointers to moved notes.

- [x] **Step 2: Directory-level exclusions / globs**

Apply the maintenance choice for `yml.test.sh` (and any similar `changelog/**` directory scopes found in the inventory) so the move does not silently change what those searches cover. Note in the commit message or plan checkbox that the test was **not** executed here.

- [x] **Step 3: Same-wave discipline**

Prefer finishing Tasks 2–5 path edits before pausing, so the diff shows moves and retargets together.

- [x] **Step 4: Explicit deferral — next-steps scanner**

Do not edit `asc/doc/next_steps.sh`. Add a one-line pointer in the [gates/next-steps idea](../../../ideas/2026/11/10-gates-and-next-steps.md) (if not already clear) that the default scan dir still names `changelog/` after this migration and needs a deliberate choice later.

---

### Task 5: README live paths (+ optional convention proposal)

**Files:**
- Modify: `README.md`

- [x] **Step 1: Fix broken live README path references in place**

Retarget every **live** reference to a moved note, including:

- Markdown links (`[text](changelog/2026/...)`)
- Backticked or bare path mentions that are real citations (e.g. `` `changelog/2026/09/11-bootstrap-cache-layout-and-invalidation.md` `` at README ~1622)

Skip **illustrative** path-shape examples (especially inside fenced code blocks, and any deliberate “looks like `changelog/YYYY/MM/...`” examples that are not pointing at a specific note). Prefer retarget over delete when the note still exists.

- [x] **Step 2: Convention / explanatory prose (proposals only)**

No convention prose added; future changes use adjacent escaped proposal blocks per asc-author-docs.

- [x] **Step 3: Optional regenerable `docs/README.md` index**

Not created; optional.

---

### Task 6: Verify by review (no test suite)

- [x] **Step 1: Re-walk Appendix A** — every dated source has a destination file; none left under `changelog/2026/`.

- [x] **Step 2: Review changed paths** — skim `/tmp/asc-changelog-consumers.txt` against staged and unstaged diffs; confirm intended rewrites (including `changelog/README.md` links, in-note links to peers **and** root/code/skills, README Markdown links **and** live backticked paths, `yml.test.sh` exclusion) and the intentional non-edit of `next_steps.sh`.

- [x] **Step 3: Review status, staged + unstaged diffs, and intended untracked files**

`git mv` stages renames; unstaged `git diff` alone **misses** the moved corpus and any already-staged content edits. Use `--stat` only as a map of what changed; **also open the full diffs** so link rewrites and note bodies can be checked (statistics alone cannot show whether a target was corrected or meaning drifted).

```bash
cd "$HOME/Documents/asc"
git status
# map first
git diff --stat
git diff --cached --stat
git diff HEAD --stat
# then inspect full contents (page/scroll; narrow with -- path if needed)
git diff                    # full unstaged patch
git diff --cached           # full staged patch (renames + staged edits)
# unexpected plain deletes of dated notes:
git diff HEAD --diff-filter=D --name-only | grep 'changelog/2026/\|docs/plans/' || true
# intended untracked (e.g. new docs/README.md index): list, then read each file
git status -u --short | grep '^??' || true
# example: less -R docs/README.md
```

In the full staged and unstaged patches, spot-check: Appendix A arrivals/renames; in-note and README path rewrites; `changelog/README.md` link updates; directory exclusions; no unintended status/prose rewrites. Read the full text of every intended untracked file this plan adds. Confirm every Appendix A destination appears in the rename/move set. Investigate any plain delete of a dated note.

- [x] **Step 4: Mother-guard skim** of the diff.

- [x] **Step 5: Mark this plan completed.** Follow-ups: gates/next-steps idea (including scanner path); optional README convention proposals; later status reassessment of older plans.

---

## Appendix A — Old→new map

| old_path | new_path | notes |
|----------|----------|-------|
| `changelog/2026/07/24-subject-asc-extensions.md` | `docs/plans/2026/07/24-subject-asc-extensions.md` | moved |
| `changelog/2026/07/24-yml-structure.md` | `docs/plans/2026/07/24-yml-structure.md` | moved |
| `changelog/2026/07/26-living-docs-readme-status.md` | `docs/plans/2026/07/26-living-docs-readme-status.md` | moved |
| `changelog/2026/07/31-array-dict-naming-plan.md` | `docs/plans/2026/07/31-array-dict-naming-plan.md` | moved |
| `changelog/2026/07/31-nameref-clarity-candidates.md` | `docs/plans/2026/07/31-nameref-clarity-candidates.md` | moved |
| `changelog/2026/07/31-subshell-printf-v-candidates.md` | `docs/plans/2026/07/31-subshell-printf-v-candidates.md` | moved |
| `changelog/2026/08/18-transcribe-mp4.md` | `docs/plans/2026/08/18-transcribe-mp4.md` | moved |
| `changelog/2026/09/04-pdf-generation-improvements.md` | `docs/plans/2026/09/04-pdf-generation-improvements.md` | moved |
| `changelog/2026/09/10-begin-entity-system-with-remote-instances.md` | `docs/plans/2026/09/10-begin-entity-system-with-remote-instances.md` | moved |
| `changelog/2026/09/11-bootstrap-cache-layout-and-invalidation.md` | `docs/plans/2026/09/11-bootstrap-cache-layout-and-invalidation.md` | moved |
| `changelog/2026/09/11-lazy-opt-inc-and-entry-point-extraction.md` | `docs/plans/2026/09/11-lazy-opt-inc-and-entry-point-extraction.md` | moved |
| `changelog/2026/09/12-rename-generated-mk-to-pivots-mk.md` | `docs/plans/2026/09/12-rename-generated-mk-to-pivots-mk.md` | moved |
| `changelog/2026/09/12-rename-test-case-run-to-single-case-make.md` | `docs/plans/2026/09/12-rename-test-case-run-to-single-case-make.md` | moved |
| `changelog/2026/09/12-subject-object-action-entry-points.md` | `docs/plans/2026/09/12-subject-object-action-entry-points.md` | moved |
| `changelog/2026/09/17-pdf-graphviz-edge-labels.md` | `docs/plans/2026/09/17-pdf-graphviz-edge-labels.md` | moved |
| `changelog/2026/09/17-pdf-graphviz-support.md` | `docs/plans/2026/09/17-pdf-graphviz-support.md` | moved |
| `changelog/2026/09/19-db-thin-inc-and-opt-inc.md` | `docs/plans/2026/09/19-db-thin-inc-and-opt-inc.md` | moved |
| `changelog/2026/09/19-eager-vs-lazy-include-cases.md` | `docs/plans/2026/09/19-eager-vs-lazy-include-cases.md` | moved |
| `changelog/2026/09/19-fs-archive-lazy-include.md` | `docs/plans/2026/09/19-fs-archive-lazy-include.md` | moved |
| `changelog/2026/09/19-lazy-opt-inc-remaining-core-waves.md` | `docs/plans/2026/09/19-lazy-opt-inc-remaining-core-waves.md` | moved |
| `changelog/2026/09/19-mysql-pgsql-hook-opt-inc.md` | `docs/plans/2026/09/19-mysql-pgsql-hook-opt-inc.md` | moved |
| `changelog/2026/09/20-agent-review-feedback-home.md` | `docs/plans/2026/09/20-agent-review-feedback-home.md` | moved |
| `changelog/2026/09/20-builder-kernel-subject.md` | `docs/plans/2026/09/20-builder-kernel-subject.md` | moved |
| `changelog/2026/09/20-drop-empty-kernel-global-inc.md` | `docs/plans/2026/09/20-drop-empty-kernel-global-inc.md` | moved |
| `changelog/2026/09/20-gap-entity-not-core.md` | `docs/plans/2026/09/20-gap-entity-not-core.md` | moved |
| `changelog/2026/09/20-garage-lightweight-rule.md` | `docs/plans/2026/09/20-garage-lightweight-rule.md` | moved |
| `changelog/2026/09/20-host-scan-project-instances.md` | `docs/plans/2026/09/20-host-scan-project-instances.md` | moved |
| `changelog/2026/09/20-match-script-not-clone-includes.md` | `docs/plans/2026/09/20-match-script-not-clone-includes.md` | moved |
| `changelog/2026/09/20-meadows-plan-review-feedback-loop.md` | `docs/plans/2026/09/20-meadows-plan-review-feedback-loop.md` | moved |
| `changelog/2026/09/20-self-explainable-labels.md` | `docs/plans/2026/09/20-self-explainable-labels.md` | moved |
| `changelog/2026/09/20-stub-gap-inventory.md` | `docs/plans/2026/09/20-stub-gap-inventory.md` | moved |
| `changelog/2026/09/20-two-include-kinds.md` | `docs/plans/2026/09/20-two-include-kinds.md` | moved |
| `changelog/2026/09/21-hook-specificity-rungs.md` | `docs/plans/2026/09/21-hook-specificity-rungs.md` | moved |
| `changelog/2026/09/21-kernel-utils-inc.md` | `docs/plans/2026/09/21-kernel-utils-inc.md` | moved |
| `changelog/2026/09/21-manual-inc.md` | `docs/plans/2026/09/21-manual-inc.md` | moved |
| `changelog/2026/09/21-rename-asc-subject-to-core.md` | `docs/plans/2026/09/21-rename-asc-subject-to-core.md` | moved |
| `changelog/2026/09/21-utils-under-core.md` | `docs/plans/2026/09/21-utils-under-core.md` | moved |
| `changelog/2026/09/22-agent-llm-entry-point.md` | `docs/plans/2026/09/22-agent-llm-entry-point.md` | moved |
| `changelog/2026/09/22-deprecate-subject-asc-extensions.md` | `docs/plans/2026/09/22-deprecate-subject-asc-extensions.md` | moved |
| `changelog/2026/09/22-doc-next-steps.md` | `docs/plans/2026/09/22-doc-next-steps.md` | moved |
| `changelog/2026/09/22-gates-like-env.md` | `docs/plans/2026/09/22-gates-like-env.md` | moved |
| `changelog/2026/09/22-gates-prune-approved-work.md` | `docs/plans/2026/09/22-gates-prune-approved-work.md` | moved |
| `changelog/2026/09/22-gates-registry-alternative.md` | `docs/plans/2026/09/22-gates-registry-alternative.md` | moved |
| `changelog/2026/09/22-gitflow.md` | `docs/plans/2026/09/22-gitflow.md` | moved |
| `changelog/2026/09/22-make-ds-literal.md` | `docs/plans/2026/09/22-make-ds-literal.md` | moved |
| `changelog/2026/09/22-make-ds.md` | `docs/plans/2026/09/22-make-ds.md` | moved |
| `changelog/2026/09/22-make-generate-string.md` | `docs/plans/2026/09/22-make-generate-string.md` | moved |
| `changelog/2026/09/22-make-generate.md` | `docs/plans/2026/09/22-make-generate.md` | moved |
| `changelog/2026/09/22-next-steps-like-env.md` | `docs/plans/2026/09/22-next-steps-like-env.md` | moved |
| `changelog/2026/09/22-workflow.md` | `docs/plans/2026/09/22-workflow.md` | moved |
| `changelog/2026/09/22-xdg-state-store.md` | `docs/plans/2026/09/22-xdg-state-store.md` | moved |
| `changelog/2026/09/23-host-asc-core-sync.md` | `docs/plans/2026/09/23-host-asc-core-sync.md` | moved |
| `changelog/2026/09/25-concert-order.md` | `docs/plans/2026/09/25-concert-order.md` | moved |
| `changelog/2026/09/25-fs-file-list-append.md` | `docs/plans/2026/09/25-fs-file-list-append.md` | moved |
| `changelog/2026/09/25-fs-list-arrays.md` | `docs/plans/2026/09/25-fs-list-arrays.md` | moved |
| `changelog/2026/09/25-wired-init-lists.md` | `docs/plans/2026/09/25-wired-init-lists.md` | moved |
| `changelog/2026/09/26-app-prefix-inventory.md` | `docs/plans/2026/09/26-app-prefix-inventory.md` | moved |
| `changelog/2026/09/26-host-shell-aliases-asc.md` | `docs/plans/2026/09/26-host-shell-aliases-asc.md` | moved |
| `changelog/2026/09/26-patterns-and-antipatterns.md` | `docs/plans/2026/09/26-patterns-and-antipatterns.md` | moved |
| `changelog/2026/09/26-readme-toc-pre-commit.md` | `docs/plans/2026/09/26-readme-toc-pre-commit.md` | moved |
| `changelog/2026/09/27-agent-guidance-from-antipatterns.md` | `docs/plans/2026/09/27-agent-guidance-from-antipatterns.md` | moved |
| `changelog/2026/09/27-backlog-priority.md` | `docs/plans/2026/09/27-backlog-priority.md` | moved |
| `changelog/2026/09/27-desktop-agent-terminal-reply.md` | `docs/plans/2026/09/27-desktop-agent-terminal-reply.md` | moved |
| `changelog/2026/09/28-agent-instructions-travel.md` | `docs/plans/2026/09/28-agent-instructions-travel.md` | moved |
| `changelog/2026/09/30-asc-guidance-as-project-skills.md` | `docs/plans/2026/09/30-asc-guidance-as-project-skills.md` | moved |
| `changelog/2026/09/30-cursor-rules-home.md` | `docs/plans/2026/09/30-cursor-rules-home.md` | moved |
| `changelog/2026/10/02-reinit-performance.md` | `docs/plans/2026/10/02-reinit-performance.md` | moved |
| `changelog/2026/10/29-local-concurrent-stacks.md` | `docs/plans/2026/10/29-local-concurrent-stacks.md` | moved |
| `changelog/2026/11/06-host-needs-and-skill-feedback.md` | `docs/plans/2026/11/06-host-needs-and-skill-feedback.md` | moved |
| `changelog/2026/11/06-simplify-disk-entities-contracts.md` | `docs/plans/2026/11/06-simplify-disk-entities-contracts.md` | moved |
| `changelog/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md` | `docs/plans/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md` | moved |
| `changelog/2026/11/10-agent-plan-cursor-codex-ollaya.md` | `docs/plans/2026/11/10-agent-plan-cursor-codex-ollaya.md` (later `docs/ideas/2026/11/10-agent-plan-cursor-codex-ollaya.md`) | moved |
| `changelog/README.md` | `changelog/README.md` | retained; links retargeted |

---

## Out-of-scope reminders

| Topic | Where it goes |
|-------|----------------|
| Gates / next-steps design + `next_steps.sh` default dir | [docs/ideas/2026/11/10-gates-and-next-steps.md](../../../ideas/2026/11/10-gates-and-next-steps.md) |
| Decision extraction / status vocabulary redesign | Not this migration |
| Running `yml.test.sh` / `test-core` / new test scripts | Not this migration — inspect exclusion only |
| Multi-instance scanner compatibility | Later / that idea |

## Mother-guard

Mother-only paths and ASC placeholders. No client-identifying content.
