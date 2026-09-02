# 0003 — Dispatcher single-entry design

`agents/core/Dispatcher.ets` has three public methods: `analyze`, `dispatch`, `routeDispatch`. `routeDispatch` is dead code (zero non-test callers per audit). `analyze` leaks a pipeline step as a public API. We collapse to one public method.

## Considered Options

1. **Single `dispatch(req, opts?)` public method, internal `analyze` step** *(chosen)*. `opts` is `{ persist?: boolean, includeRawText?: boolean }`. `routeDispatch` deleted.
2. **Keep all three methods**. `routeDispatch` stays for "compatibility" (no callers), `analyze` stays because two `entry/` services call it (per audit).
3. **Split into two public APIs**: `analyze(req)` for read-only classification, `dispatch(req)` for full pipeline. Two semantic intents, two methods.

## Consequences

- **Chosen (1)**: cleanest surface. `Dispatcher` exposes one verb. The `analyze` step is reachable via `dispatch(req, { persist: false })` for the two callers that need it. `routeDispatch` deletion is uncontroversial (zero callers).
- Reject (2): `routeDispatch` is dead code; keeping it as "API surface" is misleading. `analyze` as public method encourages callers to skip persistence, which is a leaky abstraction.
- Reject (3): the `persist: false` option is a 1-line difference. Two methods for a 1-line difference is API bloat.

## Reversibility

Low. `dispatch` signature is the natural API; restoring two methods is additive. The only risk is that two existing callers (`AiService.analyzeImage`, `services/AgentChatService.captureReply`) currently call `analyze` and `dispatch` separately and need to migrate to `dispatch(req, { persist: false | true })`. ~4 line change per caller.

## Migration plan

Phase 4 ticket #4 (already in audit): collapse methods. The two callers change to:
- `dispatcher.analyzeImage(imageUri, userText)` → `dispatcher.dispatch({ kind: 'image', imageUri, userText, persist: false })`
- `dispatcher.dispatch(req)` unchanged

Tests: `agents/src/test/KnowledgeModel.test.ets` already covers the analyze path; no new tests needed if behavior is preserved.

## Related

- Audit §4.5 — original finding
- Phase 4 ticket #4 — implementation ticket
