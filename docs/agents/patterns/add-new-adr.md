# Pattern: Add a new ADR

> **When to use:** You need to record a hard-to-reverse design decision. Examples: choosing a framework, changing a public API, restructuring modules, picking a dependency.

> **Audience:** agents + humans

## Trigger

- You are about to make a change that is **hard to reverse** (renaming a class, changing a public interface, picking a library, restructuring the project tree)
- OR you see an existing decision that's confusing and you want to make the reasoning explicit
- OR you're following a spec (`docs/specs/NNN-*.md`) and the spec needs an ADR

## When NOT to use

- The change is **reversible in one commit** (renames, internal refactors) — just commit it
- It's a tactical choice (variable name, file structure) — no need for an ADR
- The decision is **already obvious** (e.g. "we use TypeScript for the frontend") — no new info

## Quick reference

```bash
# 1. Find next ADR number
ls docs/adr/ | grep -E '^[0-9]{4}' | sort -r | head -1
# (e.g. returns "0007-test-baseline-12-unit-tests.md", so next is 0008)

# 2. Copy template
cp docs/template/adr-template.md docs/adr/0008-{topic-slug}.md

# 3. Fill in the template (see "Full procedure" below)

# 4. Verify
node scripts/naming-lint/index.mjs
node scripts/link-check/index.mjs

# 5. Update AGENTS.md ticket table if P0/P1

# 6. Commit
git add docs/adr/0008-{topic-slug}.md AGENTS.md
git commit -m "docs(adr): add 0008-{topic-slug}"
```

## Full procedure

### Step 1: Identify the decision (5 min)

Answer these questions before writing:
- **What** is changing? (one sentence)
- **Why** are we doing it? (the problem or opportunity)
- **What's the alternative** we'd pick if this didn't work? (this is the "Considered Options" entry)

If you can't answer the third question, the change may not be a "decision" worth recording.

### Step 2: Copy the template (1 min)

```bash
cp docs/template/adr-template.md docs/adr/0008-{topic-slug}.md
```

The slug is kebab-case, ≤ 5 words, describes the decision, not the area.

### Step 3: Fill the sections (20-40 min)

Required sections (do NOT skip):
- **Title**: `NNNN — {Short title}`
- **Status**: pick one (`proposed` / `accepted` / `deprecated` / `superseded by ADR-NNNN`)
- **Considered Options**: 2-4 alternatives, with the chosen one marked
- **Consequences**: what happens if we adopt this — both positive and negative
- **Reversibility**: hard / medium / soft, and what reverting requires
- **When to revisit**: triggers that should make us reconsider

Optional sections (add if useful):
- **Status / migration** if the decision supersedes a previous one

### Step 4: Reference code with file:line (5 min)

Every architectural claim should cite a primary source. Examples:
- "Dispatcher is the orchestrator" — `agents/src/main/ets/core/Dispatcher.ets:55`
- "3 public methods" — `Dispatcher.ets:63, 97, 155`

If the claim is "we use X framework", the source is the dependency file, not a code file.

### Step 5: Update AGENTS.md ticket table (if P0/P1)

If this ADR resolves a P0/P1 ticket, add a row to the "已知 P0 问题" table in `AGENTS.md`:
- Ticket #, severity, problem, fix location (now `docs/adr/0008-*.md`)

### Step 6: Verify + commit (5 min)

```bash
node scripts/naming-lint/index.mjs       # name conforms
node scripts/link-check/index.mjs         # no broken links (e.g. 'Related ADR' link)

git add docs/adr/0008-{topic-slug}.md AGENTS.md
git commit -m "docs(adr): add 0008-{topic-slug}"
git log -1                              # review the commit
```

## Common pitfalls

- **Don't write the ADR after the change is merged.** Write it as part of the change, or as a separate doc-only PR. ADRs are most useful when the code is still in PR review.
- **Don't list 5 alternatives you didn't seriously consider.** 2-3 is fine, with the runner-up explicitly named.
- **Don't add generic consequences** ("this will make the codebase cleaner"). Be specific ("this will require migrating 12 callsites across 4 modules").
- **Don't use `+` to indicate positive consequences and `-` to indicate negative.** Use `**Chosen (N):**` and `**Reject (M):**` patterns. Future readers can grep for them.

## Example

See `docs/adr/0001-layer-boundaries-in-5-module-arkts-app.md` for a worked example. It covers:
- The decision (allow direct cross-layer imports)
- 3 options considered
- Consequences (low cost, reversible)
- When to revisit (5+ callers threshold)

## Related

- [ADR template](../../template/adr-template.md)
- [Other ADRs](../../adr/) for examples
- [naming-conventions spec](../../style/naming-conventions.md) §3.2 for ADR file naming
- writing-for-agents skill (built-in): for documentation principles

## Last updated

2026-09-02 (created as part of naming governance refactor)