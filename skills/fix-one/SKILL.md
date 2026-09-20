---
name: fix-one
description: Fix exactly one finding from a report file. Failing test first, root cause only, scope-checked, then tick the box in the report.
disable-model-invocation: true
argument-hint: "[report-file] [finding-number]"
allowed-tools: Read, Edit, Write, Grep, Glob, Bash(git *), Bash(php *), Bash(composer *), Bash(vendor/bin/*), Bash(npm *), Bash(pnpm *), Bash(yarn *)
---

# Fix one finding — $ARGUMENTS

<!--
  INSTALL: ~/.claude/skills/fix-one/SKILL.md
  RUN:     /clear  first, then  /fix-one AUDIT.md 3
  RULE:    one finding per session. Always. No exceptions.
-->

## State
- Branch: !`git branch --show-current`
- Uncommitted: !`git status --short`

## Before anything else

If the working tree is dirty, STOP. Tell me to commit or stash first. A fix
session that starts on top of unrelated changes cannot prove what it changed.

Read the report file named in $ARGUMENTS. Find the numbered finding — the
`- [ ] #<n>` checkbox line. **Work on that finding and nothing else.**
If the line is already `- [x]`, stop and say so; it was fixed in a previous
session and the report just needs reading, not re-fixing.

If you notice other problems while working — and you will — write them at the
bottom of the report under `## Spotted while fixing`. Do not fix them. Do not
mention them again in this session. Every one you touch makes this change
harder to verify and harder to revert.

## Steps

**1. Prove it first**

Write a test that fails *because of this bug*, and run it. Show me the failure
output before you change any source file.

If a test genuinely isn't possible (config, styling, build tooling), say so
explicitly and instead show me the exact command or screenshot that
demonstrates the problem. Never skip straight to the fix — a fix with no
demonstrated failure is a guess, and you will not be able to tell whether it
worked.

**2. Find the actual cause**

State in one sentence why this happens, at the level of the cause, not the
symptom. If you can't state it, you haven't found it yet — keep reading.

Forbidden: `// @ts-ignore`, `any`, empty `catch {}`, `.skip()`, widening a type
to make an error disappear, or a null check that hides why the value was null.
These make the test pass without fixing anything.

**3. Make the smallest change that works**

The fix must be smaller than the problem. If it isn't — if fixing this properly
means a refactor — stop and tell me. That is a decision for me, not a step for
you.

No new abstractions. No new dependencies. No "while I'm here". No extra error
handling for cases that can't happen.

**4. Prove it's fixed**

- The new test passes — show the output
- The rest of the suite still passes — show the output
- Typecheck and lint pass

**5. Prove you stayed in scope**

Run `git diff --stat` and show it. Every file in that list must be one of:
the file with the bug, its test, or a file the report named. Anything else
means you drifted — revert it and explain.

**6. Commit**

One commit, message referencing the finding:
`fix: <short description> (<report-file> #<n>)`

**7. Tick the box**

Update the report file: change the finding's `- [ ]` to `- [x]` and append the
commit hash to the end of the line, e.g. `… — fixed in a1b2c3d`. The report is
a living checklist, not a document. A finding that is fixed but still sitting
unticked will get "fixed" again next month.

## Report back

- What was actually wrong, in one plain sentence
- The one-line change summary
- Test output, before and after
- `git diff --stat`
- What's next by priority: broken > trap > slowdown > ugly
- Anything you added to `## Spotted while fixing`

Then remind me: **`/clear` before the next one.** Carrying this session's
context into the next fix is how a clean fix turns into a messy one.
