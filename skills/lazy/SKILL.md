---
name: lazy
description: Set how aggressively the ladder in CLAUDE.md is enforced — lite, full, ultra, or off. Writes the level into CLAUDE.md so it survives the session. No argument reports the current level.
disable-model-invocation: true
argument-hint: "[lite|full|ultra|off]"
allowed-tools: Read, Edit, Grep
---

# Simplicity level — $ARGUMENTS

<!--
  INSTALL: ~/.claude/skills/lazy/SKILL.md
  RUN:     /lazy            → report current level
           /lazy ultra      → switch
  NEEDS:   a CLAUDE.md carrying a "## Simplicity level" section
           (both templates in this toolkit ship one)
-->

## Current state

- Level line: !`grep -n "^Level:" CLAUDE.md 2>/dev/null || echo "MISSING"`
- Ladder present: !`grep -c "^## The ladder" CLAUDE.md 2>/dev/null || echo 0`

## What to do

**No argument given** → report the current level and the one-line description of
what it means from the table in `CLAUDE.md`. Change nothing. Stop.

**Argument given** → it must be exactly one of `lite`, `full`, `ultra`, `off`.
Anything else: say so, list the four, change nothing.

1. If the level line is `MISSING`, do not invent a place for it. Say that
   `CLAUDE.md` has no `## Simplicity level` section, show the block to paste
   (level line + the four-row table from the toolkit template), and stop.
2. Otherwise edit that one line to `Level: **<new>**`, keeping the trailing
   comment intact. **One line changes. Nothing else in the file.**
3. Confirm in one line: `full → ultra`. No summary of what ultra means unless
   the level actually changed and I haven't seen it this session.

## The levels

| Level | Behaviour |
|-------|-----------|
| **lite** | Build what was asked, then name the lazier alternative in one line. The user picks. |
| **full** | The ladder enforced. Framework and stdlib before custom code. Shortest working diff. Default. |
| **ultra** | YAGNI extremist. Deletion before addition. Ship the one-liner and challenge the rest of the requirement in the same reply. |
| **off** | Ladder suspended. Scope discipline, conventions, and correctness rules still apply — `off` is not permission to over-build, it just stops the questioning. |

## Ground rules

- **Never** edit any file other than `CLAUDE.md`, and never more than that one line.
- Never commit. The level is a working preference, the user commits it if they want it.
- `off` does not disable the "Correctness — do not fabricate", "Scope discipline",
  or "Definition of done" sections. Say so if the user seems to expect that.
