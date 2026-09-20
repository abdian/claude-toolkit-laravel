---
name: edges
description: List the edge cases for a feature or function before writing code, and decide which ones are actually worth handling. Writes no code.
disable-model-invocation: true
argument-hint: [what to analyze]
---

# Edge cases — $ARGUMENTS

<!--
  INSTALL: ~/.claude/skills/edges/SKILL.md
  RUN:     /edges "the order checkout form"
  WHEN:    right before writing the code, after /brief
-->

## Context
- Brief: !`cat BRIEF.md 2>/dev/null | head -40 || echo "no BRIEF.md"`

## Your job

List the edge cases for **$ARGUMENTS**, then decide which ones matter.
**Write no code.** Not a snippet, not a "you'd handle it like this."

The point of this exercise is to find the two or three cases that would
actually have bitten you, cheaply, before they cost anything.

## Walk these categories

Go through each. Skip a category with one line if it genuinely doesn't apply —
don't invent a case to fill it.

**Shape of the data**
empty · exactly one · exactly two · duplicates · already sorted · reverse
sorted · very large (10k+) · deeply nested

**Values**
zero · negative · fractional where an integer was assumed · very large number ·
precision loss · empty string · whitespace only · very long string · unicode ·
emoji · right-to-left text · quotes and separators inside a value

**Absence**
null · undefined · missing key · key present but empty · default that looks
like a real value (`0`, `""`, `false`)

**Time**
timezone boundary · daylight saving · leap year · month end · calendar system
(Jalali vs Gregorian) · clock skew · expiry exactly now

**The world failing**
network drops mid-operation · request times out · service returns 500 · service
returns 200 with an error body · rate limited · disk full · permission denied ·
file locked or deleted between check and use

**More than one actor**
two users editing the same thing · the same request sent twice · user closes
the tab mid-write · a retry arriving after the original succeeded

**Boundaries of permission**
not logged in · logged in but not allowed · was allowed, no longer is ·
someone else's record

## Output

```markdown
# Edge cases — <subject>

| # | Case | What breaks | Severity | Verdict |
|---|------|-------------|----------|---------|
| 1 | <case> | <the concrete consequence> | data loss / wrong result / crash / cosmetic | HANDLE / IGNORE |

## Handle these (<n>)
<for each: the case, and the one-line rule for handling it>

## Ignore these — and why
<for each: one line on why it is acceptable to let this fail>

## Test these (<n>)
<the subset worth an actual test, with a suggested test name>
```

## The rule that matters most

**Expect most cases to be IGNORE.** A real project does not defend against
everything, and code that does is unreadable, slow to change, and full of
branches nobody has ever executed.

A case earns HANDLE only if it is *plausible in this project* **and** the
consequence is worse than cosmetic. "A user could paste 10MB of text" is
plausible. "The system clock could be off by 40 years" is not.

Do not hedge by marking things HANDLE just in case. An honest IGNORE with a
one-line reason is more useful than a defensive HANDLE, because it tells the
next reader that the case was considered and dismissed on purpose.

## When done

Report the count of HANDLE vs IGNORE, and name the single case most likely to
have caused a real bug had you not listed it. Then:

```
▶ NEXT: implement, covering the HANDLE list. Write the tests named above.
```
