# MindTrace → LangGraph Migration Plan

> **Date:** 2026-09-02
> **Scope:** What needs to change to migrate MindTrace's agent pipeline from its current custom `Dispatcher` to **LangGraph**.
> **Project:** MindTrace (`D:\HMgent\MathMind`)
> **Author:** background research agent (replaces original agent-framework-comparison-2026-09-02.md as the second half of the agent-architecture analysis)
> **Predecessor:** [agent-framework-comparison-2026-09-02.md](./agent-framework-comparison-2026-09-02.md) — established that MindTrace is **not** currently LangGraph-based.

---

## Executive Summary

| Metric | Value |
|---|---|
| Total effort | **3-5 person-weeks** (one engineer, 4-6 weeks) |
| Risk level | **Medium-High** (touch every agent code path; rewrite Dispatcher; risk of regression) |
| Recommended phasing | **Incremental** — migrate one sub-agent at a time, behind a feature flag |
| Blocking dependencies | None (LangGraph is a self-contained library) |
| Required stack decision | **Python (LangGraph)** vs **TypeScript (langgraphjs)** — see §6 |
| New docs required | 1 ADR (adopt LangGraph), 4 spec updates, 1 new spec (the new state schema) |

**Headline recommendation:** Adopt **LangGraph in Python** as a separate service. MindTrace's HarmonyOS front-end stays in ArkTS; the agent runtime moves to a Python backend that talks to ArkTS via HTTP. This isolates the rewrite and aligns with where AI/agent code naturally lives in 2026.

---

## 1. Current State (before)

MindTrace's agent pipeline is a **custom Dispatcher + sub-agent pipeline** (per [agent-framework-comparison-2026-09-02.md](./agent-framework-comparison-2026-09-02.md)).

### 1.1 Component inventory

| Component | File | Lines | Public API |
|---|---|---|---|
| Orchestrator | `agents/src/main/ets/core/Dispatcher.ets` | 159 | `analyze(req)`, `dispatch(req)`, `routeDispatch(req)` |
| Sub-agent 1 | `agents/src/main/ets/agents/TypeClassifier.ets` | 363 | `classify(payload, ctx)`, `recognizeText(payload, ctx)` |
| Sub-agent 2 | `agents/src/main/ets/agents/KnowledgeModel.ets` | 929 | `structure(ocrText, …)` (god class) |
| LLM client | `common/src/main/ets/llm/LlmClient.ets` | ~500 | `call(messages)`, `callStream(messages)`, `callSseTokens(messages)` |

### 1.2 Current data flow (per `Dispatcher.ets:97-152`)

```
AiService.capture(imageUri, userText)
  │
  ▼
new Dispatcher().dispatch(req)                   // Dispatcher.ets:97
  │
  ├─ Step 1: new TypeClassifier().recognizeText()  // Dispatcher.ets:105
  │           │
  │           └─ LlmClient.callStream()  (or callSseTokens)
  │
  ▼
recognized.text  (string)
  │
  ├─ Step 2: new KnowledgeModel().structure()       // Dispatcher.ets:129
  │           │
  │           └─ LlmClient.call()  (or callStream)
  │
  ▼
KnowledgeUnit
  │
  ▼
DispatchResult
```

**Synchronous**, **linear**, **no state machine**, **no checkpointing**, **no interrupts**.

### 1.3 What's wrong with the current setup (from a LangGraph perspective)

- No **state machine** — state is implicit in local variables
- No **checkpointing** — if `KnowledgeModel.structure` fails partway, the whole `dispatch` fails
- No **conditional routing** — every photo flows the same way
- No **HITL (Human-in-the-Loop)** — can't pause for user confirmation
- No **parallel nodes** — `TypeClassifier` and `KnowledgeModel` run strictly serially
- No **subgraph composition** — can't reuse pipelines
- No **observability** — no built-in tracing; you have to add `console.log` manually
- No **persistence** — every dispatch starts from scratch (no memory)

---

## 2. Target State (after)

A **LangGraph `StateGraph`** that mirrors the current pipeline but adds the framework features above.

### 2.1 Target architecture (in Python, behind HTTP service)

