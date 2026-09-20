---
name: explain
description: Explain what changed and why, as a self-contained HTML report. Defaults to uncommitted work; also takes a commit, a range, or the whole project. Traces every change back to the thing that asked for it, and reports the ones it cannot trace as scope findings. Writes no code.
disable-model-invocation: true
argument-hint: "[commit-ish | --staged | --project]"
allowed-tools: Read, Write, Grep, Glob, Bash(git *), Bash(wc *), Bash(rg *), Bash(php *), Bash(composer *), Bash(vendor/bin/*)
---

# Explain the change — $ARGUMENTS

## Scope

- Argument: !`echo "${ARGUMENTS:-<none — using uncommitted work>}"`
- Working tree: !`git status --short | head -40`
- Staged vs unstaged: !`git diff --cached --stat | tail -1` / !`git diff --stat | tail -1`
- Recent commits: !`git log --oneline -8`

Resolve `$ARGUMENTS` to exactly one scope and **say which one you picked**:

| Argument | Scope |
|---|---|
| *(none)* | Everything uncommitted — staged **and** unstaged |
| `--staged` | Staged only. Use before a commit |
| a commit sha, tag, or `HEAD` | That one commit |
| `a..b` | That range |
| `--project` | The whole codebase, as an orientation document |

If the working tree is clean and no argument was given, say so and stop. Do not
invent a scope to have something to write.

## Ground rules — IMPORTANT

**A change you cannot trace to a request is a finding, not a paragraph.**

This is the rule the whole skill exists for. For every changed file, you must be
able to name the thing that asked for it: a line in `BRIEF.md`, a numbered
finding in `AUDIT.md` / `COMPLEXITY.md` / `DEBT.md`, a row in `specs/`, or an
explicit instruction in the commit message. If you cannot, it goes in the scope
audit as **UNTRACED** — with the file and line count.

Do not write a plausible reason. "Refactored for clarity" and "improved error
handling" are what an untraced change looks like when someone is being polite
about it. If the only honest answer is *nobody asked for this*, that is the
answer, and it is the most useful line in the report.

**Read the diff, not the file.** You are explaining what changed, not what the
file does. A file with a two-line change gets two lines of explanation, however
large the file is.

**Never edit anything.** This skill reads and writes one HTML report. If you
spot a bug while reading, note it in the report's open questions — do not fix it.

## Phase 1 — Collect

```bash
git diff <scope> --stat
git diff <scope>
```

For `--project`, there is no diff. Map the tree instead: entry points, the
directories that hold the real logic, where the tests live, and what the build
and test commands are. Read `PROJECT.md`, `CLAUDE.md`, and `specs/README.md` if
they exist rather than inferring what they already state.

Note for later, per changed file: lines added, lines removed, and whether a
test changed alongside it.

## Phase 2 — Trace every change

Before writing anything, build the trace table. For each changed file:

| file | what changed | asked for by |
|---|---|---|

Look for the "asked for by" in this order, and stop at the first hit:

1. A numbered finding in `AUDIT.md`, `COMPLEXITY.md`, or `DEBT.md`
2. A line in `BRIEF.md` — inputs, outputs, or the done-when condition
3. A row or decision in `specs/` (name the file)
4. The commit message, when explaining a commit
5. A convention in `CLAUDE.md` or `.claude/rules/` that the change enforces

Anything left over is **UNTRACED**. Count it.

A test file changed alongside its subject traces to the same source — say so
once, do not repeat the reasoning for both.

## Phase 3 — The two views

Write both. They are genuinely different documents and neither substitutes for
the other.

**What changed for the person using this** — behaviour only. New screens, new
rules they will hit, things that used to work one way and now work another,
anything they must do differently. If a change is invisible to them, say
"no user-visible change" and move on. Never describe a class name here.

**What changed in the code** — grouped by the *reason* for the change, not by
directory. Under each reason: the files, what they now do differently, and the
one non-obvious decision a reviewer should look at. Name the trade-off that was
taken, not the one that was avoided.

## Phase 4 — Scope audit

This section is not optional and it is not a formality.

```markdown
- [ ] #<n> UNTRACED <file> (+<added>/−<removed>) — <what changed>
      nobody asked for: <what request would have justified it, if any existed>
```

Number findings continuously so `/fix-one` can take them. Then state, plainly:

- Files changed that the task required: **n**
- Files changed that nothing asked for: **n**
- Lines added vs the smallest change that would have worked — and if you think
  the diff is close to minimal, **say that**. A clean scope audit is a real
  result and you are expected to report it when it is true.

Also flag, if present:

- A new dependency (say what it does and what it replaces)
- A new abstraction with exactly one caller
- A migration — and whether it has been merged, because a merged migration is
  frozen
- Defensive code for a case that cannot occur
- Any `TODO`, stub, or commented-out block left behind

## Phase 5 — Write the report

One self-contained HTML file. No CDN links, no external fonts, no build step —
it must open from the filesystem years from now.

Filename:

| Scope | Path |
|---|---|
| Uncommitted | `reports/uncommitted-<YYYY-MM-DD>.html` |
| Staged | `reports/staged-<YYYY-MM-DD>.html` |
| A commit | `reports/<commit-subject-slugified>.html` |
| A range | `reports/<first>..<last>.html` |
| Project | `reports/project-overview.html` |

Slugify the commit subject: lowercase, non-alphanumerics to `-`, collapse
repeats, trim to 60 characters. `mkdir -p reports` first. If the file exists,
append `-2`; never overwrite a previous report.

### Document shape

In this order — the scope audit sits high on purpose, because it is the part
people skip when it is at the bottom:

1. **Header** — scope, date, commit sha or branch, one line on what this change
   set is for
2. **At a glance** — files changed, lines ±, untraced count, tests touched
3. **Scope audit** — the findings, or an explicit "nothing untraced"
4. **What changed for the user**
5. **What changed in the code** — grouped by reason
6. **Diagram** — only if it earns its place (see below)
7. **Open questions** — anything you could not resolve from the repo
8. **How this was produced** — the exact scope and commands, so the report can
   be reproduced or challenged

### Styling

Inline `<style>`, matching the toolkit's own documents:

```
paper #EAEEF2 · panel #FFFFFF · ink #14202E · muted #64748B
rule #D3DCE5 · mark #C8402F · ok #1F7A5C
Georgia for headings · Consolas/monospace for code, paths and data
```

Add `@media (prefers-color-scheme: dark)` with a dark paper, and
`@media print` that keeps it readable on paper. Set `direction: rtl` on the
body only if the project's docs are right-to-left — check `CLAUDE.md` before
assuming, and keep code blocks `direction: ltr` regardless.

### Diagrams

Add **one** inline `<svg>`, and only when the change has a shape that prose
handles badly: a request passing through new layers, a state machine that
gained a state, a data flow that changed direction, a dependency that reversed.

A diagram of two files calling each other is noise. If the change is "three
files, one reason", skip it and say nothing about skipping it. Use the same
palette. No external images.

## Phase 6 — Close honestly

End your reply — not the report — with:

1. The path to the file
2. The scope audit line: how many files nobody asked for
3. What you could not trace and why, if anything
4. If the diff was minimal and everything traced, say that plainly

Do not summarise the report in chat. The report is the deliverable; the reply
is a pointer to it plus the one number that matters.
