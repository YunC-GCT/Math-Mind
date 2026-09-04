# Pattern: Investigate a question

> **When to use:** You need to answer a question that has multiple plausible answers, and the answer affects the project's direction. Examples: "should we use framework X or Y?", "is this a real bug or expected behavior?", "what does the current code actually do?"

> **Audience:** agents + humans

## Trigger

- A new ticket or feature is being discussed, and there's a technical question blocking progress
- Code does something unexpected and you need to understand why
- A user asks "should we do X?" and the answer is non-obvious
- You need to compare options (libraries, approaches, patterns)

## When NOT to use

- The answer is "look it up in the code" (just read the code, don't write a research doc)
- The question is **a single decision** with a clear winner (use `add-new-adr.md` instead)
- The answer is purely factual and won't change (`docs/research/` for a paper-style writeup)

## Quick reference

```bash
# 1. Find related existing research
ls docs/research/
cat docs/agents/agent-glossary.md   # for term definitions

# 2. Read primary sources
# (code, official docs, GitHub issues)

# 3. Write a research note
cp docs/template/research-template.md docs/research/{slug}-{YYYY-MM-DD}.md
# Fill: Question / Method / Findings / Conclusion / Implications

# 4. Verify
node scripts/naming-lint/index.mjs
node scripts/link-check/index.mjs
```

## Full procedure

### Step 1: Define the question precisely (5 min)

Write a one-sentence question. If you can't, you don't have a research task — you have a confusion.

Examples of good questions:
- "Is MindTrace's agent framework based on LangGraph?" (verifiable)
- "What's the right way to handle <state> in a <context>?" (verifiable, scoped)
- "Why does the lint tool report 0 violations on the current repo?" (verifiable)

Examples of bad questions:
- "Should we use a different framework?" (too vague, no scope)
- "How can we improve the codebase?" (not research, it's a series of small decisions)

### Step 2: Find existing research (10 min)

Before reading anything new, check what's already known:

```bash
# Existing research notes
ls docs/research/

# Existing ADRs that might answer
ls docs/adr/

# Check if anyone has asked before
grep -r "your-question-keywords" docs/
```

If the question is already answered in an existing doc, link to it and stop. No need to re-research.

### Step 3: Identify primary sources (10 min)

Primary sources (per writing-for-agents principle):
- **Code** (`agents/src/main/ets/...`) — what does the code actually do
- **Official docs** (developer.huawei.com, langchain.com, etc.) — what the framework actually says
- **Specs / ADRs** — what the team decided previously
- **GitHub issues** — known bugs, planned features

**NOT primary sources**:
- StackOverflow answers (secondary)
- Blog posts (secondary)
- "Best practices" articles (secondary)

If you can't find a primary source, the question may be unanswerable with current info. Say so in the report.

### Step 4: Read + take notes (30-60 min)

Read sources. For each, write:
- 1-2 sentence summary
- The file:line or URL
- How it relates to the question

### Step 5: Write findings (30-60 min)

```bash
cp docs/template/research-template.md docs/research/{slug}-{YYYY-MM-DD}.md
```

Fill the template:
- **Question**: 1-3 sentences
- **Method**: which primary sources (1-2 lines)
- **Findings**: numbered list, each citing a source
- **Conclusion**: 1-3 sentences, direct answer
- **Implications**: what to do with the answer
- **Open questions**: any sub-questions raised

**Date format**: `YYYY-MM-DD` (per naming-conventions §1) — not `20260902`

### Step 6: Verify

```bash
node scripts/naming-lint/index.mjs       # research file name format correct
node scripts/link-check/index.mjs         # references resolve
```

### Step 7: Update related docs (if conclusion changes things)

- If the conclusion **changes a decision**, write an ADR or supersede an existing one
- If the conclusion **invalidates a spec**, update or delete the spec
- If the conclusion **affects ongoing work**, note in the relevant ticket

### Step 8: Commit

```bash
git add docs/research/{slug}-{YYYY-MM-DD}.md
git commit -m "docs(research): {topic-slug}"
```

## Common pitfalls

- **Don't read 10 sources and pick the one you like.** Read 2-3 PRIMARY sources, present the most authoritative answer.
- **Don't confuse correlation with causation.** "We did X, then Y happened" ≠ "X caused Y".
- **Don't extrapolate from a single data point.** "This one file has a bug" ≠ "all files have bugs".
- **Don't ignore contradictory evidence.** If source A says X and source B says not-X, investigate further or present both with rationale.
- **Don't write a 5000-word essay.** If the question can be answered in 200 words, do that. Brevity is a feature.

## Anti-patterns

- ❌ "I'll just dump everything I read into the report" — the report is for the answer, not your research process
- ❌ "I'll cite every URL I visited" — cite primary sources, not tangents
- ❌ "I won't take a position" — every research note should conclude with a position
- ❌ "I'll publish a doc per source" — one doc per question, multiple sources

## Example

See `docs/research/agent-framework-comparison-2026-09-02.md` for a worked example. It:
- Defines a clear question ("Is this LangGraph-based?")
- Cites primary sources (file:line in Dispatcher.ets, etc.)
- Presents a finding per question
- Concludes with a clear position

## Related

- [research template](../../template/research-template.md)
- [Other research notes](../../research/) for examples
- [naming-conventions spec](../../style/naming-conventions.md) §3.5 for research file naming

## Last updated

2026-09-02 (created as part of naming governance refactor)