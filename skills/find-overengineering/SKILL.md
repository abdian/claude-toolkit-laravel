---
name: find-overengineering
description: Sweep a codebase for over-engineering, dead code, and needless complexity. Measures first, judges second. Produces a ranked report with a mandatory KEEP category. Makes no changes.
disable-model-invocation: true
argument-hint: [path]
allowed-tools: Read, Write, Grep, Glob, Bash(git *), Bash(rg *), Bash(wc *), Bash(find *), Bash(sort *), Bash(head *)
---

# Complexity sweep — $ARGUMENTS

<!--
  INSTALL: .claude/skills/find-overengineering/SKILL.md
  RUN:     /find-overengineering src/features
  NOTE:    the bundled /code-review only covers recently changed files.
           This one sweeps a whole tree. Use both.
-->

## Repo signals

- Longest files: !`git ls-files -- "$ARGUMENTS" | xargs wc -l 2>/dev/null | grep -v ' total$' | sort -rn | head -25`
- Total tracked files in scope: !`git ls-files -- "$ARGUMENTS" | wc -l`
- Dependencies declared: !`cat package.json 2>/dev/null | head -60`

## Ground rules — IMPORTANT

**Read-only.** Do not edit, create, or delete any file. Write findings to
`COMPLEXITY.md` at the repo root and nothing else.

**Measure before you judge.** Every finding must be backed by a count, a path,
and a line number. A finding you cannot point at with `file:line` and a number
does not go in the report. Adjectives are not evidence.

**Do not invent findings.** You were asked to look for problems, which creates
pressure to produce them. Resist it. If a category is clean, write "none found"
and move on. A report with four real findings is more useful than one with
forty speculative ones, and padding destroys the report's credibility.

**Do not propose rewrites.** For each finding, the fix must be smaller than the
problem. If removing an abstraction would take more work than living with it,
that is a KEEP, not a finding.

**No style opinions.** Naming preferences, formatting, import order, and
"I would have written this differently" are out of scope entirely. Comment
noise (signal 11) is the one exception, and only in its measured form: a
comment that restates the code is dead weight every future reader pays for.
"I'd have worded this comment differently" is still out of scope.

**Shortcut markers are not findings.** A `lazy:` marker is deliberate,
documented debt with a stated ceiling. Count them (signal 12) and hand the
verdict to `/debt`. Never list one as REMOVE or SIMPLIFY here.

---

## Phase 1 — Count (no judgment yet)

Run these measurements and record raw numbers. Do not interpret anything yet.

| # | Signal | How to measure |
|---|--------|----------------|
| 1 | Single-implementation abstractions | Every `interface`, `abstract class`, or `type` used as a contract — count its implementers. Flag those with exactly 1. |
| 2 | Pass-through wrappers | Functions whose body is a single call to one other function, with no added logic. |
| 3 | Indirection depth | For the 5 main user-facing flows, count files traversed from entry point to the code doing real work. |
| 4 | Dead exports | Exported symbols with zero importers outside their own file. |
| 5 | Dead options | Props, config keys, feature flags, and enum members that are never read. |
| 6 | Duplicate implementations | Two or more units doing substantially the same job (date formatting, currency, fetch wrappers, modals, buttons). |
| 7 | Size outliers | Files over 400 lines; functions over 60 lines; components with more than 8 props. |
| 8 | Thin dependencies | Packages in `package.json` with fewer than 3 import sites. |
| 9 | Speculative generality | Generic type params used at exactly one call site; `options` objects where every caller passes the same thing; plugin/strategy/factory structures with one registered member. |
| 10 | Defensive noise | try/catch that swallows and returns a default; null checks on values that cannot be null per the type; validation duplicated at 3+ layers. |
| 11 | Comment noise | Comments that restate the line below them; docblocks that add nothing the signature doesn't say; section banners; commented-out code; diff narration (`// added X`). Count them per file and report the worst 5 files as a ratio of comment lines to code lines. |
| 12 | Shortcut markers | `lazy:` markers in scope — count them, and count how many sit on code that has since changed (`git log -L` on the line). Do NOT judge them here: `/debt` owns that verdict. Report the count only, and point at `/debt`. |

Write the raw counts as a table at the top of `COMPLEXITY.md`. This table is
the report's foundation — everything below must trace back to a row in it.

## Phase 2 — Rank with a forced distribution

Do not produce a flat list of problems. Rank instead, so the output has shape:

1. Rank every file in scope by **ratio of structural lines to logic lines**
   (types, interfaces, wrappers, re-exports, and boilerplate vs. code that
   actually computes or renders something).
2. Report the top 5 and the bottom 5, with the ratio for each.
3. Rank the 5 main flows by indirection depth. Report depth for each.

A forced ranking must produce both ends. Reporting only the bad end means you
ranked nothing.

## Phase 3 — Judge, with a mandatory defense

Take the top 10 candidates from Phases 1 and 2. For **each one**, write all
five fields. A candidate missing any field is dropped from the report.

```
### <short title>
- Where:      file:line (and every other site, if it repeats)
- Measured:   the number from Phase 1 that flagged this
- Cost:       what this concretely makes harder — name the task
- Case FOR keeping it: the strongest honest argument to leave it alone
- Verdict:    REMOVE | SIMPLIFY | KEEP
```

The "Case FOR keeping it" field is not a formality. Write the argument a
thoughtful engineer who wrote this code would make. Consider: was it built for
a requirement that still exists? Does it isolate something genuinely volatile?
Is it load-bearing for a test suite or an external contract?

**Expect roughly a third of candidates to end up KEEP.** If none do, you are
rationalizing toward findings rather than evaluating. If nearly all do, you
picked weak candidates — go back to Phase 2 and take the next ten.

## Phase 4 — Report

**REMOVE and SIMPLIFY entries are checkbox lines in this exact format** — the
same contract as `AUDIT.md`; `/next` counts them, `/fix-one` ticks them:

```markdown
- [ ] #<n> REMOVE <file:line> — <short title>
- [ ] #<n> SIMPLIFY <file:line> — <short title>
```

Number continuously across both categories. KEEP and Healthy entries are plain
text, never checkboxes — there is nothing to do about them, and a checkbox that
should never be ticked poisons the count.

`COMPLEXITY.md` structure, in this order:

1. **Measurements** — the Phase 1 count table
2. **Rankings** — top 5 / bottom 5 with ratios; flow depths
3. **REMOVE** — dead code and abstractions with no remaining justification
4. **SIMPLIFY** — real but the fix is a reduction, not a deletion
5. **KEEP** — candidates that survived their own defense, with the reason
6. **Healthy** — what is in genuinely good shape, named specifically. Not
   flattery: point at files and say what they do well and why.
7. **Open questions** — things that look wrong but depend on intent only a
   human knows

## Phase 5 — Close honestly

End your response with:

1. Counts per verdict category
2. The single change with the best ratio of complexity removed to risk taken
3. Your confidence level, and what you could not check (runtime behavior,
   dynamic imports, reflection, anything only observable in production)
4. If the codebase is in decent shape, say so plainly. That is a valid result
   and you are expected to report it when it is true.
