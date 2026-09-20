---
name: laravel-blue-team-review
description: >-
  Defensive (blue team) review of Laravel PHP backend projects. Detect unsafe and
  non-maintainable practices - SQL injection via raw queries, mass assignment, missing
  authorization, N+1 queries, unescaped Blade output, committed secrets, insecure config,
  weak authentication/session handling, unsupported Laravel versions - and produce a
  severity-ranked remediation report readable by product owners and security engineers.
  Use when the user asks to audit a Laravel app, review PHP/Laravel code for bad
  practices, run a defensive security review of a Laravel backend, or get Laravel
  findings classified by priority. Triggers: laravel, php, blue team, defensive, code
  review, best practices, vulnerable, vuln, audit, securite.
compatibility: opencode, claude
metadata:
  read-only: "true"
  target: "laravel-php-backend"
  asvs-adjacent: "false"
---

# Laravel Blue Team Review

Defensive (blue team) review of a **Laravel (PHP) backend** codebase: find poor, unsafe,
and non-maintainable practices, rank them by risk, and recommend project-local fixes. The
audit is **read-only**; its only artefact is a Markdown report.

Use this skill for Laravel apps specifically. For a broader web-security audit against the
OWASP ASVS, use the `audit-owasp-asvs` skill instead.

## 1. Hard operational rules (non-destructive)

Identical to the `audit-owasp-asvs` skill. Never break these:

- **Read-only inspection only.** Use read/find tools (read, list, glob, grep) and
  read-only shell commands (`ls`, `rg`, `git log`, `git show`, `git status`,
  `git diff`, `find`). Do **not** use edit, write, move, delete, or patch tools on
  project files.
- **Never run the application.** No `php artisan` commands, `composer install/update`,
  `phpunit`, `npm run`, `docker compose`, or project scripts. Do **not** install packages
  or run migrations. Static review only.
- **No network activity against the target.** Do not `curl`/`wget`/probe the app, its
  API, or its hosts. No active scanning or exploitation.
- **No side effects.** Do not start servers/daemons/background jobs. Do not touch the
  `.git` index (`git add`/`commit`/`reset`).
- **Secrets handling.** If credentials/keys are found, do **not** log or reproduce the
  full value; record `file:line` and the secret type.
- **Report is the only artefact.** Write the report as a **new** Markdown file (default
  `reports/laravel-blue-team-review-<yyyy-mm-dd>.md`), never overwriting existing files.
  If unsure about the path, present the report in chat first.

If a requested action would violate a rule, refuse and explain which rule blocks it.

## 2. What this skill checks

Seven domains of Laravel-specific bad practices. The full checklist with detection
patterns, CWE references, and fixes lives in
`references/laravel-checklist.md` - use it as the authoritative catalog:

| Domain | Focus |
|--------|-------|
| **LB-SEC** Secure Coding & Injection | Raw SQL (`DB::raw`, `whereRaw`, `selectRaw`, `orderByRaw`), string-built queries, mass assignment, SSRF, command injection, unsafe file uploads, `env()` misuse. |
| **LB-AUTHZ** Authorization | Missing policies/gates, unguarded routes, IDOR (user-supplied ids), admin-only operations without checks. |
| **LB-XSS** Output & Client-side | Unescaped Blade `{!! !!}` , unvalidated output to JS, missing `e()` on user data. |
| **LB-CONF** Secrets & Configuration | Committed `.env`, hardcoded secrets, `APP_DEBUG=true`, weak cookie/session config, unset `APP_KEY`. |
| **LB-DATA** Data, Storage & Performance | N+1 queries, sensitive data at rest in plaintext, public storage exposure, unbounded queries. |
| **LB-AUTHN** Auth & Session | Weak password hashing, missing rate limiting, CSRF disabled, missing session regeneration. |
| **LB-APP** API, Application & Dependencies | Unprotected API routes, no throttle, no transactions, unsupported Laravel/PHP versions, missing `composer.lock`. |

## 3. Severity and priority model

Every finding gets a priority **P0-P3**, findings sorted P0 -> P3 in the report.

