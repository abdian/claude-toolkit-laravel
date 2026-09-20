---
name: ctx-verify
description: Test whether the generated CLAUDE.md and rules actually change behavior. Runs realistic tasks in fresh subagents with and without the context and compares. Reports which rules are dead weight.
disable-model-invocation: true
argument-hint: [optional-area-to-test]
---

# Context verification

<!-- INSTALL: ~/.claude/skills/ctx-verify/SKILL.md -->

## Current context
- Loaded files: !`ls .claude/rules/ .claude/skills/ 2>/dev/null; wc -l CLAUDE.md .claude/rules/*.md 2>/dev/null`
- Decisions: !`cat .claude/ctx/DECISIONS.md 2>/dev/null | head -80`

## Why this exists

A rule that does not change behavior is worse than no rule: it costs context,
it makes the file longer, and it makes every other rule slightly less likely to
be followed. Generating rules feels productive. Only this step tells you
whether any of it worked.

## Phase 0 — static lint (ten seconds, before any probe)

Check the cheap structural things first. A failure here explains an IGNORED
verdict without spending a single subagent:

1. **Budgets** — line counts vs the limits (CLAUDE.md 50, each rule file 30,
   max 8 rule files, each SKILL.md body 60).
2. **Globs** — every `paths:` entry is quoted. Flag unquoted ones; they break
   YAML silently and the rule never loads.
3. **References** — every rule file ends with reference-implementation paths,
   and those paths exist in the repo.
4. **Contradictions** — a rule in `.claude/rules/` that conflicts with a line
   in `CLAUDE.md`. Claude resolves these unpredictably; a human must pick one.
5. **Orphans** — generated rules with no backing decision in `DECISIONS.md`,
   and decisions that generated no rule.

Record failures directly in `VERIFY.md`. Fix globs and budget overruns before
probing — probing a file that never loads tests nothing.

## Method

For each major area in `DECISIONS.md`, build a **probe**: a small, realistic
task where a violation would be obvious and mechanically checkable.

Good probes are specific and have a wrong answer that is easy to spot:
- "Add a delivery-date field to the checkout form"
  → does it use the canonical DatePicker, or build a new one?
- "Show the order total on the receipt component"
  → does it call `formatPrice`, or format a number inline?
- "Add an endpoint that returns a user's active subscriptions"
  → does it follow the project's error envelope and validation shape?

A bad probe is one where every plausible answer passes. If you cannot state in
advance what failure looks like, the probe is useless — write a different one.

## Run the comparison

For each probe:

1. Spawn a **fresh subagent** and give it the probe with the project context
   available. Ask for the code it would write. It writes nothing to disk.
2. Spawn a **second fresh subagent** with the probe, but instruct it to ignore
   `CLAUDE.md` and `.claude/rules/` entirely. Same request.
3. Diff the two outputs against the decisions in `DECISIONS.md`.

Fresh contexts matter. Running this in the session where you wrote the rules
proves nothing — the rules are already in the conversation, so you are testing
the transcript, not the files.

Three outcomes per rule:

| Outcome | Meaning | Action |
|---|---|---|
| **WORKING** | with-context follows the rule, without-context does not | keep |
| **REDUNDANT** | both follow it — Claude does this correctly anyway | **delete the rule** |
| **IGNORED** | neither follows it | diagnose below |

REDUNDANT is not a success. Those lines are pure cost: they buy nothing and
they crowd out the rules that do work. Deleting them makes the remaining rules
more likely to be followed.

## Diagnose IGNORED rules

Work down this list in order — the causes are ordered by how common they are:

1. **File never loaded.** Run `/memory` while touching a matching file. If the
   rule is not listed, the `paths` glob is wrong or unquoted. Fix the glob.
2. **File too long.** Check line counts against the budgets. Rules get lost in
   noise long before the context window is full. Cut, then re-test.
3. **Creation vs read.** Path-scoped rules load when Claude reads a matching
   file, not reliably when it creates one. If the probe was "add a new file",
   move that rule to `CLAUDE.md`.
4. **Ambiguous phrasing.** If Claude asks you something the rule already
   answers, the wording is unclear. Rewrite it as an imperative with a concrete
   path, not a principle.
5. **Genuinely needs enforcement.** Some things a model will not reliably do
   from advice alone. Propose a hook and stop trying to fix it with words.

## Report

Write `.claude/ctx/VERIFY.md`:

```markdown
# Verification run — <date>

| Rule / file | Probe | Outcome | Action |
|---|---|---|---|

## Delete these (REDUNDANT)
<exact lines to remove, with file and line number>

## Fix these (IGNORED)
<rule, diagnosed cause from the list above, specific fix>

## Confirmed working
<the rules that earned their place>

## Context budget
| File | Lines | Budget | Status |
```

## Close honestly

End with:

1. Counts per outcome
2. **Total lines you can delete right now** — this is the headline number
3. If most rules came back REDUNDANT, say so plainly. It means the project's
   conventions are already close to what Claude does by default, and the right
   move is a much smaller context file, not a better one. That is a good
   result, not a failed run — report it as such.
