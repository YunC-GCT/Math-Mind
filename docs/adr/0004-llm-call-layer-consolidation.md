# 0004 — LLM call layer consolidation

`common/src/main/ets/llm/LlmClient.ets` exposes three public methods: `call` (JSON response), `callStream` (true SSE via `requestInStream`), `callSseTokens` (pseudo-stream via `request()` + manual SSE parse). They are accidental, not architectural. We collapse to one entry point with two adapters.

## Considered Options

1. **One `call(opts)` method + two adapters** *(chosen)*. `opts.stream` flag routes to `StreamingAdapter` or `JsonAdapter`. `LlmGuard` becomes an *optional* wrapper, not a separate call path. `callSseTokens` deleted.
2. **Keep three methods**. `call` for JSON, `callStream` for real SSE, `callSseTokens` for "looks like streaming but is fake" (current). Three call paths for one logical capability.
3. **Deprecate `callSseTokens` only**. Keep two methods. Smaller change, but `call` vs `callStream` duplication remains.

## Consequences

- **Chosen (1)**: one call point, two transport options selected at the call site. `LlmClient` becomes smaller (~150 lines instead of 500+). `callSseTokens` is a workaround for an old `requestInStream` limitation; it's not needed once `call` knows about streams.
- Reject (2): `callSseTokens` is misnamed (it's not real streaming, it's a delay trick). Three methods is API surface for a single logical capability.
- Reject (3): `call` and `callStream` share 90% of their code (URL construction, headers, body building, error mapping). Two methods for 90% overlap is bad factoring.

## Reversibility

**High** for 1↔2 (additive). **Hard** for 1→3 (call sites would have to be re-split). Migration: 1 commit changes the public surface; downstream callers (TypeClassifier, KnowledgeModel, AgentChatService) update to pass `stream: true | false`.

## Migration plan

Phase 4 ticket #5 (already in audit): collapse to `call(opts)`. Downstream:
- `TypeClassifier` uses `stream: false` (small JSON response)
- `KnowledgeModel` uses `stream: false` (JSON)
- `AgentChatService.realReplyStream` uses `stream: true` (the only real consumer of streaming today)

## Related

- Audit §4.1 — original finding
- arkts-lint v0.3 baseline — `callSseTokens` is *not* a flagged rule but is the dead path
- `scripts/arkts-lint/` baseline reflects 0 calls to `callSseTokens` after migration
