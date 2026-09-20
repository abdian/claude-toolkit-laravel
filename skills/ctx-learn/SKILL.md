---
name: ctx-learn
description: Mine this session's corrections and propose new context rules. Run at the end of a working session. Proposes only, changes nothing.
disable-model-invocation: true
---

# What did I have to correct?

<!--
  INSTALL: ~/.claude/skills/ctx-learn/SKILL.md
  RUN:     at the end of a real working session
  OUT:     a paste-ready block. Writes nothing.
-->

## Existing decisions
!`cat .claude/ctx/DECISIONS.md 2>/dev/null | head -60 || cat CLAUDE.md 2>/dev/null | head -40 || echo "no context files yet"`

## Your job

Review **this session only**. Find every point where I redirected you:

- corrected an approach after you started
- rejected output and asked again
- repeated an instruction you had already been given
- asked you to undo something
- had to tell you about a file, command, or convention you should have known

**Propose only. Do not edit any file.** Output a block I can paste.

## For each correction

```
**What happened:** <what I asked for vs what you did, one line each>
**Rule that would have prevented it:** <one imperative line, with a real path>
**Where it belongs:** CLAUDE.md | .claude/rules/<area> | a skill | a hook
**Already covered?** <yes — phrasing problem | no — genuinely missing>
```

That last field decides everything. If `DECISIONS.md` or `CLAUDE.md` already
says this and I still had to correct you, **adding another rule will not help**.
The existing one is buried, ambiguous, or in a file that never loads. Say which
of those three it is and propose a fix to the existing rule instead of a new one.

## Routing

| The correction was about… | Goes to |
|---|---|
| something true everywhere in the repo | `CLAUDE.md` |
| something true only for certain files | `.claude/rules/<area>.md` with `paths:` |
| a multi-step procedure I keep re-describing | a new skill |
| something phrased as "always" or "never" | propose a **hook** — a rule is advice, a hook is enforcement |

## Output

```markdown
## To add to DECISIONS.md
<paste-ready entries in the DECISIONS.md format>

## To fix (existing rule not working)
<the rule, why it isn't landing, the rewrite>

## Hook candidates
<absolutes that deserve enforcement rather than advice>
```

Then remind me: after pasting into `DECISIONS.md`, run `/ctx-generate` to
rebuild, and `/ctx-verify` before trusting the result.

## Do not manufacture lessons

If I corrected you fewer than twice this session, say so and stop. Not every
session produces a rule.

A single correction is usually noise — I changed my mind, or the request was
ambiguous, or it was a one-off. Turning it into a permanent rule adds a line to
a file that has to earn every line it holds. Wait for the pattern.

The signal you are looking for is **repetition**: the same correction twice in
one session, or the same correction you know you made last week. Say explicitly
when a proposed rule is based on a single instance so I can judge it myself.
