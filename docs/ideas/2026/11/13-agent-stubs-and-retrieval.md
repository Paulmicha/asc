# Agent stubs, local orchestration, and code retrieval

Status: research and proposals, not an implementation decision or go-ahead  
Created: 2026-11-13  
Context: [agent-plan design](10-agent-plan-cursor-codex-ollaya.md), [open decisions](12-agent-spec-open-decisions.md), [clone clues](12-clone-clues-for-open-decisions.md), [skill management](11-agent-skills-manager.md), [local action records](13-local-action-records.md)

## Purpose and evidence

The desired direction is a simple human entry such as `make new-plan` with a
prose brief, followed eventually by `make plan-execute`. Enabled, local ASC
hook implementations could compose agents, threads and loops. The exact Make
quoting, arguments, results and names are not established by this example.
The long-term aim is to evaluate more work on local devices and models,
including Tiiny and Ollaya, while keeping stronger hosted agents available
where they earn their cost. Neither a particular device nor a model is assumed
to provide a complete agent runtime.

This note reads commit `9d2f22e` and selected source and documentation in the
shallow checkouts in `data/tmp`. The stubs are a human's directions to explore,
not complete contracts. Upstream descriptions below are reported capabilities,
not locally measured performance, security or compatibility. No agent, MCP
server, indexer or model was installed or run for this survey.

The README assigns ASC a thin integration and contract role and delegates
complex agent work; a generic entry point does not require ASC to own an LLM
loop, retrieval engine, model server, provider's UI or session database.

## What the stubs bring into focus

| WIP evidence in `asc/extensions/agent/` | Direction and unresolved choice |
|---|---|
| `agent/list.sh` changes to list agents and uses `hook`; `model/list.sh` and `model/pull.sh` use `hook_ms` | Agent product or harness and model are different things. Listing can aggregate implementations, while an operation choosing one implementation needs a defined selection rule. A cloud model, locally served model and a full CLI agent are not interchangeable. No model lifecycle or inventory contract follows from the filenames. |
| `agent/role/list.sh`, the `agent_role/list` hook, empty writer/reviewer YAML files and `role/use.sh` TODO | Roles express jobs such as writer and reviewer. A role could map to a provider, model, instructions and capabilities, but a YAML schema, precedence, lifecycle and even whether another wrapper is needed remain open. A role is not itself a model or an authorization grant. |
| `chat/create.sh`, `read.sh`, `reply.sh` use `CHAT_PROVIDER`, default `dummy`, and pre/main/post `hook` calls | Provider selection is now explicit in the skeleton. An all-matching `hook` is materially different from the earlier plan's one `hook_ms` selected by `CHAT_ROLE`: multiple provider implementations could run. The `dummy` fallback and missing-provider behavior need explicit tests; no successful dummy exists merely because the variable is set. |
| Empty `plan/create.sh`, `plan/execute.sh` and `need/create.sh`, `list.sh`, `status.sh` | A creation action and an eventual execution action are distinct. Whether needs are separate durable records or plan-contained declarations is open; the older v1 plan deliberately kept declared needs in the plan. Empty files do not define either lifecycle or ready/authorized/executed states. |
| Empty `skill/load.sh`, `skill/activate.sh` | Discovering or loading instructions, activating a capability in a provider, and installing/removing skill files are separate operations. Existing [skill-management research](11-agent-skills-manager.md) covers installation ownership and collisions; it does not prove a CLI supports dynamic activation during a session. |
| Empty `workspace/index.sh` | A workspace can be a local project and an index can be an optional delegated retrieval capability. Filesystem, instructions, index, agent product workspace and ChatGPT organization workspace have different scopes. Decide whether a generic index action has a real caller and whether it means build, refresh, query or status before designing a contract. |
| `agent/run.sh` currently calls `agent/stop`; old test registration was removed | This is inconsistent WIP, not evidence that run means stop or that behavior works. Several named files are empty. No core agent suite follows from the deleted registration. README's older `agent-start` example also needs a separately authorized reconciliation, not silent reliance. |

The `new-chat` synonym in `chat/global.vars.sh` points to `chat-create` in
source; whether it is enabled and present in generated Make pivots depends on
instance initialization. Likewise `new-plan` is the desired experience, not
an observed alias. A local variable documented by an action is not by itself a
result accessible across a Make subprocess: choose a structured output and
failure contract where callers need one.

## How to resolve the most consequential choices

