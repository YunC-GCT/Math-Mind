# 0002 — "agent" terminology disambiguation

The word "agent" is overloaded in MindTrace. `CONTEXT.md` documents the four meanings. We keep the code-level names (`Agent*` classes, `agents/` module) as-is and migrate user-facing strings over time.

## Considered Options

1. **Document in `CONTEXT.md` only** *(chosen for code)*. Code keeps `AgentChatService`, `AgentFloatWindow`, etc. The disambiguation table in `CONTEXT.md` is the canonical reference.
2. **Rename user-facing strings only** *(chosen for user copy)*. `AgentFloatWindow` stays (class name), but its label / title bar reads "AI 助手" not "Agent". Toast messages say "AI helper" not "agent".
3. **Full rename** (`AgentChatService` → `AssistantChatService` etc.). Massive search-and-replace across 30+ files, plus update all import statements, plus update tests. Zero functional change, high review surface.

## Consequences

- **Chosen (1) + (2)**: minimum disruption, maximum clarity where it matters. The word "agent" still appears in code (search-friendly, low-cost to keep), but the user never sees it.
- Reject (3): the cost of a rename is high (3-day refactor across 6+ modules), and the benefit is purely cosmetic. The class names are private to MindTrace.

## Reversibility

**Hard to reverse** for the rename direction (1)→(3). Once we commit to "agent" in code, every future developer sees that word and assumes it was deliberate. Migrating away later is search-and-replace across the whole repo.

## Migration plan

Phase 1 (now): update user-facing strings (toasts, placeholders, button labels) to use "AI 助手" or "AI helper". Class names stay.

Phase 2 (Phase 4 ticket #4): consider renaming class names during the `Dispatcher` refactor — the surface area is small (≤ 6 files import AgentChatService directly).

## Related

- `CONTEXT.md` §"Ambiguous terms" — the four meanings defined
- Audit §4.18 — original discovery
- `AGENTS.md` §"API 版本注意" — references this
