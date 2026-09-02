# 0001 — Layer boundaries in 5-module ArkTS app

`entry/services/` may import directly from `agents/` in MindTrace. The audit (2026-09-01) flagged this as a candidate for an interface layer but recommended keeping it for now. We accept the recommendation.

## Considered Options

1. **Allow direct cross-layer imports** *(chosen)*. `AgentChatService.ets` calls `Dispatcher.dispatch()` directly. Service code couples to one specific AI implementation. Reversible by introducing an interface.
2. **Force services through `common/` interfaces**. Define `IAiService` in `common/`, have `agents/` implement it. `entry/` depends only on `common/`. Decouples layers but requires building and maintaining an interface for a single implementation.
3. **Hybrid: services use `common/` types only**. `entry/services/` can import types from `common/`, but the runtime `Dispatcher` reference stays in `agents/`. Services get type safety without runtime abstraction.

## Consequences

- **Chosen (1)**: lowest cost. No interface to design, no abstraction to maintain. Risk: if `agents/` is replaced (e.g. by a remote agent API), every service caller changes. Today only `entry/services/AgentChatService.ets` imports `agents/`; cost of change is bounded.
- Reject (2): pure abstraction has no consumer in the current architecture. The interface would exist to satisfy a future possibility, not a present problem.
- Reject (3): types from `common/` already exist; gating on type-only imports is what (1) already does for *types*. Adding a runtime rule adds friction without proportional value at current scale.

## Reversibility

Low. Adding an interface later is additive; no service code is forced to change. Migration would be `entry → common → agents` instead of `entry → agents`.

## When to revisit

If `agents/` is ever replaced (e.g. moved to a remote service, or split into multiple AI providers), or if `entry/services/` grows past 3 callers of `agents/`, the cost of no interface starts to dominate. **Threshold**: 5+ services importing `agents/` types/classes.

## Related

- `CONTEXT.md` — defines the AI Agent layer
- Audit §5 — initial discussion of deep module design
