# Loose ends found while reviewing agent tracking

- **Date:** 2026-11-11
- **Status:** observations. None is fixed here; each needs its own decision.
- **Scope:** mismatches between code, README and docs in the mother checkout that touch threads, logs, chats, plans or skills.
- **Method:** every line below was checked against the work tree on 2026-11-11 with a file listing or a search. Nothing was run.
- **Siblings:** [run tracking](11-agent-run-tracking.md), [control actions](11-agent-control-actions.md), [drift guardrails](11-agent-drift-guardrails.md)

## Entry points that cannot run

| Entry | Problem |
|---|---|
| `asc/instance/logged/loop.sh` (`make ll`, synonym `logged-loop`) | calls `asc/loop/loop.wrap.sh`; `asc/loop/` does not exist |
| `asc/extensions/agent/prompt/generate.sh`, `prompt/refine.sh`, `instance/logged_agent.sh` | source `asc/extensions/agent/agent/wrap.sh`; the file does not exist |
| `asc/extensions/agent/chat/{new,reply,read,archive}.sh` | call `chat` hooks; no implementation exists in the mother |
| `asc/extensions/agent/agent/*.sh` | call `agent` hooks; the mother's contrib directories for agent products hold no implementation |

The `agent` extension is ignored by default, so none of this fails a default bootstrap.

## Records without a keeper

- **Host thread index.** Written on each thread record write. Read and healed only by the `thread` `monitor` hook. The only caller of that hook is the `crontab` extension, which is ignored by default. With defaults, the index is written and never corrected.
- **No action prints the host index.** `thread-list` and `thread-status` read `data/threads/` only.
- **Empty files.** `asc/thread/thread.entity.yml`, `asc/thread/sidecar.able.yml`, `asc/thread/sidecar.sh` and `asc/extensions/agent/llm/llm.entity.yml` are 0 bytes. The simplify plan lists the first two kinds as removal candidates.
- **Log sidecar** records who started what and when, and nothing about the end.

## Words that disagree

- `agent-stop` unloads a model. A reader expects it to stop a run.
- Chat entry points use the variant name `chat_TYPE` (mixed case). The agent-plan plan renames it `CHAT_TYPE` on `read` and `archive` and adds `CHAT_ROLE` on `new` and `reply`.
- The README lists `data/entities/thread/` and `data/entities/queue/`. Thread records are in `data/threads/`. Nothing writes a queue.
- The README says the upgrade overwrites an instance's `AGENTS.md`. `asc/core/upgrade.sh` replaces `AGENTS.asc.md` and leaves `AGENTS.md` alone.
- The README names three skills in the mother; the tree and the upgrade list have four.
- The host thread index lives under `.local/share`; the host registry and the proposed needs inbox live under `.local/state`.
- The guidance-as-skills plan says the checkout has a `.claude/skills` link. The mother has no `.claude/` directory, and the link step in `asc/core/upgrade.sh` is commented out.
- The needs plan cites `asc/extensions/agent/skill/skill.entity.yml` and `skill/render.sh`. The mother's `agent` extension has no `skill/` directory.

## Documentation plumbing

- `asc/doc/next_steps.sh` scans `changelog/` unless told otherwise. Dated notes moved to `docs/plans/`. The generator finds nothing by default.
- Relative links in `docs/specs/asc/documentation.md` resolve one level short: `../../README.md` points at `docs/README.md`, `../plans/…` at `docs/specs/plans/…`. They read as written for `docs/specs/`.
- The same file links a legacy changelog index that is deleted in the current work tree.
- `docs/specs/asc/` is in the upgrade swap list. Every file there is copied into each instance. Links from those specs to mother plans and ideas will not resolve in an instance. A spec meant to travel should stand without them, or the links should be absolute URLs.
- Idea and plan headers come in three shapes (plain lines, bullets, a table). Specs so far use a `Status:` line; the four agent drafts use front matter. One shape per kind would help a reader and a scanner.

## Why list these

Most are the residue of designs that moved on. They matter for the tracking decision in two ways: the existing thread machinery is less alive than its file list suggests, and each fix is a chance to remove something instead of adding to it.