1. **One turn, one selected provider.** For the draft/review loop, retain the
   requirement that a turn invokes one concrete implementation exactly once.
   Candidate A: select `CHAT_PROVIDER` with existing `hook_ms` variant lookup,
   and have the caller resolve role to provider. Candidate B: retain role
   variants as the earlier plan proposed, with each role hook invoking its
   provider. Candidate C: `hook` for aggregation only, with a separate explicit
   selection mechanism for turns. A lets several roles use one provider; B is
   smallest for the two-role experiment; C adds machinery unless a real need
   justifies it. Normal `hook_ms` fallback, location precedence and variant
   combinations still apply; pass variable names to `-v`. Do not assume the
   current all-matching `hook` guarantees a single turn. Decide which variable
   owns selection and test missing matches and invocation count before coding.
2. **Role mapping.** First try explicit local role-to-provider/model choices
   at the composition boundary. Add role YAML loading only if a concrete use
   demonstrates reusable value, rather than maintaining a second registry of
   settings already owned by the providers. Determine how explicit overrides,
   defaults, provider capabilities and unavailable roles are reported.
3. **Plan lifecycle.** `plan-create` could orchestrate the original brief into
   a reviewed plan, with a `new-plan` synonym if desired. Alternatively retain
   `agent-plan` as the composition and let creation be a smaller primitive.
   Compare real callers before selecting. `plan-execute` must not follow from
   creation or `plan-is ready` alone: readiness, authorization, execution and
   verified outcome are different. Define how it selects a plan and step,
   obtains authorization, reports partial failure, resumes and avoids
   repeating side effects before implementation.
4. **Needs.** Keep the earlier plan-contained representation for the first
   workflow unless a second caller demonstrates the value of independent
   `need-*` records. If separate records become necessary, define identity,
   authority, links to plan revisions and synchronization first.
5. **Retrieval.** Start with existing file search for a measured baseline. If
   a real task benefits, delegate indexing or semantic operations to an
   existing CLI/MCP tool. Do not make an index mandatory for chat, plan
   readiness or every agent, and do not equate an index with a workspace.

These are recommendations for review, not decisions attributed to the stub
author. The previous implementation plan's exact paths and role contract need
reconciliation; its staged promotion, evidence, isolation and archive gates
remain meaningful independent requirements.

## Existing shallow agent clones