| Priority | Label | Typical conditions |
|----------|-------|--------------------|
| **P0** | Critical | Remote exploitation without auth: SQL/command injection, SSRF, exposed secrets, unsupported Laravel (**EOL, no security patches**), mass assignment leading to privilege escalation. |
| **P1** | High | Exploitable with a precondition: IDOR/IDOR-style object access, broken authorization on sensitive operations, XSS on sensitive surfaces, debug enabled in prod, weak password hashing, CSRF disabled. |
| **P2** | Medium | Defense-in-depth / hardening: missing rate limiting, no CSRF on forms, insecure cookie flags, N+1 on hot paths (performance/DoS-ish), sensitive data plaintext at rest in non-critical tables, dependency hygiene (Laravel 12 security-only). |
| **P3** | Low | Quality/maintainability only: N+1 on cold paths, missing transactions, no Form Request classes, minor logging issues. |

Adjust by likelihood x impact in the actual context; add the domain ID and, where
relevant, the CWE next to each finding.

## 4. Workflow

### Phase 0 - Scope
- Confirm the audit target: whole repo or specific modules (e.g. "the API", "Auth
  module"). Default: whole repo. Ask the Laravel version and PHP version if not inferable
  from `composer.json`.
- Note the report path (default `reports/`). Do not stall; defaults are fine.

### Phase 1 - Read-only reconnaissance
- Read `composer.json` + `composer.lock` if present - record Laravel version, PHP
  requirement, notable packages (Sanctum/Passport, Horizon, Scout, admin panels).
- Map the structure: `app/` (Http/Controllers, Models, Http/Requests, Policies),
  `routes/` (web.php, api.php, console.php), `config/`, `.env.example`, `resources/views`,
  `database/`.
- Record whether the repo is a standard Laravel app and its approximate size.

### Phase 2 - Checklist-driven verification
For each checklist item in `references/laravel-checklist.md`:
- Run the suggested read-only searches (patterns in the checklist), read the relevant
  controllers/models/routes/config/blade views.
- Assign a verdict: `PASS` (good), `FAIL` (bad practice present), `PARTIAL` (present but
  mitigated/limited), `NOT-APPLICABLE`, `NOT-VERIFIABLE` (needs runtime, e.g. `.env`
  values in a dev repo - check `.env.example` and config defaults instead).
- Record evidence as `path:line` with a 1-3 sentence rationale for every
  FAIL/PARTIAL/NOT-VERIFIABLE. Every finding must trace to observed code.

### Phase 3 - Scoring
- Assign P0-P3 per the table in section 3, considering likelihood and impact in this
  specific app (public-facing? sensitive data? admin area?).

### Phase 4 - Report
Use `templates/laravel-review-report.md`. Required sections:
1. Header (project, date, Laravel/PHP versions, scope, method).
2. **Executive summary** (product-owner readable): overall posture, counts by severity,
   top 3-5 risks, and one line about framework support status (supported / security-only
   / EOL).
3. **Findings sorted P0 -> P3**: priority badge, `LB-<domain>-NN`, CWE, title, verdict,
   evidence `path:line`, impact, and a concrete "How to remediate" for this codebase.
4. Domain compliance matrix (counts + pass rate).
5. **Remediation roadmap** (ordered work items).
6. Not-verifiable list + limitations.

## 5. Framework support check (blue team)

Check `composer.json` for the `laravel/framework` version and compare to the official
support policy (see `references/laravel-checklist.md`, item LB-APP-DEP-04). As of
<2026-09>: Laravel **13** current (security until 2028-03), **12** security-fixes-only
(until 2027-02), **11 and older = EOL** - treat EOL as P1, security-only as P2, and
state it in the report.

## 6. Remediation guidance in the report

Every FAIL/PARTIAL ends with a concrete "How to remediate" mapped to the project's stack
(e.g. "use `where('col', ?)` binding in `app/Services/UserService.php`", "replace
`Model::create($request->all())` with a `UserRequest` + visible `$fillable`", "set
`APP_DEBUG=false` and secrets via env in `.env` + configure the deploy pipeline", "add
`->with('orders')` in `UserController@index`"). Point at exact files so findings become
backlog items.

## 7. Limitations

- Static, at-rest review: runtime `.env`, live config, and external integrations are not
  executed. Mark such items `NOT-VERIFIABLE` instead of guessing.
- Absence of evidence is not evidence of security.
- N+1 and similar quality findings are flagged as guidance, not proof of production
  impact - the report says so.
- All findings must be traceable to files read during the audit.

## 8. Resources

- `references/laravel-checklist.md` - authoritative checklist: 7 domains, detection
  patterns, CWE, baseline severity, and fixes.
- `templates/laravel-review-report.md` - the report skeleton.