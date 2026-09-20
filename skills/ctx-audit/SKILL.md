---
name: ctx-audit
description: Scan a project and produce an inventory of context decision points — competing patterns, conventions, and gotchas — as input for /ctx-interview. Read-only, makes no rules.
disable-model-invocation: true
context: fork
background: false
argument-hint: [optional-path-to-narrow-scope]
---

# Context audit

<!-- INSTALL: ~/.claude/skills/ctx-audit/SKILL.md -->

## Repo signals
- Stack: !`cat package.json 2>/dev/null | head -50; cat pyproject.toml go.mod Cargo.toml composer.json 2>/dev/null | head -30`
- Tree shape: !`git ls-files 2>/dev/null | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn | head -30`
- Scripts: !`cat package.json 2>/dev/null | grep -A20 '"scripts"'`
- Existing context: !`ls -la CLAUDE.md .claude/ .claude/rules/ .claude/skills/ AGENTS.md 2>/dev/null`

## Your job

Produce `.claude/ctx/INVENTORY.md`. **Nothing else.** Do not write CLAUDE.md,
do not write rules, do not write skills, do not edit any source file.

Delegate the reading to Explore subagents (they are read-only, which is
exactly right for exploration) and collect their reports — but write
`INVENTORY.md` yourself in this session. Subagents explore; you record.

You are looking for **decision points**: places where the codebase does the
same job more than one way, or where a convention exists but is not written
down anywhere. You are NOT deciding which way is right. That comes later, from
a human.

If this is an empty or near-empty project (greenfield), write
`INVENTORY.md` containing only the line `GREENFIELD` plus whatever stack you
could detect, and stop. There is nothing to inventory yet.

## What to inventory

For each area below, find every distinct implementation and record:
`path | approach used | number of call sites | how recently touched`

1. **UI primitives** — buttons, inputs, modals, selects, date pickers, toasts.
   Competing implementations here are the single most common source of
   "it built it a different way again".
2. **Styling** — Tailwind / CSS modules / styled-components / inline. Which
   spacing and color values appear as raw literals vs tokens.
3. **Data fetching** — fetch / axios / react-query / server actions. Where
   errors are handled and where they are swallowed.
4. **State** — local / context / zustand / redux. Which is used where.
5. **Forms & validation** — library, where schemas live, client vs server.
6. **Dates & times** — library, timezone handling, calendar system, whether
   display and storage formats are separated.
7. **Money & numbers** — formatting helpers, integer vs float, currency and
   locale handling, where rounding happens.
8. **i18n / localization / text direction** — how strings and RTL are handled.
9. **API layer** — route shape, error envelope, validation, auth checks.
10. **Testing** — runner, where tests live, what is actually covered.
11. **Build & env** — commands that are not guessable, required env vars,
    setup steps that would trip up a newcomer.
12. **Frozen zones** — vendored code, generated files, legacy directories that
    nobody should edit.

## Output format

```markdown
# Context inventory

## Stack
<one paragraph>

## Decision points
### <area name>
| Path | Approach | Call sites | Last touched |
|------|----------|-----------:|--------------|
...
**Ambiguity:** <why a human must choose, in one sentence>
**Signal:** <which one looks newest / most used, as evidence only, not a recommendation>

## Already consistent — no decision needed
<areas with exactly one approach, listed with the path. These become rules
directly without a question.>

## Non-obvious things a newcomer would get wrong
<env vars, setup steps, gotchas, frozen directories>

## Questions I cannot answer from code
<intent-level things: which pattern is aspirational vs legacy, what is being
migrated away from, what is deliberate vs accidental>
```

## Rules

- Evidence only. Every row needs a real path. Do not generalize from one file.
- Do not recommend. The `Signal` field states an observation; it does not pick
  a winner. Picking is a human's job in `/ctx-interview`.
- Do not include areas where you found nothing. An empty section is noise.
- Keep the whole file under 200 lines. If an area has 15 competing
  implementations, report the top 5 by call sites and say how many remain.

## When done

Report to the main session: the number of decision points found, the three
areas with the most ambiguity, and this line:

> Next: run `/ctx-interview` to turn these into decisions.
