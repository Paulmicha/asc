# ASC Living Documentation

Always-current explanation of how ASC works **now**, plus compiled rewrite notes from root [`README.md`](../../README.md) § Current status.

Raw working notes still live in that README section until the product README is fully rewritten. Prefer this suite over duplicating long dumps.

## Current rewrite status

*Massive rewrite* in progress: shrink to bare essentials, restabilize naming / workflow / hooks / DSL / YAML, then refactor bootstrap → core → tests → builder → baseline → agents.

Stabilization order (from root README TODO):

1. Naming convention (doc)
1. Workflow + git flow (doc)
1. Hooks (doc)
1. DSL (doc)
1. YAML (doc)
1. Refactor bootstrap
1. Refactor core + core extensions
1. Refactor tests (switch to nestable entity)
1. Complete the builder
1. Complete baseline implementations
1. Implement agents (Cursor MVP first; later Hermes + ollama + kimi ?, open)

Also open: discovery must support both `$subject`/`$action` and `$subject`/`$object`/`$action` (agnostic stance — see [organization.md](organization.md) § subjects). Nested extensions: plan SoT is `$subject/.asc_extensions` (`24-subject-asc-extensions.md`); README tension about dropping that mechanism stays open until a changelog decides.

## July 2026 plan SoTs (review — not go-ahead)

Dated plans under `changelog/2026/07/` that living docs compile from:

| Plan | Living home |
|------|-------------|
| [`23-f-e-naming-convention.md`](../../changelog/2026/07/23-f-e-naming-convention.md) | [shell-usage.md](shell-usage.md) § symbol prefixes; [organization.md](organization.md) § globals (`a` / `a_*` positionals; `e_*` / `hookms`) |
| [`24-filename-dsl.md`](../../changelog/2026/07/24-filename-dsl.md) | [shell-usage.md](shell-usage.md) § filename-DSL; [organization.md](organization.md) § bootstrap / hooks; [documentation.md](documentation.md) § `$` notation |
| [`24-subject-asc-extensions.md`](../../changelog/2026/07/24-subject-asc-extensions.md) | [organization.md](organization.md) § subjects; [wrappers.md](wrappers.md) § nested |
| [`24-yml-structure.md`](../../changelog/2026/07/24-yml-structure.md) | [yml-structure.md](yml-structure.md) |
| Root README § Current status | Compiled across org / entities / builder / shell-usage — see [`26-living-docs-readme-status.md`](../../changelog/2026/07/26-living-docs-readme-status.md) |

`23-initial-changelog.md` is empty (placeholder).

Table of contents :