```
Frontend (ArkTS, on-device)
  │
  │  HTTP POST /dispatch
  ▼
LangGraph service (Python, runs on a server)
  │
  │  compiled graph from build_graph()
  ▼
StateGraph: ocr_text -> classify -> structure -> [conditional] -> END
                │             │              │
                ▼             ▼              ▼
            LLM call      LLM call       validate
            (subgraph)   (subgraph)     (function)
                │             │              │
                └───── State ─────────────────┘
                       (TypedDict)
```

### 2.2 Target state schema (`src/graph/state.py`)

```python
from typing import TypedDict, Optional, Literal

NoteType = Literal["概念", "定理", "公式", "证明题", "计算题"]
DispatchStep = Literal["ocr", "classify", "structure", "validate", "done"]

class AgentState(TypedDict, total=False):
    # Input (set by entry node)
    image_uri: Optional[str]
    user_text: Optional[str]
    source: str

    # Pipeline state
    ocr_text: str                  # populated by OCR node
    category: NoteType             # populated by classify node
    confidence: float
    knowledge_unit: dict           # populated by structure node

    # Metadata
    current_step: DispatchStep
    error: Optional[str]           # set on failure
    duration_ms: int
```

### 2.3 Target nodes (in `src/graph/nodes.py`)

```python
from langgraph.graph import StateGraph
from .state import AgentState

def ocr_node(state: AgentState) -> AgentState:
    """OCR / text extraction. Mirrors TypeClassifier.recognizeText()."""
    ...

def classify_node(state: AgentState) -> AgentState:
    """5-type classification. Mirrors TypeClassifier.classify()."""
    ...

def structure_node(state: AgentState) -> AgentState:
    """KnowledgeUnit construction. Mirrors KnowledgeModel.structure()."""
    ...

def validate_node(state: AgentState) -> AgentState:
    """Sanity check. Replaces KnowledgeModel's implicit validation."""
    ...

def build_graph():
    workflow = StateGraph(AgentState)
    workflow.add_node("ocr", ocr_node)
    workflow.add_node("classify", classify_node)
    workflow.add_node("structure", structure_node)
    workflow.add_node("validate", validate_node)
    workflow.set_entry_point("ocr")
    workflow.add_edge("ocr", "classify")
    workflow.add_edge("classify", "structure")
    workflow.add_edge("structure", "validate")
    workflow.add_edge("validate", "__end__")
    return workflow.compile()
```

---

## 3. Component-by-Component Migration

### 3.1 `Dispatcher` → LangGraph `StateGraph`

| Aspect | Before | After |
|---|---|---|
| Code | 159 lines of TypeScript, 3 public methods | ~50 lines of Python graph definition + entry HTTP handler |
| State | Local variables | TypedDict (typed, inspectable) |
| Persistence | None | `MemorySaver` (in-process) or `PostgresSaver` (durable) |
| Time to implement | n/a | 3-5 days (including LangGraph learning curve) |
| Risk | n/a | Medium (rewriting orchestrator) |
| Migration steps | n/a | (1) Add `src/graph/` skeleton. (2) Implement `ocr_node` as a wrapper over `TypeClassifier.recognizeText` HTTP call. (3) Add feature flag. (4) Flip flag. (5) Remove `Dispatcher.dispatch` calls. |

### 3.2 `TypeClassifier` → LangGraph `classify_node`

| Aspect | Before | After |
|---|---|---|
| Code | 363 lines of TypeScript, 2 methods | 50-line Python `classify_node` calling LLM + parsing JSON |
| State | Local variables | `state["category"]`, `state["confidence"]` |
| Reuse | Only via `Dispatcher.dispatch` | Reusable as a sub-graph in any future flow |
| Time | n/a | 2-3 days (mostly porting logic) |
| Risk | n/a | Low (sub-agent, easy to A/B) |
| Migration steps | (1) Port the JSON Schema + parse to Python. (2) Add unit tests. (3) Call from `classify_node`. |

### 3.3 `KnowledgeModel` (god class) → LangGraph `structure_node` + `validate_node`

| Aspect | Before | After |
|---|---|---|
| Code | 929 lines, 1 method (`structure`) | 2 nodes: `structure_node` (~150 lines) + `validate_node` (~50 lines) |
| State | Implicit | `state["knowledge_unit"]` |
| Reuse | None | Both nodes can be reused in any graph |
| Time | n/a | 3-5 days (per ADR-0006 + spec 003, the god class was already being broken up) |
| Risk | n/a | Medium (929 lines of behavior to preserve) |
| Migration steps | (1) Port `structure()` to Python (preserve output schema). (2) Extract `truthCheck` to `validate_node` (was inline in `KnowledgeModel`). (3) Add characterization tests. (4) Wire both nodes into the graph. |

