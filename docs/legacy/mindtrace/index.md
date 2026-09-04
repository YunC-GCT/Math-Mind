# MindTrace — Legacy Docs

> **This directory is frozen.** It contains docs from the original MindTrace project (HarmonyOS ArkTS) before the agent working environment pivoted to a generic (LangGraph backend + React frontend) architecture.
>
> **Do not add new files here.** Create new docs in their canonical location per [`docs/style/naming-conventions.md`](../../style/naming-conventions.md).

## Contents

| Subdir | What was there | Count |
|---|---|---|
| [`architecture/`](./architecture/) | Audit + deep-dive from 2026-09-01 (21 findings) | 7 files (5 md + 2 html + 2 json) |
| [`plans/w3/`](./plans/w3/) | W3 era design plans (July 2026) | 19 files |
| [`plans/w4/`](./plans/w4/) | W4 era design plans (July 2026) | 4 files |
| [`research/`](./research/) | MindTrace-specific research notes (HarmonyOS / ArkUI / WebView / formula rendering) | 4 .md files |
| [`competition/`](./competition/) | Competition submission docs (鸿蒙高校创新赛 semifinal) | 2 files |
| [`api/`](./api/) | MindTrace API contract | 1 file |

Total: ~37 files (3.5 MB)

## Why archived

This content is **frozen at 2026-09-01** (the last audit date) and reflects the MindTrace project's specific architecture (HarmonyOS ArkTS, 5 modules, W4 design). The current `docs/adr/`, `docs/specs/`, and `docs/agents/` directories reflect the current project's decisions and tooling.

The audit (per `audit-full-2026-09-01.md`) identified 21 findings. Of those:
- ✅ #9 (LlmConfig throw on reserved keyword) — fixed in TDD commit
- ✅ #15 (ArkTS 铁律反例) — fixed via `docs/style/arkts-1.1.md` + lint engines
- ✅ #16 (production fixture data leak) — fixed in TDD commit
- 🟡 #1 / #3 / #4 / #5 / #7 / #10 — work items tracked in [`docs/architecture/audit-full-2026-09-01.md`](./architecture/audit-full-2026-09-01.md) §7 (file is now under `docs/legacy/mindtrace/architecture/`)

## What's NOT here

- `docs/agents/*` — generic agent workflow docs (still in `docs/agents/`)
- `docs/adr/*` — current project's ADRs (still in `docs/adr/`)
- `docs/specs/*` — current project's specs (still in `docs/specs/`)
- `docs/research/agent-framework-comparison-2026-09-02.md` — generic agent framework research (not MindTrace-specific)
- `docs/style/arkts-1.1.md` — ArkTS rules reference, still used by the `scripts/arkts-lint/` tool
- `docs/style/naming-conventions.md` — naming spec (new, applies to all future docs)
- `docs/template/*` — copy-paste templates for new docs

## If you need to reference MindTrace

- **For current project decisions**: read `docs/adr/0001-0007` and `docs/specs/003-010`
- **For the original audit**: read `architecture/audit-full-2026-09-01.md` in this directory
- **For ArkTS rules**: read `docs/style/arkts-1.1.md` (still active)