1. [documentation (3 types only, as far as ASC is concerned)](documentation.md)
    1. [ideas](documentation.md#ideas)
    1. [changelogs](documentation.md#changelogs)
    1. [living docs](documentation.md#living)
1. [organization](organization.md)
    1. [globals](organization.md#globals)
    1. [hosts](organization.md#hosts)
    1. [instances](organization.md#instances)
    1. [humans vs agents (ownership ?)](organization.md#humans-vs-agents-ownership)
    1. [subjects](organization.md#subjects)
    1. [actions](organization.md#actions)
    1. [hooks](organization.md#hooks)
    1. [variants](organization.md#variants)
    1. [bootstrap : inc, opt-inc](organization.md#bootstrap-inc-opt-inc)
    1. [make shortcuts](organization.md#make-shortcuts)
    1. [(re)init : cache, state](organization.md#re-init-cache-state)
1. [wrappers](wrappers.md)
    1. [batch (synonym : parallel)](wrappers.md#batch-synonym-parallel)
    1. [chain (synonym : sequence)](wrappers.md#chain-synonym-sequence)
    1. [cronjob (TODO or just use "raw" thread wrapper instead ?)](wrappers.md#cronjob-todo-or-just-use-raw-thread-wrapper-instead)
    1. [loop (TODO synonyms : deamon ? background task ? background job ? always-on ?)](wrappers.md#loop-todo-synonyms-deamon-background-task-background-job-always-on)
    1. [nested](wrappers.md#nested)
    1. [pipe](wrappers.md#pipe)
    1. [remote](wrappers.md#remote)
    1. [rule (conditional and/or nested combinations)](wrappers.md#rule-conditional-and-or-nested-combinations)
    1. [sequence](wrappers.md#sequence)
    1. [stream ?](wrappers.md#stream)
    1. [thread](wrappers.md#thread)
    1. [tunnel](wrappers.md#tunnel)
    1. [vpn](wrappers.md#vpn)
    1. [curl](wrappers.md#curl)
    1. [$protocol ? (http, etc)](wrappers.md#protocol)
1. [entities](entities.md)
    1. [represents ? (why it exists)](entities.md#represents-why-it-exists)
    1. [definition (scope ?)](entities.md#definition-scope)
    1. [capabilities](entities.md#capabilities)
    1. [field vs prop](entities.md#field-vs-prop)
    1. [sidecar](entities.md#sidecar)
    1. [relationships](entities.md#relationships)
    1. [compatibility, applicability ? (protocols, etc)](entities.md#compatibility-applicability-protocols-etc)
    1. [yml includes (synonym : inheritance)](entities.md#yml-includes)
    1. [change / workflow](entities.md#change--workflow)
1. [yml structure (YAML bodies; complementary to filename-DSL)](yml-structure.md)
    1. [scope vs filename-DSL](yml-structure.md#scope-vs-filename-dsl)
    1. [file kinds](yml-structure.md#file-kinds)
    1. [props vs fields in bodies](yml-structure.md#props-vs-fields-in-bodies)
    1. [state able (git draft)](yml-structure.md#state-able-git-draft)
    1. [subject inventory](yml-structure.md#subject-inventory)
    1. [repo entity (git draft)](yml-structure.md#repo-entity-git-draft)
    1. [primordial meta (Wave B draft)](yml-structure.md#primordial-meta-wave-b-draft)
    1. [open / living](yml-structure.md#open--living)
1. [builder](builder.md)
    1. [documenting (~ minimal OKF ? dedicated core extension ?)](builder.md#documenting-minimal-okf-dedicated-core-extension)
    1. [blueprints](builder.md#blueprints)
    1. [atomic blueprint objects](builder.md#atomic-blueprint-objects)
    1. [slots](builder.md#slots)
    1. [templates](builder.md#templates)
    1. [self-building (chain.able, nest.able, rule.able codegen for humans and agents)](builder.md#self-building-chain-able-nest-able-rule-able-codegen-for-humans-and-agents)
1. [testing](testing.md)
    1. [1. Conventions (layers)](usage.md)
    1. [1. asc/vendor/shunit2 dependency](usage.md)
    1. [1. TODO new browser asc core extension, with playwright as default implementation in core as well ?](usage.md)
1. [usage](usage.md)
    1. [start](usage.md#start)
    1. [extend](usage.md#extend)
    1. [customize](usage.md#customize)
    1. [adapt](usage.md#adapt)
    1. [contribute](usage.md#contribute)
1. [shell usage](shell-usage.md)
    1. [stdin / stdout / stderr](shell-usage.md#stdin--stdout--stderr)
    1. [sourcing](shell-usage.md#sourcing)
    1. [argument forwarding](shell-usage.md#argument-forwarding)
    1. [shell options](shell-usage.md#shell-options)
    1. [scope](shell-usage.md#scope)
    1. [walk arrays](shell-usage.md#walk-arrays)
    1. [step by step](shell-usage.md#step-by-step)
    1. [symbol prefixes (f_ / e_ / o_ / a_ / b_ / hookms)](shell-usage.md#symbol-prefixes-f_--e_--o_--a_--b_--hookms)
    1. [filename-DSL examples](shell-usage.md#filename-dsl-examples)
    1. [proposed DSL redesign (README)](shell-usage.md#proposed-dsl-redesign-readme)
    1. [parsable stdout (asc-dsl / asc-yml)](shell-usage.md#parsable-stdout-asc-dsl--asc-yml)