### 3.4 `LlmClient` (3 methods) → LangChain `ChatModel`

| Aspect | Before | After |
|---|---|---|
| Code | ~500 lines of TypeScript, 3 methods | Replaced by LangChain's `ChatOpenAI` / `ChatAnthropic` / etc. |
| Streaming | Manual SSE parsing (`callSseTokens`) | Built into LangChain `ChatModel.stream()` |
| Reuse | 2 callers in MindTrace | All LangGraph nodes use it |
| Time | n/a | 1-2 days (replace TS LlmClient with `langchain.chat_models.init_chat_model`) |
| Risk | n/a | Low (well-trodden path) |
| Migration steps | (1) Add `langchain-core` + provider SDK. (2) Remove `LlmClient.ets` (or keep for legacy callers). |

---

## 4. LangGraph Concepts to Introduce

Per [agent-glossary.md](../agents/agent-glossary.md), these are universal concepts MindTrace will adopt:

| Concept | Use in MindTrace |
|---|---|
| **StateGraph** | The whole pipeline (`ocr → classify → structure → validate`) |
| **TypedDict state** | `AgentState` (see §2.2) |
| **Node** | One per pipeline stage (4 nodes) |
| **Edge (normal)** | `ocr → classify → structure → validate → end` |
| **Conditional edge** | Optional: if `validate` fails, route to a `fallback` node for retry |
| **Checkpointer** | `MemorySaver` (dev) or `PostgresSaver` (prod) — per-thread state for HITL and resume |
| **Thread** | One user photo = one `thread_id` (UUID) |
| **Command** | For HITL (e.g., user confirms a low-confidence classification) |
| **Tool** | Could replace the OCR step with a tool-call (if model supports vision) |
| **Subgraph** | Could package `ocr + classify` as a sub-graph reused in other flows |

---

## 5. Migration Strategy

### 5.1 Recommendation: **Adopt in Python as a sidecar service**

**Why Python, not langgraphjs?**
- LangGraph is Python-native; langgraphjs is less mature and has fewer integrations
- AI/agent code lives in Python's ecosystem (LangChain, LlamaIndex, etc.)
- The ArkTS front-end is presentation + I/O; the agent logic is best in Python
- This matches the current OCR service (Python FastAPI) — same operational model

**Architecture:**
```
┌────────────────────┐     HTTP     ┌────────────────────┐
│  ArkTS Frontend     │ ──────────→ │  Python LangGraph    │
│  (HarmonyOS device) │              │  Service (server)    │
│  AiService.capture() │              │  POST /dispatch      │
└────────────────────┘              └────────────────────┘
```

### 5.2 Phasing (incremental, 4-6 weeks)

**Phase 1: Foundation (1 week)**
- (a) Create `services/agent-runtime/` (new Python project)
- (b) Add LangGraph + LangChain + provider SDK
- (c) Implement `AgentState` + `build_graph()` with stub nodes
- (d) Add FastAPI endpoint `POST /dispatch` that returns the `DispatchResult`
- (e) Add unit tests for the graph

**Phase 2: One sub-agent migrated (1 week)**
- (a) Port `TypeClassifier.classify` to Python
- (b) Wire as `classify_node` in the graph
- (c) Add feature flag: `USE_LANGGRAPH_FOR_CLASSIFY=1` (calls Python, otherwise calls ArkTS)
- (d) A/B test on real data
- (e) Roll out

**Phase 3: Remaining sub-agents + main flow (1-2 weeks)**
- (a) Port `KnowledgeModel.structure` to Python (`structure_node` + `validate_node`)
- (b) Port OCR step (calls `OcrTool` HTTP)
- (c) Wire full graph
- (d) Add `MemorySaver` checkpointer
- (e) Add HITL interrupt for low-confidence classifications
- (f) Flip feature flag at 100%

