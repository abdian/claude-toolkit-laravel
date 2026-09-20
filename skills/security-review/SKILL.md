---
name: security-review
description: Audit a Laravel codebase for exploitable security defects — broken authorization, mass assignment, injection, data exposure, unsafe uploads, and unverified external input. Produces a ranked report with a proof-of-exploit line for every finding. Makes no changes.
disable-model-invocation: true
argument-hint: "[path-or-module]"
allowed-tools: Read, Write, Grep, Glob, Bash(git *), Bash(rg *), Bash(php *), Bash(composer *), Bash(vendor/bin/*)
---

# Security review — $ARGUMENTS

## Repo signals

- Scope: !`echo "${ARGUMENTS:-app/ routes/ config/}"`
- Laravel: !`php artisan --version 2>/dev/null || echo "artisan not runnable here"`
- Debug flag: !`grep -E '^APP_DEBUG=' .env 2>/dev/null || echo "no .env readable"`
- Routes without middleware: !`grep -rn "Route::" routes/ 2>/dev/null | grep -v "middleware" | wc -l`
- Raw query surfaces: !`rg -c "DB::raw|whereRaw|orderByRaw|selectRaw|havingRaw" --glob '*.php' 2>/dev/null | head -5`
- Unescaped Blade: !`rg -c '\{!!' --glob '*.blade.php' 2>/dev/null | head -5`

## Ground rules — IMPORTANT

**Read-only.** Never edit, never "just fix this one". Write findings to
`SECURITY-AUDIT.md` at the repo root and nothing else. A security fix applied
without review is how a second hole gets opened.

**Every finding needs a reachable path.** State who can trigger it and how:
*"any authenticated user, by changing the id in the URL"*. If you cannot name
the actor and the request that reaches it, it is not a finding — it is a
hardening note, and it goes in that section instead.

**Do not invent findings.** Being asked to look for vulnerabilities creates
pressure to produce them. A clean section gets "none found" and nothing else.
Four real findings beat forty speculative ones; padding destroys the report's
credibility and buries the real ones.

**Framework defences count.** Laravel escapes Blade by default, guards CSRF on
web routes, and parameterises Eloquent queries. Do not report what the
framework already handles — report where the code **left** that protection:
`{!! !!}`, `whereRaw`, `withoutMiddleware`, a custom login that never calls
`regenerate()`.

**No severity inflation.** A missing `Content-Security-Policy` is not the same
class of problem as an IDOR. Rank by what an attacker actually gets.

**Never write an exploit.** Describe the path in one line. Do not produce a
working payload, a script, or a curl command that performs the attack.

---

## Phase 1 — Authorization (look here first)

This is where Laravel apps actually break. Work through it before anything else.

- **Controller actions with no gate.** For every non-public action: is there a
  `$this->authorize()`, a `can:` middleware, a Policy, or a Gate? List the ones
  with none.
- **IDOR through route model binding.** `Route::get('/orders/{order}')` resolves
  *any* order. Without an ownership check in the Policy, user A reads user B's
  record. Check every bound model.
- **Ownership checked in the query, or after it?** `Order::findOrFail($id)` then
  a manual `if ($order->user_id !== auth()->id())` is fragile — a later edit
  drops the check. Scoped queries are the durable form.
- **`Gate::before` masking gaps.** A super-admin short-circuit makes every
  Policy look like it works. Test the non-admin path separately.
- **Policy method missing entirely.** `Gate::allows('some-ability')` on an
  unregistered ability returns false silently — the feature looks broken, not
  insecure. But `Gate::any` and custom resolvers can invert that. Verify.
- **Mass assignment as privilege escalation.** `$user->update($request->all())`
  with `role_id` or `is_admin` in `$fillable`, or `$guarded = []`, is an
  authorization bug wearing a validation costume.

## Phase 2 — Input crossing a trust boundary

- **Validation absent or bypassed.** Any controller taking `$request->all()`,
  `$request->input()` or `$request->merge()` without a FormRequest.
- **Injection where the framework was stepped around.** `DB::raw`, `whereRaw`,
  `orderByRaw`, `selectRaw`, `havingRaw` with any request-derived value.
  Column-name injection counts: `->orderBy($request->sort)` is exploitable even
  though it looks harmless.
- **XSS.** `{!! !!}` in Blade carrying user content. `@json` into a script tag
  without escaping. `v-html` / `dangerouslySetInnerHTML` on the frontend.
- **Command and path.** `Process::run`, `exec`, `shell_exec` with user input.
  Filenames concatenated into a path — directory traversal.
- **Deserialisation.** `unserialize()` on anything that crossed the wire.

## Phase 3 — Uploads and files

- Validated by **mime and extension**, not just by what the client claimed
- Stored under `storage/` with a signed URL, **not** dropped in `public/`
- Filename generated server-side, never taken from the request
- Size limit enforced
- SVG treated as executable content, because it is

## Phase 4 — Authentication and session

- **Rate limiting** on login, OTP request, OTP verify, password reset. Missing
  throttle on an SMS-backed OTP is both a security hole and a bill.
- **Token comparison** with `hash_equals`, never `==`. String comparison leaks
  timing.
- **Session regenerated on login.** Laravel's own `attempt()` does it; a
  hand-rolled login often does not.
- **Password reset tokens** never logged, never in a URL that lands in an
  access log or a Referer header.
- Remember-me and API tokens hashed at rest, not stored in plaintext.

## Phase 5 — What leaks

- **API Resources returning the whole model.** `$this->resource->toArray()`
  ships every column, including the ones added by a later migration.
- **`$hidden` unset** on models holding tokens, secrets, or internal ids.
- **`APP_DEBUG=true`** anywhere that is not a developer's laptop. A stack trace
  is a map of the application.
- **PII in logs.** National id, phone, full address, card data — in `Log::info`,
  in an exception context array, or in a queue payload.
- **Queue payloads.** A Job serialised to Redis or the database carries its
  constructor arguments. A secret passed into a Job is a secret at rest.
- Secrets committed: `.env` in git, credentials in `config/*.php` defaults.

## Phase 6 — External services

Relevant to every integration in `specs/INTEGRATIONS.md`:

- **Inbound webhooks verified.** A payment callback without signature
  verification lets anyone mark an order paid. This is the single highest-value
  finding in most payment integrations — check it explicitly and say so either
  way.
- **Outbound calls have a timeout.** `Http::` with no `timeout()` hangs a worker.
- **Responses validated before use.** An external service returning `200` with
  an error body, or a changed shape, must not flow into a model unchecked.
- Credentials in `config/services.php` reading from env, never literal.

---

## Phase 7 — Report

**Every finding is exactly one checkbox line in this format** — `/next` counts
these and `/fix-one` ticks them, so the format is a contract:

```markdown
- [ ] #<n> <SEVERITY> <file:line> — <what is wrong, one line>
      reachable by: <who, and through what request>
      impact: <what the attacker gets> · fix: <the minimal fix>
```

Number continuously across all severities so `/fix-one SECURITY-AUDIT.md 3` is
unambiguous. Write `SECURITY-AUDIT.md` grouped by severity, worst first:

- **CRITICAL** — unauthenticated access to data or actions, remote code
  execution, credential disclosure, payment state an attacker can set
- **HIGH** — authenticated user reaching another user's data or actions;
  privilege escalation; injection with real reach
- **MEDIUM** — exploitable only with unusual preconditions, or leaking data of
  limited value
- **HARDENING** — no known path today, but the protection is missing and a
  future edit would open it. Not vulnerabilities. Keep them separate.
- **OPEN QUESTIONS** — things that look wrong but depend on intent only a human
  knows. Plain bullets, not checkboxes.

Then a **Suggested order**: which to fix first, and which share one root cause
and should be fixed together. A missing Policy that explains six findings is one
fix, not six.

State explicitly if a severity is empty. Never promote a lesser finding to fill
a level.

## Phase 8 — Close honestly

End your reply with:

1. Counts per severity
2. The single finding you would fix before anything else, and why
3. **What you could not check**, explicitly: runtime configuration, the web
   server, TLS, infrastructure, secrets in the deployment environment,
   dependency CVEs unless you ran an audit, and anything only observable in
   production
4. If the code is in good shape, say so plainly. That is a valid result and you
   are expected to report it when it is true.

Add one line naming what this review is **not**: it is a code read, not a
penetration test, and it does not replace one for anything handling money or
identity.
