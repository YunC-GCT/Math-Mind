# Naming Conventions

> **Authority:** This file is the single source of truth for all naming rules in this repo. AGENTS.md references it for hard rules. When in doubt, this file wins.
>
> **Scope:** All files — docs (`.md`), code (`.ts`/`.tsx`/`.py`/`.mjs`/`.json`/`.json5`/`.yml`), configs, and directories.
>
> **Last updated:** 2026-09-02

## 1. Universal Rules

These apply to **every** file and directory in this repo.

| Rule | Correct | Incorrect |
|---|---|---|
| **No spaces in file/dir names** | `state-graph.md` | `state graph.md` |
| **kebab-case for doc/config files and directories** | `layer-boundaries.md`, `langgraph-rules/` | `layerBoundaries.md`, `langgraph_rules/` |
| **kebab-case for code file basenames (most languages)** | `has-decorator.mjs`, `qa-chain.py` | `hasDecorator.mjs`, `qaChain.py` |
| **Date suffix is `YYYY-MM-DD`** (with dashes) | `langgraph-vs-mvp-2026-09-15.md` | `langgraph-vs-mvp-20260915.md` ❌, `langgraph-vs-mvp-2026_09_15.md` ❌ |
| **No leading numbers in doc names** (ADR/spec numbers are fine as prefix) | `001-dispatcher.md` (spec) | `2026-09-02-report.md` (unless it's a date suffix) |
| **No abbreviations that aren't widely known** | `service.ts`, `state.md` | `svc.ts`, `st.md` |
| **Renames must use `git mv`** (preserves history) | `git mv old.md new.md` | `mv old.md new.md` ❌ |

## 2. Top-level Files

| Path | Naming | Examples |
|---|---|---|
| `AGENTS.md`, `CONTEXT.md`, `README.md` | UPPERCASE single-word | — |
| Other top-level | `kebab-case` | `package.json`, `tsconfig.json` |

## 3. Documentation Files (`docs/`)

### 3.1 Path Conventions

| Type | Path | File naming |
|---|---|---|
| ADR (Architecture Decision Record) | `docs/adr/` | `NNNN-{topic-slug}.md` (4-digit seq) |
| ADR index | `docs/adr/` | `index.md` |
| Spec (implementation spec) | `docs/specs/` | `NNN-{topic-slug}.md` (3-digit seq) |
| Spec index | `docs/specs/` | `index.md` |
| Style / coding standard | `docs/style/` | `{scope}-{topic}.md` |
| Research note | `docs/research/` | `{topic-slug}-{YYYY-MM-DD}.md` |
| Architecture / audit | `docs/architecture/` | `{scope}-{YYYY-MM-DD}.md` |
| API contract | `docs/api/` | `contract.md` or `contract-{module}.md` |
| Competition / submission | `docs/competition/` | `{topic}-{YYYY-MM-DD}.md` |
| Agent workflow pointer docs | `docs/agents/` | `{topic-slug}.md` |
| Template (canonical) | `docs/template/` | `{doc-type}-template.md` |
| Legacy content (old project) | `docs/legacy/{project}/` | (preserves old naming) |

### 3.2 ADR — `NNNN-{topic-slug}.md`

- `NNNN` = 4-digit zero-padded sequence (`0001`, `0002`, …). Permanent — never renumber.
- `{topic-slug}` = kebab-case, ≤ 5 words, describes the decision, not the area.
- Example: `0001-layer-boundaries-in-5-module-arkts-app.md`

### 3.3 Spec — `NNN-{topic-slug}.md`

- `NNN` = 3-digit zero-padded sequence.
- `{topic-slug}` matches the corresponding ADR where possible.
- Example: `003-knowledge-model-decomposition.md`

### 3.4 Style — `{scope}-{topic}.md`

- `{scope}` is the framework or topic: `langgraph`, `react`, `arkts`, `python`, `naming`, etc.
- `{topic}` is `style`, `strict`, `atomic`, `hooks`, `conventions`, etc.
- Examples: `langgraph-style.md`, `react-atomic.md`, `naming-conventions.md`

### 3.5 Research — `{topic-slug}-{YYYY-MM-DD}.md`

- One research file per investigation. One date per question, not per update.
- HTML rendered version: same name + `.html` (gitignored, generated only).

### 3.6 Architecture / audit — `{scope}-{YYYY-MM-DD}.md`

- One file per audit. No re-audits under the same date.

### 3.7 Agent workflow pointer docs (`docs/agents/`)

- One topic per file: `domain.md`, `issue-tracker.md`, `triage-labels.md`, `git-conventions.md`, etc.
- Each file is **a pointer to a deeper doc or a process**, not the full content.

### 3.8 Legacy (`docs/legacy/{project}/`)

- Frozen subdirectory: old project's docs go here, no new docs added.
- The `project` name identifies the project (e.g., `mindtrace`).
- Subdirs preserve the original structure (`docs/legacy/mindtrace/adr/`, `…/specs/`, `…/research/`).

## 4. Code Files

### 4.1 TypeScript (`.ts`)

| What | Naming | Example |
|---|---|---|
| File basename | `kebab-case.ts` | `http-client.ts`, `format-date.ts` |
| Class | `PascalCase` | `class Dispatcher { … }` |
| Interface | `I` + `PascalCase` | `interface IDispatcher { … }` |
| Type alias | `T` + `PascalCase` | `type TState = …` |
| Enum | `PascalCase` | `enum Direction { … }` |
| Function | `camelCase` | `function buildPrompt() { … }` |
| Variable | `camelCase` | `const maxRetry = 3` |
| Constant | `UPPER_SNAKE_CASE` | `const MAX_RETRY = 3` |
| Test | `{name}.test.ts` (sibling) or `__tests__/{name}.test.ts` | `http-client.test.ts` |

### 4.2 React (`.tsx`)

| What | Naming | Example |
|---|---|---|
| File basename (component) | `PascalCase.tsx` | `Button.tsx`, `SearchField.tsx` |
| File basename (non-component, e.g. utility) | `kebab-case.tsx` | `layout-helper.tsx` |
| Class component | `PascalCase` extending `React.Component` | `class UserCard extends React.Component { … }` |
| Function component | `PascalCase` (function declaration) or `PascalCase` const | `function Button() { … }` or `const Button = () => { … }` |
| Hook | `use` + `PascalCase` | `useAuth.ts`, `useFetch.ts` |
| Prop type | Component name + `Props` | `ButtonProps` |
| Test | `{Name}.test.tsx` (sibling) | `Button.test.tsx` |

### 4.3 Atomic Design (React)

The frontend follows Brad Frost's Atomic Design. Each layer has a strict directory and naming:

| Layer | Directory | File naming | Examples |
|---|---|---|---|
| **Atom** | `frontend/src/atoms/` | `PascalCase.tsx` (no `Atom` suffix) | `Button.tsx`, `Input.tsx`, `Label.tsx`, `Icon.tsx` |
| **Molecule** | `frontend/src/molecules/` | `PascalCase.tsx` | `SearchField.tsx`, `FormField.tsx` |
| **Organism** | `frontend/src/organisms/` | `PascalCase.tsx` | `Header.tsx`, `UserCard.tsx` |
| **Template** | `frontend/src/templates/` | `PascalCase.tsx` | `MainLayout.tsx`, `AuthLayout.tsx` |
| **Page** | `frontend/src/pages/` | `{Name}Page.tsx` | `HomePage.tsx`, `LoginPage.tsx` |
| **Service** | `frontend/src/services/` | `{name}-service.ts` or `{name}Service.ts` (be consistent within layer) | `auth-service.ts`, `http-client.ts` |
| **Hook** | `frontend/src/hooks/` | `use{Name}.ts` | `useAuth.ts`, `useFetch.ts` |
| **Util** | `frontend/src/utils/` | `{name}.ts` | `format-date.ts` |
| **Type** | `frontend/src/types/` | `{name}-types.ts` or `{name}.ts` | `api-types.ts` |
| **Test** | sibling `*.test.tsx` | — | `Button.test.tsx` |

**Layer rules:**
- Atom: no other component dependency; single-purpose
- Molecule: composed of atoms; minimal or no state
- Organism: business logic; may have state and side effects
- Template: page skeleton with slots; no business content
- Page: route endpoint; composes template + organisms + molecules + atoms
- Service: API client / external integration (no React)

A file's directory determines its layer. **Don't put a `Page.tsx` in `atoms/`** — that would violate the layer rule.

### 4.4 Python (`.py`)

| What | Naming | Example |
|---|---|---|
| File basename | `snake_case.py` | `state_graph.py`, `retrieve_node.py` |
| Class | `PascalCase` | `class StateGraph: …` |
| Module-level function | `snake_case` | `def build_prompt() → str: …` |
| Variable | `snake_case` | `max_retry = 3` |
| Constant | `UPPER_SNAKE_CASE` | `MAX_RETRY = 3` |
| Private (module-internal) | `_` prefix | `def _helper(): …` |
| Test | `{name}.test.py` (sibling) or `tests/test_{name}.py` | `retrieve_node.test.py` |

### 4.5 LangGraph Backend

| Role | Directory | File naming | Example |
|---|---|---|---|
| State schema (TypedDict) | `backend/src/graphs/state/` | `{graph}_state.py` | `qa_state.py` |
| Node (atom) | `backend/src/nodes/` | `{verb}_node.py` | `retrieve_node.py`, `classify_node.py` |
| Node class | (same file) | `{Verb}Node` | `class RetrieveNode: …` |
| Chain (molecule) | `backend/src/chains/` | `{name}_chain.py` | `rag_chain.py` |
| Graph (organism) | `backend/src/graphs/` | `{name}_graph.py` | `qa_graph.py` |
| Service | `backend/src/services/` | `{name}_service.py` | `vector_store.py`, `llm_client.py` |
| Tool | `backend/src/tools/` | `{name}_tool.py` | `search_tool.py` |
| Checkpointer | `backend/src/checkpointers/` | `{backend}_checkpointer.py` | `postgres_checkpointer.py` |
| Test | sibling `*.test.py` | — | `retrieve_node.test.py` |

**Layer rules (mirror Atomic Design):**
- **Node (atom)**: one operation; takes/returns a `dict` (state slice)
- **Chain (molecule)**: composes 2+ nodes; a sub-graph
- **Graph (organism)**: full `StateGraph` with entry/exit; entry point of an agent

### 4.6 JavaScript / Node (`.mjs`, `.cjs`)

| What | Naming | Example |
|---|---|---|
| File basename | `kebab-case.mjs` | `parse-arkui.mjs`, `index.mjs` |
| Function | `camelCase` | `function buildRule() { … }` |
| Constant | `UPPER_SNAKE_CASE` | `const MAX_RETRIES = 3` |
| Test | `{name}.test.mjs` (sibling) | `parser.test.mjs` |

### 4.7 Configs

| Type | Naming | Example |
|---|---|---|
| `package.json` | exactly `package.json` | — |
| `tsconfig.json` | `tsconfig.json` (root), `tsconfig.{name}.json` (variant) | `tsconfig.build.json` |
| `pyproject.toml` | exactly `pyproject.toml` | — |
| `.eslintrc` family | `.eslintrc.{scope}.{ext}` | `.eslintrc.js`, `.eslintrc.react.js` |
| `vite.config.ts` | `vite.config.ts` (build-tool-specific, keep) | — |
| `*.yml` / `*.yaml` | `kebab-case.yml` | `arkts-lint.yml` |

## 5. Branches

- **Main branch**: `main`
- **Work branches**: `{prefix}/{short-description}` or `user/{user}/{topic}`
  - `feat/{topic}` — new feature
  - `fix/{topic}` — bug fix
  - `chore/{topic}` — tooling / docs
- **No direct commits to `main`** for non-trivial work.
- Branch names: `kebab-case`, no spaces, no uppercase.

## 6. Commit Messages

Conventional Commits (already covered in `docs/agents/git-conventions.md`):

| Type | When |
|---|---|
| `feat` | new feature |
| `fix` | bug fix |
| `refactor` | code change without behavior change |
| `docs` | documentation only |
| `test` | test addition/correction |
| `chore` | tooling, deps, no production change |
| `style` | formatting only |

Scope: `(scope)` is the affected module, e.g., `(frontend)`, `(backend)`, `(agents)`, `(docs)`, `(lint)`. Optional but recommended.

Example: `fix(backend): throw LlmError on reserved keyword override`

## 7. Forbidden Patterns

| Anti-pattern | Why |
|---|---|
| Spaces in file/dir names | breaks shell, npm scripts, URLs |
| `camelCase.md` in `docs/` | inconsistent with kebab-case for all other docs |
| `snake_case.md` in `docs/` | inconsistent |
| `YYYYMMDD.md` date suffix | harder to read, no separator |
| `lb.md`, `tmp.md`, `new.md` | abbreviations / generic names |
| `My Component.tsx` (space + capital in name) | breaks JSX, looks like import |
| `mv old.md new.md` (without `git`) | loses git history |
| `package-lock.json` (committed) | except where intended (`scripts/*/package-lock.json` is intentionally committed for CI reproducibility) |
| `.html` in `docs/research/` or `docs/architecture/` | HTML is a generated render, not the source — only `.md` is committed |
| `node_modules/`, `build/`, `oh_modules/`, `dist/` | always gitignored |

## 8. Validation

The `scripts/naming-lint/` tool enforces these rules in CI. Run locally:

```bash
node scripts/naming-lint/index.mjs        # exit 0 = pass, exit 1 = violations
```

Run before any commit:

```bash
node scripts/naming-lint/index.mjs && node --test scripts/naming-lint/tests/*.test.mjs
```

## 9. When to Update This File

- New framework or tool adopted (e.g., adding Go): add a code-file section
- New doc type (e.g., RFCs): add to section 3
- New forbidden pattern discovered: add to section 7
- Layer rule change (e.g., new component layer): update section 4.3 or 4.5

Update via a `docs(naming):` commit, with the diff in the body explaining why.