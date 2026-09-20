---
name: ctx-interview
description: Interview me about this project's conventions and write DECISIONS.md. Works for existing projects (reads INVENTORY.md) and greenfield ones. Asks only what cannot be read from code.
disable-model-invocation: true
argument-hint: [optional-area-to-focus-on]
---

# Context interview

<!-- INSTALL: ~/.claude/skills/ctx-interview/SKILL.md -->

## Inputs
- Inventory: !`cat .claude/ctx/INVENTORY.md 2>/dev/null || echo "NO INVENTORY — run /ctx-audit first, or treat this as greenfield"`
- Existing decisions: !`cat .claude/ctx/DECISIONS.md 2>/dev/null || echo "none yet"`

## Your job

Interview me using the **AskUserQuestion** tool, then write
`.claude/ctx/DECISIONS.md`. Write no other file. Do not generate CLAUDE.md,
rules, or skills — `/ctx-generate` does that from your output.

## Interview rules — IMPORTANT

**Never ask what you can read.** If the inventory shows exactly one date
library across 40 call sites, that is already a decision. Record it and move
on. Every question you ask that the code already answered wastes my time and
trains me to stop reading your questions carefully.

**One decision per question.** Offer 2–4 concrete options with the real paths
or library names from the inventory as the labels, not abstract descriptions.
Bad: "How should styling work?" Good: "Which is the canonical button?" with
options `ui/Button.tsx (31 uses)`, `common/Btn.tsx (4 uses)`, `both — they
serve different purposes`.

**Ask about intent, not preference.** The useful questions are the ones only I
can answer: which of two patterns is aspirational vs legacy, what is being
migrated away from, what is deliberate vs accidental, what must never change.

**Dig into the hard parts.** Do not ask obvious questions. Ask the ones I
probably have not thought about: what happens at the boundary, what is out of
scope, what would you be angry to find in a PR.

**Batch by area.** Group questions so I answer one topic at a time. Confirm
what you concluded from each area before moving to the next.

**Stop when you stop learning.** When the remaining questions would not change
a single generated rule, stop. Do not pad to feel thorough. Tell me you are
done and why.

## If GREENFIELD

There is no code to read, so ask more and assume less. Cover in this order:
stack and framework; what the project actually is; the three or four UI
primitives that will exist; styling approach; data layer; how errors surface;
what "done" means (test? typecheck? screenshot?); and the one thing I would be
most annoyed to see done wrong.

Keep it to about a dozen questions. A greenfield project does not need a
40-rule constitution on day one — it needs enough to start consistently, and
`/ctx-learn` will grow the rest from real mistakes.

## Always ask these, regardless of project

They are never answerable from code and they are the highest-value rules:

1. **Frozen zones** — what must never be edited or extended?
2. **Ask-first triggers** — what should I stop and ask about rather than
   decide? (new dependency, new abstraction, DB migration, changing a public
   contract...)
3. **Definition of done** — the exact commands that must pass before you
   consider a task finished.
4. **The recurring annoyance** — what does an AI assistant keep getting wrong
   in this project that you have to correct by hand?

Question 4 is the most valuable one in this file. Ask it last, when I am
already thinking about the project, and follow up on the answer.

## Output: DECISIONS.md

```markdown
# Context decisions
<!-- SOURCE OF TRUTH. Edit this file, then re-run /ctx-generate. -->
<!-- Do not hand-edit generated rules — they get overwritten. -->

Last updated: <date>

## <area>
- **Decision:** <what was chosen>
- **Rejected:** <what lost, and its status: legacy / frozen / being migrated>
- **Reference:** <path to the file that shows the pattern>
- **Rationale:** <only if non-obvious. Otherwise omit — do not pad.>
- **Source:** interviewed | inferred-from-code

## Frozen zones
## Ask-first triggers
## Definition of done
## Known annoyances
```

Mark every entry `interviewed` or `inferred-from-code`. When I later disagree
with a rule, that field tells us instantly whether the engine guessed or I
actually said it.

## When done

Report: how many decisions were captured, how many came from the interview vs
inferred from code, and anything you deliberately left undecided and why. Then:

> Next: run `/ctx-generate` to build the context files.
