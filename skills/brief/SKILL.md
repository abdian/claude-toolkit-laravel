---
name: brief
description: Turn a rough description of what I want into a tight, testable brief before any code gets written. Works for features, scripts, and whole projects.
disable-model-invocation: true
argument-hint: [rough description, or leave blank and I'll describe it]
---

# Brief

<!--
  INSTALL: ~/.claude/skills/brief/SKILL.md
  RUN:     /brief   (then describe what you want, however messily)
  OUT:     BRIEF.md
-->

## Existing context
- Project: !`cat PROJECT.md 2>/dev/null | head -20 || echo "no PROJECT.md — run /start first if this is a new project"`
- Current brief: !`cat BRIEF.md 2>/dev/null || echo "none"`

## Your job

Turn what I tell you into `BRIEF.md`. **Write no code.** Not a sketch, not a
"here's roughly how it'd look" — none.

If `BRIEF.md` already exists and describes finished work, archive it to
`.claude/briefs/<date>-<slug>.md` before writing the new one. Briefs are worth
keeping; they explain why the code looks the way it does.

## Interview me — but only where it matters

Use **AskUserQuestion**. Ask only what would change the code. For everything
else, state your assumption in the brief and let me correct it — an assumption
I can see and reject is faster than a question I have to answer.

Good questions dig into what I probably haven't thought about:
- What happens when the input is missing, malformed, or huge?
- What should happen on failure — stop, skip, retry, or ask?
- Which existing thing should this reuse instead of building new?
- What is deliberately *not* part of this?

Bad questions: anything answerable from `PROJECT.md`, `CLAUDE.md`, the file
tree, or common sense.

Cap it at about six questions. If I gave you a detailed description already,
you may need none — say so and write the brief.

## Output: BRIEF.md

```markdown
# <short name>

**Goal** — <one sentence, from the user's point of view. Not "add a function
that…" but "so that someone can…">

**Inputs**
- <name>: <shape> — example: `<a real example value>`

**Outputs**
- <name>: <shape> — example: `<a real example value>`

**Behaviour**
- <the 3–7 rules that define correct behaviour, one line each>
- <include what happens on the failure paths, not just the happy one>

**Out of scope**
- <what we are explicitly NOT doing in this piece of work>

**Reuse**
- <existing files/components this must use rather than reinvent>

**Done means**
- <the exact command to run, or the exact thing to look at, that proves it works>
- <if it can be a test, name the test file>

**Assumptions I made**
- <anything you assumed instead of asking, so I can catch a wrong one early>
```

## Rules

**Real examples, not descriptions of examples.** `"2026-07-25T10:00:00Z"` beats
"an ISO date string". A concrete value removes an entire class of
misunderstanding.

**"Done means" is not optional and cannot be vague.** "It works correctly" is
not a done condition. "`npm test scraper.test.ts` passes" and "the CSV opens in
Excel with 4 columns and no empty rows" are. If the work genuinely cannot be
checked mechanically, name the exact thing to look at.

**Out of scope is where briefs earn their keep.** Most wasted work comes from
building something nobody asked for. Two or three lines here save hours.

**Keep it under 30 lines.** A brief longer than the code it describes is a
design document, and design documents are where scope creep is born.

## When done

Print the brief, then:

```
▶ NEXT: <the first implementation step, in one line>
   Suggested: /edges "<the riskiest part>" before writing code
```

Recommend `/edges` only when the work has real edge-case surface — user input,
external data, concurrency, dates, money, files. For something simple and
self-contained, say it isn't needed and let me start.
