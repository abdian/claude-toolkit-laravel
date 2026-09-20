---
name: plan-check
description: Review an implementation plan against the brief and the simplicity rules before any code is written. Flags scope creep and over-engineering at the cheapest moment to fix them. Writes no code, changes nothing.
disable-model-invocation: true
argument-hint: [paste the plan, or leave blank if it's already in this conversation]
---

# Plan check — $ARGUMENTS

<!--
  INSTALL: ~/.claude/skills/plan-check/SKILL.md
  RUN:     in a FRESH session: /clear → /plan-check → paste the plan
  WHY FRESH: the session that wrote the plan inherited your biases and its
             own. A reviewer who was in the room approves the room's plan.
  WHEN:    after plan mode, before implementation. Tier 2 and up.
-->

## Context
- Brief: !`cat BRIEF.md 2>/dev/null || echo "no BRIEF.md — judge against what the user states instead"`
- Project rules: !`cat CLAUDE.md 2>/dev/null | head -60 || echo "no CLAUDE.md"`
- Project: !`cat PROJECT.md 2>/dev/null | head -25 || echo "no PROJECT.md"`

## Your job

Judge the plan. **Write no code. Edit no file. Do not "improve" the plan by
rewriting it** — report what you found and let the human decide.

Your value is distance: you were not in the conversation where this plan grew,
so you have no attachment to any part of it. Use that.

## Walk every step of the plan

**1. Scope** — does each step trace back to a line in the brief? A step that
traces to nothing is scope creep, however sensible it sounds on its own.

**2. Speculative structure** — new interfaces, base classes, factories,
plugin points, config options, event buses, or generic parameters with exactly
one concrete use in this plan. Name each, and say what the plan looks like
without it.

**3. Dependencies** — for every new package: what does it buy over what the
project already has? "Popular" and "might need it later" are not answers.

**4. Defensive weight** — error handling for states that cannot occur,
validation repeated at more than one layer, retries around things that never
transiently fail.

**5. Size** — could a competent developer do this in fewer steps, fewer files,
or fewer layers? Sketch the smaller shape in two or three lines. If nothing
smaller would work, say so plainly — that is a finding too.

**6. The missing piece** — the one realistic failure or edge case the plan
does not mention. Exactly one. Naming ten is hedging, not reviewing.

## Verdict

```
▶ VERDICT: GO | TRIM | RETHINK

GO      — proportionate to the brief. Start building.
TRIM    — right shape, remove these first:
          1. <item — one line>
          2. <item — one line>
RETHINK — solves a different problem than the brief describes.
          <one line on the mismatch>
```

## Rules

Cap findings at five, ranked by cost. Six small nitpicks bury the one
structural problem.

If the plan is good, say GO in one line and stop. A reviewer who always finds
something is a reviewer nobody reads — and inventing objections to look
thorough is its own kind of over-engineering.

Do not judge style, naming, or formatting. Only scope, structure, and size.
