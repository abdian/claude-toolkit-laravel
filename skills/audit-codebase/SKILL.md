---
name: audit-codebase
description: Audit a module or the whole codebase for bugs, dead code, logic errors, and drift from project conventions. Produces a written report, makes no changes.
disable-model-invocation: true
argument-hint: [path-or-module]
allowed-tools: Read, Write, Grep, Glob, Bash(git *), Bash(php *), Bash(composer *), Bash(vendor/bin/*), Bash(npm run *), Bash(pnpm *)
---

# Codebase audit — $ARGUMENTS

<!--
  INSTALL: save as .claude/skills/audit-codebase/SKILL.md
  RUN:     /audit-codebase src/features/checkout
  THEN:    start a FRESH session to do the fixing. Never fix in this session.
-->

## Repo signals

- Changed recently: !`git log --oneline -20`
- Largest files: !`git ls-files | xargs wc -l 2>/dev/null | grep -v ' total$' | sort -rn | head -20`
- Working tree: !`git status --short`

## Rules for this audit — IMPORTANT

YOU MUST NOT edit, create, or delete any file during this audit. This run is
read-only. Produce `AUDIT.md` at the repo root and nothing else.

Report only findings you can point at with `file:line`. If you are not certain
something is a problem, put it in OPEN QUESTIONS instead of inventing a
severity for it. Do not pad the report — a short report with five real bugs is
worth more than forty speculative ones.

Do not propose architectural rewrites, new abstraction layers, new
dependencies, or "future-proofing". Propose the smallest change that fixes the
actual defect. If a finding's fix is larger than the defect, say so and stop.

## Phase 1 — Map (use subagents)

Delegate to subagents so exploration does not fill this context. For the scope
in $ARGUMENTS, have them report back:

1. Entry points and the main data flow through the module
2. Public surface: exported functions, components, routes, types
3. External dependencies and where side effects happen (network, DB, storage)
4. Which project conventions apply here — read `.claude/rules/` and `CLAUDE.md`

Write this as a short "how it works" section at the top of AUDIT.md. If your
understanding is wrong, everything below it is wrong too.

## Phase 2 — Find (still no edits)

Work through these passes separately. Do not merge them; each pass looks for a
different class of problem and mixing them causes misses.

**Pass A — Correctness bugs**
- Unhandled error paths, swallowed exceptions, `catch {}` with no handling
- Off-by-one, wrong boundary, wrong operator, inverted condition
- Race conditions, missing `await`, unhandled promise rejections
- Null/undefined reachable where the code assumes a value
- State updated from stale closures; effects with wrong dependency arrays

**Pass B — Logic that does not match intent**
- Code whose behavior contradicts its name, its comment, or its test
- Validation that lets through what it claims to block
- Edge cases the code silently gets wrong: empty list, single item, duplicate,
  zero, negative, very large, unicode, timezone boundary
- Business rules implemented in two places that disagree with each other

**Pass C — Dead and duplicated**
- Exports with no importer, branches that cannot be reached
- Two components or helpers doing the same job
- Config flags nothing reads; TODOs older than the feature they refer to

**Pass D — Convention drift**
- Files that ignore the patterns in `.claude/rules/` and `CLAUDE.md`
- Hardcoded values where a token/constant exists
- A second implementation of something the design system already provides

**Pass E — Safety**
- Secrets or credentials in code
- Injection surfaces (SQL, XSS, command), missing authorization checks
- Unvalidated input crossing a trust boundary

For each finding record: `file:line`, one line on what is wrong, one line on
why it matters in practice, and the minimal fix. Nothing else.

## Phase 3 — Report

**Every finding is exactly one checkbox line in this format** — `/next` counts
these lines and `/fix-one` ticks them, so the format is a contract, not a
suggestion:

```markdown
- [ ] #<n> <SEVERITY> <file:line> — <what is wrong, one line>
      why: <why it matters in practice> · fix: <the minimal fix>
```

Number findings continuously across all severities (#1, #2, #3…) so
`/fix-one AUDIT.md 3` is unambiguous. OPEN QUESTIONS entries are plain bullets,
not checkboxes — they are questions for a human, not work items.

Write `AUDIT.md` with findings grouped by severity, most severe first:

- **CRITICAL** — data loss, security hole, or user-facing breakage happening now
- **BUG** — wrong behavior in a reachable case
- **INCONSISTENCY** — works, but drifts from project conventions
- **DEAD** — safe to delete
- **OPEN QUESTIONS** — things that look wrong but need a human to confirm intent

Then add a **Suggested order** section: which findings to fix first, and which
ones share a root cause and should be fixed together.

State explicitly if a severity level is empty. Do not promote a lesser finding
to fill it.

## Phase 4 — Handoff

End your response with:
1. A count per severity level
2. The three findings you would fix first, and why those three
3. This reminder: fixing starts in a NEW session, one finding at a time, each
   with a failing test written first where a test is possible.
