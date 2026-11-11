# LLM Space Evaluation

| Field | Value |
|---|---|
| Date | 2026-11-11 |
| Status | Idea for discussion; no implementation or provider choice is approved. |
| Scope | Evaluation of the eventual usefulness of the "LLM Space" tool. |

LLM Space looks useful as an **optional laboratory for developing and inspecting agents**, but I would not make it a foundation of your second brain or a dependency of the planned `make agent-plan` workflow. Its strongest overlap with your research is the missing measurement and debugging layer: it records model and tool activity, lets you compare runs, and supports human-scored evaluations. Its biggest practical obstacle is that its published desktop releases are macOS DMGs, while your primary environment is Debian.

My recommendation is to **study its design now and defer integration**. A small experiment becomes worthwhile if you have access to a Mac or if Linux desktop support becomes practical. For your immediate Cursor → Codex plan, retain the ASC orchestration and security contracts you have already specified.

## What LLM Space does

[LLM Space](https://github.com/deer-flow/llm-space) is an MIT-licensed desktop workbench for building, debugging, and evaluating LLM agents. It is a sister project of DeerFlow, but it is a separate application: it uses the Pi agent framework and provides a desktop interface around agent experiments. The project describes v4 as a place to edit prompts and tools, inspect model and tool calls, replay runs, and compare performance. [Source: project README](https://github.com/deer-flow/llm-space/blob/main/README.md)

Its main working unit is a **Thread**: a local JSON file containing an experiment’s model configuration, system prompt, tools, messages, tool calls, run history, and evaluation records. You can inspect recorded tool inputs and outputs, compare two saved runs, and assign human scores against a rubric. The documented rubric mechanism has 2–6 criteria and preserves the rubric and scores with the runs; it does not itself make another model call. [Source: core concepts](https://github.com/deer-flow/llm-space/blob/main/docs/core-concepts.md)

Other relevant capabilities include:

- **Extensions:** MCP servers, skills, model providers, tools, commands, and alternative thread storage can be contributed by plugins. [Source: plugin guide](https://github.com/deer-flow/llm-space/blob/main/docs/plugins.md)
- **Model endpoints:** custom providers can use compatible APIs and configurable base URLs. This makes a local model endpoint a plausible experiment, but I did not verify a working Ollama setup or the compatibility of your particular models. [Source: model configuration](https://github.com/deer-flow/llm-space/blob/main/docs/core-concepts.md)
- **Compaction:** old conversation turns can be summarized into a checkpoint, with the original thread preserved and a new thread created. [Source: compaction](https://github.com/deer-flow/llm-space/blob/main/docs/compaction.md)
- **Import and export:** it can import several conversation formats, including DeerFlow run-event JSONL, and can generate an editable LangGraph/Python project from a thread. Import support does not by itself establish compatibility with ASC or Codex traces. [Sources: import formats](https://github.com/deer-flow/llm-space/blob/main/docs/core-concepts.md), [manual](https://github.com/deer-flow/llm-space/blob/main/docs/index.md)

The repository currently lists **v4.20.0**, released on October 12, 2026. The published downloads described by the project are macOS DMGs for Intel and Apple Silicon. Its manual also lists a desktop-to-Linux runtime over SSH, but that does not establish availability of a Linux desktop client. [Sources: releases](https://github.com/deer-flow/llm-space/releases), [manual](https://github.com/deer-flow/llm-space/blob/main/docs/index.md)

## Fit with your second-brain research

I reviewed the synthesis of the three literature collections and the two ASC plan documents. The synthesis notes are proposals and research conclusions, not evidence that all of those components already exist.

| Your concern | Potential contribution from LLM Space | Remaining gap |
|---|---|---|
| **Observability and evaluation** | Saved runs, tool-call inspection, comparison, and human rubrics provide a concrete reference for an agent workbench. | Your research calls for a broader trace schema, golden sets, context-component measurements, and a reusable eval plane. Its documented manual evaluations do not establish those capabilities. |
| **Files as the system of record** | Thread JSON files are locally accessible and can preserve experiment evidence. | They are application-specific conversation records. They do not provide your proposed Claim, Gap, evidence, provenance, and lifecycle model. |
| **Retrieval and context packing** | Tools and MCP could connect a prototype to your retrieval service; compaction offers a useful interface pattern. | I found no basis to treat it as your lexical-first retrieval pipeline, source ingestion system, or context-packing controller. |
| **Human review** | Manual comparisons and preserved evaluation records align with keeping a human in the loop. | Scoring a run is not equivalent to accepting a knowledge claim or authorizing an operational action. |
| **Local-first operation** | Threads are stored locally, and compatible local model endpoints may be usable. | Model calls, web tools, MCP servers, plugins, sharing, and telemetry each have separate data flows. Local storage alone does not make a run offline. |
| **Debian and modest hardware** | A remote Linux runtime is documented. | The desktop distribution is a significant mismatch for your Debian workstation; a source build’s Linux usability remains unverified. |

The strongest conceptual fit is with your agentic review’s conclusion that **measurement precedes regulation**. LLM Space demonstrates an approachable way to put run history, tool calls, replay, and evaluation in front of a human. It is less clearly a match for your planned durable data architecture, where source files and knowledge objects have their own provenance and derived stores can be rebuilt. See your [agentic synthesis](<AI Reviews/agentic-ai, rag, retrieval, packing, workflow, anonymization/10-synthesis-v6-delta-strategy-and-staged-roadmap.md>) and [data architecture synthesis](<AI Reviews/data stores, databases, wiki, plain file storage (md, json, yaml)/06-synthesis-data-architecture-v6-delta-and-rebuild-first-roadmap.md>).

## Fit with `make agent-plan`

Your [functional plan](changelog/2026/11/10-agent-plan-cursor-codex-ollaya.md) and [implementation plan](changelog/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md) describe a specific headless workflow: Cursor writes a staged plan, Codex reviews the exact snapshot against the original brief and declared needs, and ASC decides whether the named next step is ready. The plan also separates readiness from human authorization and gives the orchestrator ownership of promotion.

LLM Space could help **prototype prompts or inspect representative runs**, but I would not assume it can transparently observe the actual Cursor and Codex sessions. Its documented traces describe runs in its own runtime, while its import formats do not establish support for the exact provider session formats or ASC’s proposed result schema. That integration would need a concrete adapter and a fidelity test.

It also does not replace the contracts that matter most in your plan:

- digest binding between the reviewed bytes and the promoted plan;
- structured `yes` / `no` / `unknown` readiness and pause behavior;
- the staging, lock, recheck, and promotion procedure;
- role-specific sandbox enforcement and its explicitly stated limits;
- the distinction between readiness and authorization.

A particularly relevant limitation is that the current plugin guide says **before/after agent, turn, and model hooks are unsupported**. That makes it a weak candidate for implementing your proposed ASC hook-based measurement or `pre_llm` policy boundary without changes outside the documented plugin API. [Source: unsupported plugin features](https://github.com/deer-flow/llm-space/blob/main/docs/plugins.md#18-currently-unsupported)

## Privacy and operational implications

The project says prompts and file contents are excluded from its analytics, but usage telemetry sends events to PostHog EU with a randomly generated installation identifier. It documents a settings toggle and an environment-variable override to disable analytics. This is only the telemetry path: a cloud model, web search, MCP server, or plugin can still receive data according to its own configuration. [Source: telemetry policy](https://github.com/deer-flow/llm-space/blob/main/TELEMETRY.md)

The plugin security boundary deserves particular attention for your project. The authors state that plugins have **no trust prompt or permission manifest**, and that their process isolation is **not an OS sandbox**: plugin code can access the current user’s files, processes, environment, and network. Therefore, LLM Space’s plugin model should not be taken as evidence that your reviewer’s enforced filesystem boundary is met. [Source: plugin security](https://github.com/deer-flow/llm-space/blob/main/docs/plugins.md#14-trust-and-security)

Thread JSON and traces can also contain prompts and tool outputs. If you experiment with private research or client data, their location, backup, retention, and deletion need the same consideration as other sensitive working files. Sharing a thread is an explicit publication path through a secret GitHub Gist, according to the manual. [Sources: storage](https://github.com/deer-flow/llm-space/blob/main/docs/core-concepts.md#file-storage), [manual](https://github.com/deer-flow/llm-space/blob/main/docs/index.md)

## A worthwhile, bounded experiment

If the platform issue can be resolved, I would test LLM Space with **synthetic or already-public material**, before connecting your actual knowledge base:

1. Take one representative planning brief and two saved candidate plans or review results. Try importing them, or recreate the experiment in a thread; record which metadata and tool events survive.
2. Define a small human rubric around your actual criteria: coverage of the original brief, evidence for the named next step, identification of missing decisions, and unsupported readiness claims.
3. Compare its replay and evaluation interface with the evidence you expect ASC to retain. Check whether it reduces review time or exposes an error that your existing records would make hard to find.
4. Separately test a local compatible model endpoint and measure whether tool calls and structured output work with your chosen model. Treat this as a compatibility test, not an assumption about Ollaya.
5. Stop if using it requires making its thread JSON the authoritative plan or weakening ASC’s isolation and promotion rules.

A successful result would justify using it as a **developer-facing inspection tool** or borrowing its UX patterns for your own trace/eval plane. It would not, by itself, justify adding it to the production path.

This assessment is based on the project’s current documentation and your synthesis and plan documents; I did not install or run LLM Space, verify Linux desktop support, test Ollama, or audit its source security end to end.