**Phase 4: Cleanup (1 week)**
- (a) Remove `Dispatcher.ets`, `TypeClassifier.ets`, `KnowledgeModel.ets`, `LlmClient.ets`
- (b) Remove ADR-0003 (Dispatcher single entry) and ADR-0004 (LLMClient consolidation) — both subsumed by LangGraph
- (c) Update ADR-0006 (KnowledgeModel decomposition) — partially obsolete; keep lessons learned
- (d) Update spec 003 / 004 / 005 / 007 — all of them describe the OLD architecture
- (e) New ADR: "Adopt LangGraph for agent runtime"
- (f) New spec: "Agent state schema and graph definition"

---

## 6. Open Questions

These need user input before starting the migration:

1. **Python vs langgraphjs?** — recommendation: Python (see §5.1)
2. **Service deployment?** — alongside the OCR service? Separate? Kubernetes?
3. **Cost of LLM calls?** — current model? move to cheaper / faster? (out of scope for this research, but affects design)
4. **Persistence?** — `MemorySaver` (in-process, dev) or `PostgresSaver` (durable, prod)? — affects HITL design
5. **HITL threshold?** — when `confidence < 0.8`, pause for user confirmation? — affects UX
6. **What happens to the existing ArkTS code?** — keep as fallback, or remove entirely?
7. **Multi-language support?** — does the agent runtime need to support Chinese AND English prompts? (likely yes for MindTrace)
8. **Versioning of state schema?** — `AgentState` will evolve; how to handle old checkpoints?

---

## 7. Conclusion

MindTrace's agent pipeline is **ready for a LangGraph migration**: the current custom Dispatcher is small (159 lines) and the sub-agents are well-bounded, so the rewrite is contained. The biggest risk is the **KnowledgeModel god class** (929 lines), which needs to be split into `structure_node` + `validate_node` plus a state schema.

**Recommendation:** Adopt **LangGraph in Python as a sidecar service**, incrementally, over 4-6 weeks. Each phase is independently shippable.

**Pre-conditions for starting:** User answers the 8 open questions in §6 (especially Q1 and Q2 — Python vs langgraphjs, and service deployment).

---

## 8. Primary Source Citations

| Claim | Source |
|---|---|
| Dispatcher is 159 lines with 3 methods | `agents/src/main/ets/core/Dispatcher.ets:55, 63, 97, 155` |
| Pipeline order: `recognizeText → structure` | `agents/src/main/ets/core/Dispatcher.ets:105, 129` |
| TypeClassifier is 363 lines | `agents/src/main/ets/agents/TypeClassifier.ets` (line 1-363) |
| KnowledgeModel is 929 lines, god class | `agents/src/main/ets/agents/KnowledgeModel.ets` (line 1-929); flagged in ADR-0006 |
| LlmClient has 3 methods | `common/src/main/ets/llm/LlmClient.ets` (per spec 005) |
| MindTrace is NOT LangGraph-based | [agent-framework-comparison-2026-09-02.md](./agent-framework-comparison-2026-09-02.md) (commit daa5114) |
| Dispatcher collapse to single entry | ADR-0003 |
| LLMClient consolidation | ADR-0004 |
| KnowledgeModel decomposition | ADR-0006, spec 003 |
| LangGraph Python API | https://langchain-ai.github.io/langgraph/ (referenced for StateGraph, nodes, edges, checkpointers) |
| Agent-glossary definitions (Node, State, Edge, etc.) | `docs/agents/agent-glossary.md` |

---

## 9. Next Steps

1. User reviews this research and answers the 8 open questions in §6
2. If user approves: create new ADR "Adopt LangGraph for agent runtime" (this is the gate to start coding)
3. Phase 1 (foundation) can begin in parallel with the new ADR
4. After Phase 1: write spec "Agent state schema and graph definition" (canonical reference for all subsequent code)

This research doc is the entry point. No code is changed yet.

---

## 10. Maintenance Note

**When to update this file:**
- After each phase completes: update §5.2 with the actual effort spent
- If user answers §6 questions: update the recommendations accordingly
- If a LangGraph major version releases: re-verify the API examples
- If the existing ADRs (#3, #4, #6) are superseded: cross-link to the new ADR

**Bump file version if** any of the following change:
- Effort estimate changes by > 20%
- Phasing strategy changes (incremental → big-bang)
- New open question is answered
- A phase completes (mark ✅)

Current version: 1.0 (initial). Last updated 2026-09-02.