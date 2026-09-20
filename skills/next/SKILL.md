---
name: next
description: Look at this project's state and tell me the single next thing to do. Reads brief, decisions, findings, git state, and test health.
disable-model-invocation: true
---

# What's next?

<!-- INSTALL: ~/.claude/skills/next/SKILL.md -->

## Project state
- Size: !`git ls-files 2>/dev/null | wc -l` files tracked
- Context setup: !`ls CLAUDE.md .claude/rules/ .claude/skills/ .claude/ctx/ 2>/dev/null || echo "none"`
- Work docs: !`ls BRIEF.md AUDIT.md COMPLEXITY.md DEBT.md VERIFY.md .claude/ctx/DECISIONS.md 2>/dev/null || echo "none"`
- Git: !`git status --short; git log --oneline -5`
- Open findings: !`grep -h "^- \[ \]" AUDIT.md COMPLEXITY.md DEBT.md 2>/dev/null | wc -l`
- Shortcut markers in code: !`rg -c --no-heading "lazy:" . 2>/dev/null | wc -l`
- Context freshness (newest first): !`ls -lt CLAUDE.md .claude/ctx/DECISIONS.md .claude/rules/*.md 2>/dev/null | head -6 || echo "no context files"`

## Your job

Recommend **one** next action. Not a roadmap, not a list of options — one
thing, with the exact command to run.

A list of five good options is how a person ends up doing none of them. Pick.

## How to decide

Walk these in order and stop at the first that applies.

**1. Is something broken right now?**
Failing tests, a red build, an unfinished change sitting in the working tree.
→ Fix that. Nothing else matters until the tree is green.

**2. Is there an open finding at priority "broken" or "trap"?**
→ `/clear` then `/fix-one <file> <n>`. Name the specific finding and say why
it outranks the others.

**3. Is there work in flight without a brief?**
Recent commits with no `BRIEF.md`, or a `BRIEF.md` that doesn't match what the
commits are doing.
→ `/brief`. Cheap, and it prevents the expensive kind of mistake.

**4. Does the project size justify context setup that isn't there yet?**
Use this table honestly. Do not recommend setup the project has not earned:

| Tracked files | What it needs |
|---|---|
| under ~15 | a brief and a real test. Nothing else. Say so plainly. |
| ~15–60 | a short CLAUDE.md with the commands. No rules directory yet. |
| over ~60, actively growing | the full `ctx-*` pass is now worth its cost |

→ Recommend the appropriate step, or explicitly recommend *no* setup.

**5. Are the generated files stale?**
`DECISIONS.md` is newer than `CLAUDE.md` or any rule file (check the freshness
signal above — if DECISIONS.md sits at the top of that list, someone edited
decisions and never regenerated).
→ `/ctx-generate`. The decisions changed; the rules Claude actually reads did
not. Until they match, every session runs on outdated instructions.

**6. Has the context been verified?**
`CLAUDE.md` or rules exist but no `VERIFY.md`, or `VERIFY.md` is older than the
rules it tested.
→ `/ctx-verify`. Unverified rules are unverified assumptions.

**7. Are there open findings at "slowdown" or "ugly"?**
→ `/fix-one`, highest first. But say out loud that these are optional and that
shipping the next feature may be worth more right now.

**8. Nothing above applies?**
→ Say so. Recommend writing the next feature and getting back to work.

## Rules

**Do not invent work.** If the project is in good shape, the correct answer is
"nothing — go build the next thing." Say it without hedging. A tool that always
finds something for you to do is a tool that wastes your time.

**Do not recommend more process than the size justifies.** A 200-line scraper
does not need a rules directory, and telling someone it does is bad advice
dressed up as thoroughness. Check the file count before you suggest setup.

**Be specific.** Not "review the findings" — `"/fix-one AUDIT.md 3 — the null
deref in checkout, it's the only one that loses user data."`

## Output

Exactly this, nothing more:

```
▶ NEXT: <the one action>
  Command: <exact command to paste>
  Why: <one sentence>
  Est: <rough size — minutes or hours>

Not now (and why not):
  - <thing you considered> — <one line>
  - <thing you considered> — <one line>
```

The "not now" section is the point. It tells me what I'm allowed to ignore
today, which is more useful than another list of things I should be doing.
