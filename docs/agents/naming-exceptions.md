# Naming Exceptions Workflow

> **Purpose:** How to add or remove an exception to the naming spec (`docs/style/naming-conventions.md`) without breaking the rule.

## When you need an exception

Three cases:

1. **Third-party file you cannot rename** — e.g. a vendored dependency uses a different convention
2. **Legacy file pending migration** — already-named file, scheduled to be renamed but not yet
3. **Generated file with non-conformant upstream name** — e.g. schema-codegen output that must match an external name

For all other cases, fix the file rather than exempt it.

## How to request an exception

1. Open a PR with:
   - The file rename (or stay-as-is for cases 1-3)
   - An entry added to `docs/agents/naming-exceptions.md` (this file) under the right category
   - A short justification (one or two sentences)

2. PR title format: `exemption(<scope>): allow <pattern> because <reason>`

   Examples:
   - `exemption(python): allow .pyi stubs in stubs/ because Pyright convention`
   - `exemption(legacy): docs/legacy/mindtrace/* because frozen historical archive`

3. The PR must be reviewed by the spec owner (currently whoever owns `docs/style/naming-conventions.md`).

## Current exceptions

### Third-party (cannot rename)

| Path / Pattern | Reason | Date added | Owner | Expires |
|---|---|---|---|---|
| _none_ | | | | |

### Legacy (pending migration)

| Path | Reason | Migration ticket | Date added | Expires |
|---|---|---|---|---|
| `docs/legacy/mindtrace/**` | Frozen historical archive (MindTrace project) | (none — never migrating) | 2026-09-02 | never |

### Generated (must match upstream)

| Path / Pattern | Reason | Date added | Owner | Expires |
|---|---|---|---|---|
| _none_ | | | | |

## How to remove an exception

When the underlying reason is resolved:

1. Rename the file (if applicable) to follow the spec
2. Remove the entry from this file in the same commit
3. The `scripts/naming-lint/index.mjs` no longer needs the skip rule

## When exceptions are NOT allowed

You may NOT add an exception for:

- New files (use the spec)
- Files you have permission to rename (just rename them)
- A whole directory (be specific — per-file exceptions only)
- Linting convenience ("I'm too lazy to rename this") — fix the file

## The exception process as a state machine

```
[valid file] --request exemption--> [review] --approve--> [exempt + entry added]
                                |
                                +--reject--> [fix the file, no entry]
[exempt]   --fix applied-------> [valid file, entry removed]
```

If you're unsure whether your case warrants an exception, **default to fixing the file**. The bar is high.

## Last updated

2026-09-02 (created)