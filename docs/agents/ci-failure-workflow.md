# CI Failure Workflow

> **Purpose:** What to do when CI fails. Covers lint, tests, builds, and other automated checks.

## When CI fails — first steps

1. **Read the failure log** — don't just look at the status icon. Click into the failed job.
2. **Identify the job that failed** — test / lint / build / etc.
3. **Find the actual error message** — usually at the bottom of the log.
4. **Reproduce locally** before fixing. Run the same command on your machine.

```bash
# Common reproductions
node scripts/naming-lint/index.mjs --json docs scripts     # lint
node --test scripts/arkts-lint/tests/*.test.mjs              # arkts-lint tests
node --test scripts/naming-lint/tests/*.test.mjs             # naming-lint tests
npm --prefix scripts/arkts-lint test                        # full arkts-lint suite
```

## By failure type

### Lint failure (naming-lint)

The most common failure.

**Symptom:**
```
FAIL: naming-lint found 3 violation(s):
  [md-kebab] (2)
    docs/some File.md
        → .md filename must be kebab-case
  ...
```

**Fix:**
1. Rename the file with `git mv` (preserves history)
2. Run `node scripts/naming-lint/index.mjs` to confirm
3. Commit

**Or** if the name is genuinely necessary (rare), add an exception to [`docs/agents/naming-exceptions.md`](./naming-exceptions.md).

### Test failure (node --test)

**Symptom:**
```
✖ test_reserved_keyword_throws (1.4ms)
  AssertionError: actual 'return DEFAULT_ENDPOINT;', expected /throw/
```

**Fix:**
1. Read the test — what is it asserting?
2. Read the implementation — what does it actually do?
3. One of:
   - **Bug in implementation** — fix the code to match the test (TDD)
   - **Test was wrong** — fix the test to match the spec (only if the test is genuinely wrong)
4. Run the test locally to confirm

### CI workflow syntax error

**Symptom:** GitHub Actions shows "YAML syntax error" or "could not find action"

**Fix:**
1. View the workflow file: `cat .github/workflows/{name}.yml`
2. Validate YAML locally: `python -c "import yaml; yaml.safe_load(open('.github/workflows/naming-lint.yml'))"`
3. Common mistakes:
   - Wrong indentation (YAML is sensitive to spaces, not tabs)
   - Unquoted strings with special characters
   - Action version typos (e.g. `actions/checkout@v4` typo)

### Approval needed (release / deploy)

**Symptom:** "Required approval" or "Manual approval needed"

**Fix:** This is by design. Find the designated approver (check `CODEOWNERS` or repo settings) and ask them to review the PR.

## Bypassing CI (don't do this)

If you genuinely need to bypass CI:

- **Bypass pre-commit hook**: `git commit --no-verify -m "..."` (local only, doesn't affect CI)
- **Bypass PR check**: Requires admin / bypass permission. Document why in the PR.
- **Push force**: Don't, unless you have very good reason and the user is informed.

**Bypassing CI should be the exception, not the rule.** If you find yourself needing to bypass often, fix the underlying problem.

## When CI is flaky

Sometimes a test passes locally but fails in CI (or vice versa). Common causes:

| Symptom | Likely cause | Fix |
|---|---|---|
| Test passes locally, fails in CI | Path issue, line-ending issue, missing dep | Reproduce in clean container; check `.editorconfig` and `.gitattributes` |
| Test fails locally, passes in CI | Time-of-day / system load | Add retry logic; check for `Date.now()` or `Math.random()` |
| Test fails for some users, not others | Locale / timezone | Use UTC everywhere; mock time |
| Files in git are CRLF in CI but LF locally | `core.autocrlf` | Set `.gitattributes` to force LF (already done) |

## When CI is broken for a long time

If CI is red for >24 hours:
1. The team should be aware. If the project has a `CODEOWNERS`, page the maintainer.
2. **Don't merge new PRs into the red branch.** Either fix CI or revert the breaking commit.
3. Use the GitHub Actions UI to identify the breaking commit (look at the first red build after a green one).

## Verifying a CI fix locally

Before pushing a CI fix:

```bash
# Run the full local test suite
node --test scripts/arkts-lint/tests/*.test.mjs
node --test scripts/naming-lint/tests/*.test.mjs
node scripts/naming-lint/index.mjs --json docs scripts | jq -e '.passed'
```

All must pass. Then push and re-trigger CI.

## Last updated

2026-09-02 (created)