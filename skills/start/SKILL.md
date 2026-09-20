---
name: start
description: Front door for any new or existing project. Works out what this is, how much process it actually needs, sets up only that, and writes PROJECT.md. Run once per project.
disable-model-invocation: true
---

# Start here

<!--
  INSTALL: ~/.claude/skills/start/SKILL.md
  RUN:     once per project.  Daily driver afterwards is /next
-->

## What's already here
- Files tracked: !`git ls-files 2>/dev/null | wc -l`
- Languages: !`git ls-files 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -8`
- Stack files: !`ls package.json pyproject.toml go.mod Cargo.toml composer.json manifest.json 2>/dev/null || echo none`
- Tests exist: !`git ls-files 2>/dev/null | grep -ciE '(test|spec)\.' || echo 0`
- Existing setup: !`ls CLAUDE.md PROJECT.md BRIEF.md .claude/ 2>/dev/null || echo none`
- Git history: !`git log --oneline -5 2>/dev/null || echo "no commits"`

## If PROJECT.md already exists

Do not start over. Read it, report the current tier and phase, and tell me to
run `/next` instead. Offer to re-run the sizing only if the project has clearly
outgrown its tier — for example it was Tier 1 and now has 80 files.

## Your job

Work out how much process this project actually needs, set up exactly that
much, and write `PROJECT.md`. Then get out of the way.

**Read before you ask.** The signals above already tell you the size, the
stack, and whether tests exist. Do not ask me things you can see. Ask only
what the files cannot tell you.

## Ask me (AskUserQuestion, 2–3 questions maximum)

1. **What is this?** — offer concrete options based on what you detected:
   web app / API or service / CLI or script / browser extension / library /
   data or scraping job / something else

2. **How long does it live?** — this decides the tier more than size does:
   - one-off — I run it, I get my answer, I may never open it again
   - a few weeks — I'll come back and change it a handful of times
   - long-lived — months or years, possibly other people

3. **Only if the answer isn't obvious from the files:** what is the one thing
   that would most annoy you if it were done wrong?

Three questions is the ceiling. If you can answer one of them yourself from
the signals, skip it and state your assumption in `PROJECT.md` instead.

## Assign a tier — and be strict

| Tier | When | Set up |
|---|---|---|
| **1 — Light** | one-off, or under ~15 files | **Nothing.** A brief and one real test. |
| **2 — Medium** | a few weeks, or ~15–60 files | Short `CLAUDE.md` (commands + gotchas only). No rules directory. |
| **3 — Full** | long-lived, or over ~60 files and growing | Full `ctx-*` pass, rules, audit loop. |

**Default down, not up.** When a project sits on a boundary, pick the lower
tier. Moving up later costs one command. Moving down means deleting files you
already talked yourself into needing, which people rarely do.

For Tier 1, say plainly that this project does not need a rules directory, does
not need the context engine, and does not need an audit loop. That is the
correct answer for most scripts, and recommending setup a project has not
earned is bad advice wearing a suit.

## Set up — only what the tier calls for

**Tier 1:** write `PROJECT.md` only. Then run `/brief` for the actual work.

**Tier 2:** write `PROJECT.md`, then a `CLAUDE.md` of at most 20 lines
containing only:
- the commands I can't guess (dev, test, build, lint)
- required env vars or setup steps
- frozen or generated directories
- the "one thing done wrong" answer, as a single imperative line

Nothing else. No style section. No architecture section. Those belong to
Tier 3, and adding them here just means Claude reads past them.

**Tier 3:** write `PROJECT.md`, then hand off — tell me to run `/ctx-audit`
next if there's existing code, or `/ctx-interview` if it's greenfield. Do not
run them yourself; they are long and deserve their own session.

**For Tier 2 and 3, state the first milestone explicitly** in `PROJECT.md`:
one thin end-to-end slice — a single real flow from entry to output, runnable
or deployed — before any horizontal layer gets built out. Building layer by
layer instead of slice by slice is how a project spends three weeks with
nothing to show and an architecture designed for features that never came.

## Write PROJECT.md

```markdown
# Project

**What:** <one sentence, plain language>
**Kind:** <web app / script / extension / …>
**Tier:** <1 | 2 | 3> — <the reason, in one line>
**Phase:** SETUP
**First milestone:** <Tier 2/3: the thinnest end-to-end slice that proves it works>

## Non-goals
<product-level: features this will deliberately never have. Different from
"out of scope" in a brief — that is per-feature, this is per-project.>

## Commands
<the ones that matter, or "none yet">

## In play
<only the skills this tier actually uses>

## Deliberately not using
<the skills we are skipping, each with a one-line reason>
<e.g. "ctx-* — 9 files, conventions fit in CLAUDE.md">
<e.g. "audit-codebase — nothing to audit yet">

## Promote when
<the concrete trigger that would move this to the next tier>
<e.g. "passes 60 files, or a second person starts committing">

## Notes
<assumptions you made instead of asking; the "done wrong" answer>

---
Updated: <date> · Daily driver: `/next`
```

The **Deliberately not using** section is the most important part of this file.
It stops `/next` from suggesting the same setup every week, and it tells me six
months from now that the gap was a decision rather than an oversight.

## Report back

```
▶ THIS IS: <kind>, Tier <n>
  Why: <one line>

  Set up: <what you created, or "nothing — this project doesn't need it">
  Skipped: <what you deliberately left out>

▶ DO THIS NOW: <one command>

  After that, run /next any time you're unsure what's next.
```

One next action. Not a plan, not a checklist — the single thing to do now.