| Observed source | Relevance and limit |
|---|---|
| [OpenHands SDK Agent](https://github.com/OpenHands/software-agent-sdk/blob/10be259c4fc8/openhands-sdk/openhands/sdk/agent/agent.py) separates an LLM and tools; its [agent profile](https://github.com/OpenHands/software-agent-sdk/blob/10be259c4fc8/openhands-sdk/openhands/sdk/profiles/agent_profile.py) separately references MCP servers and secrets. | Supports separating model, harness and capabilities. Its rich profile is not proof ASC needs a profile database or should copy its defaults; `null` and `[]` have distinct meanings there. |
| [OpenHands local workspace](https://github.com/OpenHands/software-agent-sdk/blob/10be259c4fc8/openhands-sdk/openhands/sdk/workspace/local.py) performs local file and command operations; conversation state is separately managed. | A workspace can denote execution context without implying an index or a ChatGPT account workspace. Its direct host access is not evidence of ASC's proposed sandbox isolation. |
| [Goose ACP provider](https://github.com/aaif-goose/goose/blob/249316032104/crates/goose/src/acp/provider.rs) exposes a provider session id alongside its session identity; [Hermes Codex runtime](https://github.com/NousResearch/hermes-agent/blob/2bfa6b07a14a/agent/codex_runtime.py) stores a Codex thread reference. | A wrapper may need a stable mapping to a product-owned session without owning the product's store. This does not decide whether ASC needs two public IDs or how its archive recovers. |
| [DeepSeek team tool tests](https://github.com/deepseek-ai/deepseek-harness/blob/e8f7b93a3449/packages/team/tool-agent-team/tests/tool-team.spec.ts) exercise model selection and tool assembly for agents. | Demonstrates that model, agent and exposed tools can vary independently. This is a more elaborate runtime than the thin ASC entry proposed here, not a template to import. |
| [Aider](https://github.com/Aider-AI/aider/tree/5dc9490bb35f), [DeerFlow](https://github.com/bytedance/deer-flow/tree/04a9833763f7), [Hermes](https://github.com/NousResearch/hermes-agent/tree/2bfa6b07a14a) and [Goose](https://github.com/aaif-goose/goose/tree/249316032104) have the session, cancellation and queue examples already compared in [clone clues](12-clone-clues-for-open-decisions.md). | Those examples inform state and interruption, not a requirement to copy a durable queue, database, daemon or autonomous multi-agent framework. `thread` in those products need not mean ASC's process wrapper. |

## Retrieval and filesystem candidates

The following are complementary tool choices, not substitute agent
orchestrators. MCP is a way to expose tools to a client; it does not itself
index code or guarantee an agent uses the tools. Pin and inspect the selected
version before any trial. All revision links below match the cloned HEADs.

| Candidate | Observed from cloned sources | Implication for `workspace/index` |
|---|---|---|
| [Serena `6e5c3776d4e6`](https://github.com/oraios/serena/tree/6e5c3776d4e6) | [README](https://github.com/oraios/serena/blob/6e5c3776d4e6/README.md) describes LSP-backed symbol navigation, references and edits, plus an optional JetBrains backend and memory. Some languages need additional language-server dependencies. | Useful for exact symbol and reference questions, potentially including Bash, but language-server coverage on ASC patterns needs measurement. This is not the same as vector retrieval, and edit tools require an appropriate boundary. |
| [CocoIndex Code `5676897a169f`](https://github.com/cocoindex-io/cocoindex-code/tree/5676897a169f) | Its README describes Tree-sitter-aware semantic search via CLI, skill or MCP. The full package uses local embeddings; the slim package is described as requiring a cloud embedding provider. Its MCP search defaults to index refresh. | Candidate for fuzzy code discovery; distinguish local embedding inference from first-time model download, refresh writes and possible remote providers. A search can mutate index state, so test reviewer isolation and freshness. |
| [Realtime example `07af206605bd`](https://github.com/cocoindex-io/realtime-codebase-indexing/tree/07af206605bd) | The [example](https://github.com/cocoindex-io/realtime-codebase-indexing/blob/07af206605bd/README.md) uses incremental Tree-sitter chunks, embeddings and Postgres/pgvector, with optional live updates. | Illustrates the engineering behind an index, not the same deployable product as CocoIndex Code. An always-running database or watcher is not justified for ASC by the example alone. |
| [Moderne docs `f18f272222a1`](https://github.com/moderneinc/moderne-docs/tree/f18f272222a1) and [OpenRewrite `858cb51abdb5`](https://github.com/openrewrite/rewrite/tree/858cb51abdb5) | [Moderne's local MCP docs](https://github.com/moderneinc/moderne-docs/blob/f18f272222a1/docs/user-documentation/agent-tools/mcp/overview.md) describe an experimental `mod mcp` in the Moderne CLI, requiring a Git repository, with a trigram text index, LST-based tools and recipes. Trigrep is not itself an LST semantic index. | Candidate for structured navigation and deterministic recipes where supported. The local MCP server implementation was not identified as a public clone; these are its documentation and related OpenRewrite source, not a server-source audit. Check language/build support, licensing and the actual tool before relying on it. |
| [MCP reference servers `e1dc4b18dbb9`](https://github.com/modelcontextprotocol/servers/tree/e1dc4b18dbb9), [`src/filesystem`](https://github.com/modelcontextprotocol/servers/blob/e1dc4b18dbb9/src/filesystem/README.md) | Filesystem operations are limited by configured allowed directories; this revision describes read-only options and OS-level defense in depth. Its `search_files` searches names, not file contents. | A filesystem server is not a semantic index or a complete sandbox. It may be redundant with a CLI agent's file tools; an external server's privileges can exceed a sandboxed client's unless the server is confined too. |

The requested clones, including Moderne documentation and OpenRewrite as
related public sources, are local research checkouts under `data/tmp`; they
are not dependencies of ASC and should not be treated as verified installs.

## Proposed small evaluation before choosing integration

Use a disposable, non-sensitive project and a short, fixed question set that
includes exact ASC action/hook discovery, Bash symbol references, conceptual
cross-file search, a negative case, and an edit followed by deletion. Compare
`rg` and normal file reads with Serena and CocoIndex separately; only trial
Moderne if its actual CLI, language support and terms fit. For each record
version, configuration, build and refresh time, result paths and supporting
lines, missed and stale results, resource use, network/model downloads, index
location, ignore behavior and cleanup. Measure actual tasks, not vendor speed
claims. Keep the candidate outside the production workflow until a useful
improvement is demonstrated.

For writer and reviewer separately test where the server runs, what it can
read/write, whether refresh changes state, how permissions and credentials are
passed, and whether edits and external side effects are blocked as intended.
An MCP tool is not confined merely because the client is. Then test the same
capability with the intended local harness/model pair, including structured
output and actual tool calling. Compare results, latency and memory against the
hosted baseline; retain human review and explicit authorization. A local
model, local index and local transcript do not independently establish that
every part of the workflow is offline.

Before implementation, resolve the role/provider selection and entry-point
names, archive and thread-control gates, the exact host feasibility probes in
the [implementation plan](../../../plans/2026/11/10-agent-plan-cursor-codex-ollaya-impl.md),
and the meaning of plan execution. Nothing in this survey asserts the stubs,
clones or planned end-to-end loop have been run.
