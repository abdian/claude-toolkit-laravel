---
name: debt
description: Harvest the `lazy:` shortcut markers left in the code into a ranked DEBT.md ledger, so "later" doesn't become "never". Checks each marker's ceiling against what the code does now. Makes no code changes.
disable-model-invocation: true
argument-hint: [path]
allowed-tools: Read, Write, Grep, Glob, Bash(git *), Bash(rg *), Bash(wc *)
---

# Shortcut ledger — $ARGUMENTS

<!--
  INSTALL: ~/.claude/skills/debt/SKILL.md
  RUN:     /debt                → whole repo
           /debt app/Services   → one subtree
  PAY OFF: /clear, then /fix-one DEBT.md 3
-->

## Markers in scope

- Raw hits: !`rg -n --no-heading "lazy:" -- "${ARGUMENTS:-.}" 2>/dev/null | head -60`
- Count: !`rg -c --no-heading "lazy:" -- "${ARGUMENTS:-.}" 2>/dev/null | wc -l`
- Existing ledger: !`ls -l DEBT.md 2>/dev/null || echo "none yet"`

## Ground rules — IMPORTANT

**Read-only.** Do not edit, create, or delete anything except `DEBT.md` at the
repo root. Never remove a marker from the code — a marker is deleted by the
person who actually pays the debt off, in the same commit as the fix.

**A marker is a claim, not a fact.** Each one was written when the code looked
different. Read the code the marker sits on *now* before you record it. The
useful output is not a list of comments — it's which ceilings are close.

**Do not invent debt.** Only `lazy:` markers go in the ledger. Not TODOs, not
code you personally find ugly, not things `/find-overengineering` would flag.
Wrong tool, different report.

**Preserve ticked lines.** If `DEBT.md` exists, carry every `- [x]` line over
untouched into an `## Paid` section and keep its number. Renumbering ticked
work destroys the history and breaks anything referencing an old number.

---

## Phase 1 — Collect

For every marker, record: `file:line`, the ceiling it names, the upgrade
trigger it names, and the commit that introduced it
(`git log -S` on the marker text, or `git blame -L`). A marker whose text
names no ceiling and no trigger is malformed — record it anyway, in a separate
**Malformed** section, so it gets rewritten or deleted rather than silently ignored.

## Phase 2 — Check each ceiling against reality

This is the phase that makes the ledger worth reading. For each marker, answer
in one line, with evidence:

- **Has the trigger fired?** The marker says "if this runs multi-node" / "if the
  table grows past 10k" / "if throughput matters". Look: how many rows does that
  table have per the migrations and seeders, is there a queue worker config, does
  the deploy target run more than one node? Point at the file that answers it.
- **Is the ceiling still where the marker says?** Code around it may have changed.
- **What breaks first when it's crossed?** Name the symptom: slow endpoint,
  wrong total, lost job, race on double-submit. "It won't scale" is not a symptom.

If you cannot tell whether a trigger has fired, say so — that goes in
**Open questions**, not in a guess.

## Phase 3 — Rank

Order by `(has the trigger fired?) × (how bad the first symptom is)`, not by
age and not by how big the fix is. An eighteen-month-old marker on a table that
still holds 40 rows ranks below a three-week-old one on a payment path.

## Phase 4 — Write DEBT.md

Open items are checkbox lines in this **exact** format — the same contract as
`AUDIT.md` and `COMPLEXITY.md`, so `/next` counts them and `/fix-one` ticks them:

```markdown
- [ ] #<n> UPGRADE <file:line> — <ceiling> → <what to do instead>
```

Number continuously, highest priority first. Structure, in this order:

1. **Summary** — total markers, how many have fired their trigger, how many haven't
2. **Fired** — trigger has fired; these are real work now (checkbox lines)
3. **Waiting** — correctly lazy, trigger hasn't fired (checkbox lines, lower numbers first is fine but keep them after Fired)
4. **Stale** — the code moved on and the marker no longer describes it; the fix is deleting or rewriting the comment, not the code (checkbox lines)
5. **Malformed** — no ceiling or no trigger named (checkbox lines)
6. **Paid** — carried over `- [x]` lines, untouched
7. **Open questions** — triggers you could not evaluate, and what you'd need to know

Under each checkbox line, at most two indented lines: the evidence for the
trigger verdict, and the first symptom. No more. This is a ledger, not an essay.

## Phase 5 — Close honestly

End your response with:

1. Counts per section
2. The single marker worth paying off first, and why it beats the others
3. If nothing has fired its trigger, say exactly that — a repo whose shortcuts
   are all still correctly lazy is a good result and reporting it plainly is
   the whole point of running this.
