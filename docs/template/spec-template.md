# Ticket NNN — {Short title}

> **Status**: spec for review (Phase 3)
> **Source ADR**: [`../adr/0006-knowledge-model-decomposition-plan.md`](../adr/0006-knowledge-model-decomposition-plan.md) — *replace with your actual ADR when copying*
> **Files affected**: {list of files}
> **Test files**: {list of test files}

## Why this ticket

{Context, the problem, the gap. Cite the ADR and audit finding if applicable.}

## What we will build

{New shape — types, classes, signatures. Use code blocks.}

## Public surface change

{What's breaking, what isn't. List affected callers.}

## Migration (atomic commits)

1. **`type(scope): summary`** — {what this commit does}
2. **`type(scope): summary`** — {what this commit does}
3. **`type(scope): summary`** — {what this commit does}

## Test plan (TDD)

| Class | New tests | What each verifies |
|---|---|---|
| `Class1` | N | ... |
| `Class2` | M | ... |

Each commit in "Migration" is independently revertable. Red → Green → Refactor.

## Reversibility

{How hard to undo. Low / Medium / High. What would reverting require?}

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] `node scripts/naming-lint/index.mjs` passes
- [ ] `node --test scripts/*/tests/*.test.mjs` all pass

## Out of scope (intentionally)

- {item 1 — not part of this ticket}
- {item 2 — separate ticket NNN}

## Open questions (none blocking)

- {Question that could be deferred}
- {Another question}

## Sequencing note

{How this ticket depends on or unblocks other tickets.}