# Gates, next-steps, and mature ASC entry points

Status: open idea  
Created: 2026-11-10  
Related migration: [docs/plans/2026/11/10-changelog-refactor.md](../../../plans/2026/11/10-changelog-refactor.md)

## Question

Are `gates*.yml` and the generated / human next-steps files still the right surfaces for authorizing and prioritizing agent work in ASC? What problem do they solve today, and how should that relate to:

- mature `$subject` / `$object` / `$action` entry points and Make pivots
- the DSL (`make ds` and related plans)
- agent tools (hooks, contrib implementations, desktop vs headless)

This idea is **not** an implementation go-ahead. The changelog → `docs/plans/` migration only retargets broken paths; it does not assume the current scanner or gate model is the long-term design.

## Why separate this from the docs-tree migration

Moving dated notes out of `changelog/` forces path maintenance in gates rows, next-steps lists, and `@see` comments. That mechanical work must not quietly redesign approval, lane classification, or queue generation. Those are product questions about ASC’s agent workflow.

## What to explore later

1. **Need:** Which failures appear without gates / next-steps (lost approvals, duplicate work, unclear authorization)?
2. **Overlap:** What already belongs in README, plans’ own status lines, Make entry points, or agent skills?
3. **Scanner coupling:** Today `asc/doc/next_steps.sh` classifies notes by status-cell wording under a scanned directory. Should that continue, move, or shrink once plans live under `docs/plans/`?
4. **Gates shape:** Keep YAML approvals, replace with another store, or fold go-ahead into entry-point / DSL / agent-tool contracts?
5. **Instance variants:** How `gates.$INSTANCE_TYPE.yml` and `NEXT_STEPS*.md` should behave across mother vs client instances after docs layout changes.

## Known follow-up after the docs/plans migration

The narrow migration leaves `asc/doc/next_steps.sh` unchanged. Its default scan directory still names `changelog/`. **After dated notes move to `docs/plans/`, that default will no longer discover them.** The scanner is not currently relied on for day-to-day work; choosing a new default (or retiring the scan) belongs here, together with any lane/classification redesign — not in the path-move plan. Keep this discovery warning visible until that choice is made.

## Non-goals for this idea file

- Migrating `changelog/` files (see the related plan).
- Extracting ADRs from historical notes.
- Rewriting the root README’s ASC concept sections.
- Running next-steps or gates as part of the docs-tree move.

## Outcome when ready

A short decision or plan that either (a) keeps gates + next-steps with a clarified contract, (b) replaces them with named successors tied to entry points / DSL / agent tools, or (c) retires parts of the model with an explicit migration for instances.
